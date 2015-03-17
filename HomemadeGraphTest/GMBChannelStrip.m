//
//  GMBChannelStrip.m
//  CollectionViewsTake2
//
//  Created by Graham Barab on 7/3/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

static void * gainChangedContext = &gainChangedContext;
static void * panChangedContext = &panChangedContext;
static void * nChannelsChangedContext = &nChannelsChangedContext;


#import "GMBChannelStrip.h"



OSStatus inputRenderNotifyPeakAmplitudeForBuffer (void				*inRefCon,
						AudioUnitRenderActionFlags 	*ioActionFlags,
						const AudioTimeStamp		*inTimeStamp,
						UInt32				inBusNumber,
						UInt32				inNumberFrames,
						AudioBufferList			*ioData)
{
	//This callback's purpose is to notify the queue when the AudioUnitRender call has completed.
	float temp = 0;
	if (*ioActionFlags & kAudioUnitRenderAction_PostRender)
	{
		GMBLevelMeterUserData* ud = (GMBLevelMeterUserData*)inRefCon;
		UInt32 numChannels = ioData->mNumberBuffers;
		if (numChannels == 2)
		{
			GMBAudioSample32BitFloat_t sampleL = 0;
			GMBAudioSample32BitFloat_t sampleR = 0;
			GMBAudioSample32BitFloat_t sSum = 0;
			for (int i=0; i < inNumberFrames; ++i)
			{
				memcpy(&sampleL, ioData->mBuffers[0].mData + (i * sizeof(sampleL)), sizeof(sampleL));
				memcpy(&sampleR, ioData->mBuffers[1].mData + (i * sizeof(sampleR)), sizeof(sampleR));
				sSum = (sampleL / 2.0) + (sampleR / 2.0);

				if (sSum > temp)
				{
					temp = sSum;
				}
			}
			ud->peak = temp;
		}
		else	//Mono
		{
			GMBAudioSample32BitFloat_t sample = 0;
			for (int i=0; i < inNumberFrames; ++i)
			{
				memcpy(&sample, ioData->mBuffers[0].mData + (i * sizeof(sample)), sizeof(sample));
				if (sample > temp)
				{
					temp = sample;
				}
			}
			ud->peak = temp;
		}
	}
	return noErr;
}


@implementation GMBChannelStrip


@synthesize gain;
@synthesize name;
@synthesize pan;
@synthesize channelNum;
@synthesize levelMeterValue;
@synthesize graph;
@synthesize gainLog;
@synthesize gainLogControlValue;
@synthesize levelMeterTimer;
@synthesize bgTimer;


-(id)init
{
	self = [super init];
	gain = 1;
	pan = 0;
	levelMeterValue = 0;
	name = [[NSString alloc] init];
	channelNum = [[NSNumber alloc] init];
	NSNumber* tempMono = [[NSNumber alloc] initWithInt:0];
	[self setIsMonoOrStereoNSNumber:tempMono];
//	isMonoOrStereo = [[NSNumber alloc] initWithInt:0];
	return self;
}

-(id)initWithChannelNum : (NSNumber*)channelNum_
	withUserDataStruct: (GMBAudioQueueUserData*)userData_
	withOutputBusArray:(GMBOutputBus *)outputBus_
			withGraph: (GMBAUGraph*)graph_
{
	self = [self init];
	gain = 1;
	pan = 0;
	name = @"Track ";
	[name stringByAppendingString:[channelNum_ stringValue]];
	channelNum = channelNum_;
	outputBus = outputBus_;
	userData = userData_;
	graph = graph_;

	if (userData->streamFormat.mChannelsPerFrame == 1)
	{
		monoOrStereo = 0;
	} else
	{
		monoOrStereo = 1;
	}

	//Register the input callback.
	levelMeterUserData.peak = 0;
	CheckError(AudioUnitAddRenderNotify(outputBus->limiter,
										inputRenderNotifyPeakAmplitudeForBuffer,
										&levelMeterUserData), "Error adding level meter render callback");

	[self addObserver:self forKeyPath:NSStringFromSelector(@selector(gainLogControlValue)) options:NSKeyValueObservingOptionNew context:&gainChangedContext];
	[self addObserver:self forKeyPath:NSStringFromSelector(@selector(pan)) options:NSKeyValueObservingOptionNew context:&panChangedContext];
	[self addObserver:self forKeyPath:NSStringFromSelector(@selector(monoOrStereo)) options:NSKeyValueObservingOptionNew context:&nChannelsChangedContext];

	bgTimer = [[GMBBackgroundTimer alloc] initWithSelector:@selector(updateLevelMeterValue:)
											andTarget:self];
	dispatch_queue_t backgroundQueue = dispatch_queue_create("inputSerialDispatchQueue", DISPATCH_QUEUE_SERIAL);
	dispatch_async(backgroundQueue, ^
				{
					[bgTimer main];
				});

//	levelMeterTimer = [[NSTimer alloc] initWithFireDate:[NSDate date]
//											   interval:0.01
//												 target:self
//											   selector:@selector(updateLevelMeterValue:)
//											   userInfo:nil
//												repeats:YES];
//	NSRunLoop *runner = [NSRunLoop currentRunLoop];
//	[runner addTimer: levelMeterTimer forMode: NSDefaultRunLoopMode];

	return self;
}

