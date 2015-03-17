//
//  GMBMixer.m
//  AVAssets2
//
//  Created by Graham Barab on 6/24/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBMixer.h"

static int pass = 0;
static OSStatus inputRenderCallback (
		void			*inRefCon,	//A pointer to a struct containing the complete audio data
							//to play, as well as state information such as the
							//first sample to play on this invocation of the callback.
		AudioUnitRenderActionFlags  *ioActionFlags, // Unused here. When generating audio, use ioActionFlags to indicate silence
										//between sounds; for silence, also memset the ioData buffers to 0.
		const AudioTimeStamp	*inTimeStamp,   // Unused here.
		UInt32			inBusNumber,	// The mixer unit input bus that is requesting some new
									//		frames of audio data to play.
		UInt32			inNumberFrames, // The number of frames of audio to provide to the buffer(s)
							//		pointed to by the ioData parameter.
		AudioBufferList		*ioData		// On output, the audio data to play. The callback's primary
									// responsibility is to fill the buffer(s) in the
									//		AudioBufferList.
)
{
	if (pass == 3300)
		printf("breakpoint\n");
	GMBAudioQueueUserData* userData = (GMBAudioQueueUserData*)inRefCon;

	UInt32 inNumChannels = ioData->mNumberBuffers;				  //Are we stereo or mono?
	int bytesRead = 0;

	int bytesRequested = 0;
	for (int i=0; i < ioData->mNumberBuffers; ++i)
	{
		bytesRequested += ioData->mBuffers[i].mDataByteSize;
	}
	int availableBytes = 0;
	void* tail = TPCircularBufferTail(&userData->buf, &availableBytes);

	//Check if there is any audio data left to give before doing any work at all.
	if (userData->isDone)
	{
		*ioActionFlags = kAudioUnitRenderAction_OutputIsSilence;
		return noErr;
	}
	if ( ((int)availableBytes) < 4)
	{
		*ioActionFlags = kAudioUnitRenderAction_OutputIsSilence;
		return noErr;
	}

	//Now figure out how many bytes we can actually copy in this pass.
	int bytesToCopy = (availableBytes > bytesRequested) ? bytesRequested : availableBytes;

	if (inNumChannels == 1)
	{
		if (userData->streamFormat.mChannelsPerFrame == 1)		  //Simple case of mono to mono pass-through
		{
			//Make sure that (bytesToCopy > 0) by this point, otherwise infinite loop ahead
			while (1)
			{
				memcpy(ioData->mBuffers[0].mData + bytesRead,
					tail,
					bytesToCopy);
				TPCircularBufferConsume(&userData->buf, bytesToCopy);
				tail = TPCircularBufferTail(&userData->buf, &availableBytes);
				bytesRead += bytesToCopy;
				bytesToCopy -= bytesRead;
				userData->bytePos += bytesRead;
				if (bytesToCopy < 1)
					break;
			}
			ioData->mBuffers[0].mDataByteSize = bytesRead;
		}
		if (userData->streamFormat.mChannelsPerFrame == 2)		  //Stereo source to mono bus (sum left and right channels)
		{
			GMBAudioSample32BitFloat_t sampleL = 0;
			GMBAudioSample32BitFloat_t sampleR = 0;
			GMBAudioSample32BitFloat_t sampleSum = 0;
			int pos = 0;
			for (int i = 0; i < inNumberFrames * 2; ++i)
			{
				memcpy(&sampleL, tail, sizeof(GMBAudioSample32BitFloat_t));										//Copy left channel
				memcpy(&sampleR, tail + sizeof(GMBAudioSample32BitFloat_t), sizeof(GMBAudioSample32BitFloat_t));   //Copy right channel
				TPCircularBufferConsume(&userData->buf, 8);
				tail = TPCircularBufferTail(&userData->buf, &availableBytes);
				sampleL *= 0.5; sampleR *= 0.5; sampleSum = sampleL + sampleR;		  //This should stop it from clipping.
				memcpy(ioData->mBuffers[0].mData + pos, &sampleSum, sizeof(sampleSum));
				bytesRead += (sizeof(GMBAudioSample32BitFloat_t) * 2);
				userData->bytePos += (sizeof(GMBAudioSample32BitFloat_t) * 2);
				bytesToCopy -= (sizeof(GMBAudioSample32BitFloat_t) );
				pos += sizeof(GMBAudioSample32BitFloat_t);
				if ( bytesToCopy < 1)
				{
					break;
				}
			}
			ioData->mBuffers[0].mDataByteSize = bytesRead;
		}
	}
	else															//inNumChannels = 2
	{
		if (userData->streamFormat.mChannelsPerFrame == 2)		  //Stereo source, must deinterleave
		{
			int posL = 0;
			int posR = 0;
			GMBAudioSample32BitFloat_t sample = 0;
			bytesToCopy *= 2;
			if (bytesToCopy > availableBytes)
			{
				bytesToCopy = (int)userData->totalBytesInBuffer - (int)userData->bytePos;
			}
			if (inNumberFrames > (availableBytes) / sizeof(GMBAudioSample32BitFloat_t))
			{
				inNumberFrames = (availableBytes) / sizeof(GMBAudioSample32BitFloat_t);
			}

			for (int i = 0; i < inNumberFrames * 2; ++i)
			{
				memcpy(&sample, tail, sizeof(GMBAudioSample32BitFloat_t));
				TPCircularBufferConsume(&userData->buf, sizeof(GMBAudioSample32BitFloat_t));
				tail = TPCircularBufferTail(&userData->buf, &availableBytes);
				if (i % 2 == 0)
				{
					memcpy(&ioData->mBuffers[0].mData[posL], &sample, sizeof(GMBAudioSample32BitFloat_t));
					posL += sizeof(GMBAudioSample32BitFloat_t);
					bytesRead += sizeof(GMBAudioSample32BitFloat_t);
					bytesToCopy -= sizeof(GMBAudioSample32BitFloat_t);
					userData->bytePos += sizeof(GMBAudioSample32BitFloat_t);		// += 4
					if (bytesToCopy < 1)
						break;
				}
				else
				{
					memcpy(&ioData->mBuffers[1].mData[posR], &sample, sizeof(GMBAudioSample32BitFloat_t));
					posR += sizeof(GMBAudioSample32BitFloat_t);
					bytesRead += sizeof(GMBAudioSample32BitFloat_t);
					bytesToCopy -= sizeof(GMBAudioSample32BitFloat_t);
					userData->bytePos += sizeof(GMBAudioSample32BitFloat_t);		// += 4
					if (bytesToCopy  < 1)
						break;
				}
			}
			ioData->mBuffers[0].mDataByteSize = bytesRead;
			ioData->mBuffers[1].mDataByteSize = bytesRead;
		}
		else												  //Input is Mono
		{
			//Since input is mono, duplicate each sample into the other buffer
			for (int i = 0; i < inNumberFrames; ++i)
			{
				memcpy(ioData->mBuffers[0].mData + bytesRead, tail, sizeof(GMBAudioSample32BitFloat_t));
				memcpy(ioData->mBuffers[1].mData + bytesRead, tail, sizeof(GMBAudioSample32BitFloat_t));
				TPCircularBufferConsume(&userData->buf, sizeof(GMBAudioSample32BitFloat_t));
				tail = TPCircularBufferTail(&userData->buf, &availableBytes);
				bytesRead += sizeof(GMBAudioSample32BitFloat_t);
				bytesToCopy -= sizeof(GMBAudioSample32BitFloat_t);
				userData->bytePos += sizeof(GMBAudioSample32BitFloat_t);
				if (bytesToCopy < 1)
					break;
			}
			ioData->mBuffers[0].mDataByteSize = bytesRead;
			ioData->mBuffers[1].mDataByteSize = bytesRead;

		}
}
	++pass;
	return noErr;
}