-(void)updateLevelMeterValue: (NSTimer*)timer_
{
	float logVal = 20 * log10(levelMeterUserData.peak);
	[self setLevelMeterValue:logVal];
}

-(void)setLevelMeterValue:(float)levelMeterValue_
{
	_levelMeterValue = levelMeterValue_;
	[self didChangeValueForKey:NSStringFromSelector(@selector(levelMeterValue))];
}

-(float)levelMeterValue
{
	return _levelMeterValue;
}

-(void)setMonoOrStereo:(int)monoOrStereo_
{
	NSAssert(!((monoOrStereo > 1) || (monoOrStereo < 0)), @"monoOrStereo must be 0 (mono) or 1 (stereo)");

	monoOrStereo = monoOrStereo_;
	[self didChangeValueForKey:NSStringFromSelector(@selector(monoOrStereo))];
}

-(int)monoOrStereo
{
	return monoOrStereo;
}

-(NSNumber*)isMonoOrStereoNSNumber
{
	return _isMonoOrStereo;
}

-(void)setIsMonoOrStereoNSNumber:(NSNumber *)isMonoOrStereoNSNumber_
{

//	[self willChangeValueForKey:@"isMonoOrStereoNSNumber"];
	if (_isMonoOrStereo)
	{
		_isMonoOrStereo = isMonoOrStereoNSNumber_;
	} else
	{
		_isMonoOrStereo = [[NSNumber alloc] init];
		_isMonoOrStereo = [isMonoOrStereoNSNumber_ copy];
	}

//	monoOrStereo = [isMonoOrStereoNSNumber_ intValue];
	[self didChangeValueForKey:@"isMonoOrStereoNSNumber"];
}

-(GMBOutputBus*)outputBus
{
	return outputBus;
}

-(void)setOutputBus:(GMBOutputBus *)outputBus_
{
	outputBus = outputBus_;
	[self didChangeValueForKey:NSStringFromSelector(@selector(outputBus))];
}

-(GMBAudioQueueUserData*)userDataStruct
{
	return userData;
}

-(void)setUserDataStruct:(GMBAudioQueueUserData *)userDataStruct
{
	userData = userDataStruct;
}

//-(void)setGainLogControlValue:(double)gainLogControlValue_
//{
//	
//}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == gainChangedContext)
	{
		if (gainLogControlValue <= -59)
		{
			[self willChangeValueForKey:NSStringFromSelector(@selector(gainLog))];
			gain = 0;
			gainLog = ( (pow(-60, 3.0)) / 4000.0) +  (pow(-60, 2.0) / 400.0) + (-60 / 2.0);
			[self didChangeValueForKey:NSStringFromSelector(@selector(gainLog))];
		}
		else
		{
			[self willChangeValueForKey:NSStringFromSelector(@selector(gainLog))];
			gainLog = ( (pow(gainLogControlValue, 3.0)) / 4000.0) +  (pow(gainLogControlValue, 2.0) / 400.0) + (gainLogControlValue / 2.0);
			[self didChangeValueForKey:NSStringFromSelector(@selector(gainLog))];
			gain = pow(10, (gainLog / 20.0));

		}


		CheckError(AudioUnitSetParameter(outputBus->mixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, gain, 0), "Error setting mixer volume parameter");
		return;
	}

	if (context == panChangedContext)
	{
		CheckError(AudioUnitSetParameter(outputBus->mixer, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, 0, pan, 0), "Error setting mixer volume parameter");
		return;
	}

	if (context == nChannelsChangedContext)
	{
		AudioStreamBasicDescription asbd_ = {0};
		if (monoOrStereo == 0)
		{
			GMBFillOutASBDForLPCM(&asbd_, userData->streamFormat.mSampleRate, 1, 32, 32, true, false, true);
		} else
		{
			GMBFillOutASBDForLPCM(&asbd_, userData->streamFormat.mSampleRate, 2, 32, 32, true, false, true);
		}

		Boolean isInitialized;
		Boolean isRunning;

		AudioStreamBasicDescription currentASBD = {0};
		UInt32 asbdSize;
		CheckError(AUGraphIsRunning(graph.graph, &isRunning), "Error checking if graph is running");
		if (isRunning)
			CheckError(AUGraphStop(graph.graph), "Error stopping the graph");

		CheckError(AUGraphIsInitialized(graph.graph, &isInitialized), "Error checking if graph is initialized");
		if (isInitialized)
		{
			CheckError(AUGraphUninitialize(graph.graph), "Error uninitializing the graph");
		}

		//Disconnect audio units from eachother before setting their properties.
		CheckError(AUGraphDisconnectNodeInput(graph.graph, outputBus->mixerNode, 0), "Error disconnecting converter from mixer");
		CheckError(AUGraphDisconnectNodeInput(graph.graph, outputBus->limiterNode, 0), "Error disconnecting mixer from limiter");
		CheckError(AUGraphDisconnectNodeInput(graph.graph, outputBus->splitterNode, 0), "Error disconnecting limiter from splitter");
		CheckError(AUGraphDisconnectNodeInput(graph.graph, *(graph.multiMixerNode), (UInt32)[channelNum unsignedIntegerValue]), "Error disconnecting converter from mixer");

		AudioUnitConnection splitterToGenOutputConnection = {0};
		splitterToGenOutputConnection.sourceAudioUnit = 0;
		splitterToGenOutputConnection.sourceOutputNumber = 0;
		splitterToGenOutputConnection.destInputNumber = 0;
		CheckError(AudioUnitSetProperty(outputBus->genericOutput, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, 0, &splitterToGenOutputConnection, sizeof(AudioUnitConnection)), "Error manually connecting splitter output 1 to generic output input bus 0");

		//Set the properties
		CheckError(AudioUnitGetProperty(outputBus->converter_pre, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &currentASBD, &asbdSize), "Error obtaining the current stream format of converter_pre input");
		CheckError(AudioUnitSetProperty(outputBus->converter_pre, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd_, sizeof(AudioStreamBasicDescription)), "Error setting the input stream description for converter_pre");
		CheckError(AudioUnitSetProperty(outputBus->converter_pre, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd_, sizeof(asbd_)), "Error setting the input stream description for converter_pre");
		CheckError(AudioUnitSetProperty(outputBus->mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd_, sizeof(AudioStreamBasicDescription)), "Error updating the stream format of mixer output");
		CheckError(AudioUnitSetProperty(outputBus->limiter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd_, sizeof(AudioStreamBasicDescription)), "Error updating the stream format of mixer output");
		CheckError(AudioUnitSetProperty(outputBus->splitter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd_, sizeof(AudioStreamBasicDescription)), "Error updating the stream format of splitter output");
		CheckError(AudioUnitSetProperty(outputBus->splitter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd_, sizeof(AudioStreamBasicDescription)), "Error updating the stream format of mixer output");


		//Now reconnect all the nodes
		CheckError(AUGraphConnectNodeInput(graph.graph, outputBus->converter_preNode, 0, outputBus->mixerNode, 0), "Error re-connecting converter_pre to mixer");
		CheckError(AUGraphConnectNodeInput(graph.graph, outputBus->mixerNode, 0, outputBus->limiterNode, 0), "Error re-connecting mixernode to limiternode");
		CheckError(AUGraphConnectNodeInput(graph.graph, outputBus->limiterNode, 0, outputBus->splitterNode, 0), "Error re-connecting converter_pre to mixer");
		CheckError(AUGraphConnectNodeInput(graph.graph, outputBus->splitterNode, 0, *graph.multiMixerNode, (UInt32)[channelNum unsignedIntegerValue]), "Error re-connecting converter_pre to mixer");
		//Reconnect the generic output manually
		splitterToGenOutputConnection.sourceAudioUnit = outputBus->splitter;
		splitterToGenOutputConnection.sourceOutputNumber = 1;
		splitterToGenOutputConnection.destInputNumber = 0;
		CheckError(AudioUnitSetProperty(outputBus->genericOutput, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, 0, &splitterToGenOutputConnection, sizeof(AudioUnitConnection)), "Error manually connecting splitter output 1 to generic output input bus 0");


		CheckError(AUGraphInitialize(graph.graph), "Error re-initializing the graph");

		//If graph had been running before, then resume playing back audio automatically
		if (isRunning)
		{
			CheckError(AUGraphStart(graph.graph), "Error resuming playback");
		}
		return;
	}


}

-(id)copyWithZone:(NSZone*)zone
{
	GMBChannelStrip* newChannelStrip = [[GMBChannelStrip allocWithZone:zone] initWithChannelNum:[self channelNum] withUserDataStruct:graph.userDataStructs withOutputBusArray:[self outputBus] withGraph:graph];
	newChannelStrip.channelNum = [[NSNumber alloc] initWithInt:[self.channelNum intValue]];
	newChannelStrip.gain = self.gain;
	newChannelStrip.pan = self.pan;
	newChannelStrip.monoOrStereo = self.monoOrStereo;
	newChannelStrip.name = self.name;
	newChannelStrip.outputBus = self.outputBus;

	return self;

}

-(void)dealloc
{
	[self removeObserver:self forKeyPath:NSStringFromSelector(@selector(gainLogControlValue))];
	[self removeObserver:self forKeyPath:NSStringFromSelector(@selector(pan))];
	[self removeObserver:self forKeyPath:NSStringFromSelector(@selector(monoOrStereo))];
	[levelMeterTimer invalidate];
	[bgTimer cancel];
	bgTimer = nil;
	graph = nil;
}
@end