@implementation GMBMixer

@synthesize audioChannelStrips;
@synthesize busChannelStrips;
@synthesize outputChannelStrips;
@synthesize graph;
@synthesize asbd;
@synthesize mixerInputsUsed;
@synthesize mixerNode;
@synthesize isProcessingGraph;
@synthesize mixer;
@synthesize assetParser;
@synthesize audioConverter;
//@synthesize sampleBufferDelegate;
@synthesize needsNewSampleBuffer;
@synthesize userDataStructs;
@synthesize nSourceTracks;
@synthesize nOutputBusses;



-(id) init
{
	self = [super init];
	audioChannelStrips = [[NSMutableArray alloc] init];
	busChannelStrips = [[NSMutableArray alloc] init];
	outputChannelStrips = [[NSMutableArray alloc] init];
	graph = [GMBAUGraph alloc];
	mixerInputsUsed = 0;
	mixer = malloc(sizeof(AudioUnit));
	userDataStructs = NULL;
	[self addObserver:self forKeyPath:NSStringFromSelector(@selector(nSourceTracks)) options:NSKeyValueObservingOptionNew context:nSourceTracksContext];
	return self;
}



-(void)startGraph
{
	if (graph.graph && graph)
	{
		Boolean outIsInitialized;
		CheckError(AUGraphIsInitialized(graph.graph,
										&outIsInitialized), "AUGraphIsInitialized");
		if(!outIsInitialized)
			CheckError(AUGraphInitialize(graph.graph), "AUGraphInitialize");

		Boolean isRunning;
		CheckError(AUGraphIsRunning(graph.graph,
									&isRunning), "AUGraphIsRunning");
		if(!isRunning)
			CheckError(AUGraphStart(graph.graph), "AUGraphStart");
		isProcessingGraph = YES;
	}
}

-(void)stopGraph
{
//	printf("Stopping the graph\n");
	CheckError(AUGraphStop(graph.graph), "Stopping the audio graph");
}

-(void)registerCallbacks
{
	AURenderCallbackStruct renderCallbackStruct = {0};
	for (int i = 0; i < [nSourceTracks intValue]; ++i)
	{
		renderCallbackStruct.inputProc = inputRenderCallback;
		renderCallbackStruct.inputProcRefCon = (void*)&userDataStructs[i];						  //Passing the first audio channel for testing purposes
		CheckError(AUGraphSetNodeInputCallback(graph.graph, graph.outputBusArray[i].converter_preNode, 0, &renderCallbackStruct), "Registering input callback");
	}
   }

-(void)bufferData:(AVAssetReaderTrackOutput*)source
{

}

-(void)enqueueSampleBuffer:(AVAssetReaderAudioMixOutput *)buffer
{

}

-(BOOL)hasMoreSampleBuffersToProvide
{
	return YES;
}

-(void)dealloc
{

	free(mixer);
	[self removeObserver:self forKeyPath:NSStringFromSelector(@selector(nSourceTracks))];
	userDataStructs = NULL;
	graph = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == nSourceTracksContext)
	{
		nOutputBusses = nSourceTracks;
	}
	if (context == mixerNodeChangedContext)
	{
		mixerNode = graph.multiMixerNode;
	}
}

@end

