//
//  GMBAVExporter.m
//  AVAssets2
//
//  Created by Graham Barab on 7/11/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBAVExporter.h"

static void* assetWriterStatusContext = &assetWriterStatusContext;
static unsigned long long count = 0;

OSStatus inputRenderNotify (
							void						*inRefCon,
							AudioUnitRenderActionFlags  *ioActionFlags,
							const AudioTimeStamp		*inTimeStamp,
							UInt32					  inBusNumber,
							UInt32					  inNumberFrames,
							AudioBufferList			 *ioData
							)
{
	//This callback's purpose is to notify the queue when the AudioUnitRender call has completed.
	if (*ioActionFlags & kAudioUnitRenderAction_PostRender)
	{
		bool* locked = (bool*)inRefCon;
		*locked = false;
	}
	return noErr;
}

OSStatus normalizeRenderNotify (
							void						*inRefCon,
							AudioUnitRenderActionFlags  *ioActionFlags,
							const AudioTimeStamp		*inTimeStamp,
							UInt32					  inBusNumber,
							UInt32					  inNumberFrames,
							AudioBufferList			 *ioData
							)
{
	//This callback's purpose is to notify the queue when the AudioUnitRender call has completed.
	if (*ioActionFlags & kAudioUnitRenderAction_PostRender)
	{
		bool* locked = (bool*)inRefCon;
		*locked = false;
	}
	return noErr;
}

OSStatus GMBAudioConverterComplexInputDataProc (
											AudioConverterRef			 inAudioConverter,
											UInt32						*ioNumberDataPackets,
											AudioBufferList			   *ioData,
											AudioStreamPacketDescription  **outDataPacketDescription,
											void						  *inUserData
											)
{	
	return noErr;
}

@implementation GMBAVExporter
@synthesize assetWriter;
@synthesize graph;
@synthesize userDataStructs;
@synthesize numAudioTracks;
@synthesize assetWriterInputsAudio;
@synthesize videoInput;
@synthesize bufferListArray;
@synthesize asbds;
@synthesize assetParser;
@synthesize videoTrackReader;
@synthesize inputSerialDispatchQueue;
@synthesize normalizeOutputs;
@synthesize userRequestedASBDs;
@synthesize convertedBusNumbersArray = _convertedBusNumbersArray;
@synthesize normalize;


-(id) init
{
	self = [super init];
	return self;
}

-(id) initWithGraph:(GMBAUGraph *)graph_ withUserDataStructs:(GMBAudioQueueUserData *)userDataStructs_ numberOfStructs:(UInt32)numStructs_ withAssetParser:(GMBAVAssetParser *) assetParser_ withDestinationURL:(NSURL *)url_
{
//	self = [self init];
//	_convertedBusNumbersArray = malloc(sizeof(bool) * numStructs_);
	_audioConverterRef = malloc(sizeof(AudioConverterRef) * numAudioTracks);
//	memset(_convertedBusNumbersArray, 0, sizeof(bool) * numStructs_);
	normalizeOutputs = YES;
#pragma mark SetTargetAmplitude
	_normalizationUserData.targetAmplitude = 0.44;
	_normalizationUserData.loudestSampleValue = 0;
//	_dataByteSizeOfUserDataStructs = userDataStructs_->totalBytesInBuffer;
	inputSerialDispatchQueue = dispatch_queue_create("inputSerialDispatchQueue", DISPATCH_QUEUE_SERIAL);
	userDataStructs = userDataStructs_;
	assetParser = assetParser_;
	videoTrackReader = [[AVAssetReader alloc] initWithAsset:assetParser.asset error:nil];
	[videoTrackReader addOutput:assetParser.videoTrackOutput];
	[videoTrackReader startReading];
	numAudioTracks = numStructs_;
	graph = graph_;
	bufferListArray = malloc(sizeof(GMBBufferListStruct) * numAudioTracks);
	NSError* outErr = nil;
	assetWriter = [[AVAssetWriter alloc] initWithURL:url_ fileType:AVFileTypeQuickTimeMovie error:&outErr];
	asbds = malloc(sizeof(AudioStreamBasicDescription) * numStructs_);
	assetWriterInputsAudio = [[NSMutableArray alloc] init];
	videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:nil];
	[assetWriter addInput:videoInput];
	for (int i=0; i < numAudioTracks; ++i)
	{
		if (_convertedBusNumbersArray[i])		//Mono case
		{
			AudioStreamBasicDescription origASBD = assetParser_.originalASBD;
			AudioStreamBasicDescription hybridASBD = {0};

			hybridASBD.mSampleRate = origASBD.mSampleRate;
			hybridASBD.mFormatID = origASBD.mFormatID;
			hybridASBD.mFormatFlags = origASBD.mFormatFlags;
			hybridASBD.mFramesPerPacket = 1;
			hybridASBD.mChannelsPerFrame = 1;
			hybridASBD.mBytesPerPacket = origASBD.mBitsPerChannel / 8;
			hybridASBD.mBytesPerFrame = origASBD.mBitsPerChannel  / 8;
			hybridASBD.mBitsPerChannel = origASBD.mBitsPerChannel;

			asbds[i] = hybridASBD;

//			CheckError(AudioUnitSetProperty(graph.outputBusArray[i].genericOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &hybridASBD, sizeof(AudioStreamBasicDescription)), "Error setting output stream format for generic output in GMBAVExporter");

			NSDictionary* outputSettings = [GMBAVAssetParser convertASBDToNSDictionary:hybridASBD];
			AVAssetWriterInput* input = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:outputSettings];
			//		bufferListArray[i].bufferList.mBuffers[0].mNumberChannels = origASBD.
			//		bufferListArray[i].bufferList.mBuffers =
			[assetWriterInputsAudio addObject:input];
			[assetWriter addInput:input];
		}
		else
		{
			AudioStreamBasicDescription origASBD = assetParser_.originalASBD;
			AudioStreamBasicDescription outASBD = {0};
			AudioStreamBasicDescription hybridASBD = {0};
			UInt32 propSize = sizeof(AudioStreamBasicDescription);
			CheckError(AudioUnitGetProperty(graph.outputBusArray[i].splitter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &outASBD, &propSize), "Error obtaining generic output stream description in GMBAVExporter");
			hybridASBD = outASBD;
			hybridASBD.mFormatID = origASBD.mFormatID;
			hybridASBD.mFormatFlags = origASBD.mFormatFlags;
			hybridASBD.mFramesPerPacket = outASBD.mFramesPerPacket;
			hybridASBD.mChannelsPerFrame = outASBD.mChannelsPerFrame;
			hybridASBD.mBytesPerPacket = origASBD.mBitsPerChannel * outASBD.mChannelsPerFrame / 8;
			hybridASBD.mBytesPerFrame = origASBD.mBitsPerChannel * outASBD.mChannelsPerFrame / 8;
			hybridASBD.mBitsPerChannel = origASBD.mBitsPerChannel;

			asbds[i] = hybridASBD;

			CheckError(AudioUnitSetProperty(graph.outputBusArray[i].genericOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &hybridASBD, sizeof(AudioStreamBasicDescription)), "Error setting output stream format for generic output in GMBAVExporter");

			NSDictionary* outputSettings = [GMBAVAssetParser convertASBDToNSDictionary:hybridASBD];
			AVAssetWriterInput* input = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:outputSettings];
			//		bufferListArray[i].bufferList.mBuffers[0].mNumberChannels = origASBD.
			//		bufferListArray[i].bufferList.mBuffers =
			[assetWriterInputsAudio addObject:input];
			[assetWriter addInput:input];
		}

	}

//	[assetWriter addInput:videoInput];
	[assetWriter addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:assetWriterStatusContext];
	if ([assetWriter startWriting])
	{

	}else
	{
		NSLog(@"%@", [assetWriter error]);
	}
	;

	[assetWriter startSessionAtSourceTime:kCMTimeZero];


	return self;
}

-(void) startExport
{
	//Don't forget to reset the playback position of the userDataStructs, otherwise silence when we actually export the movie
	for (int i=0; i < numAudioTracks; ++i)
	{
		graph.userDataStructs[i].bytePos = 0;
		graph.userDataStructs[i].isDone = false;
	}

	//Uninitalize the generic output so it can be reinitialized in the next function call.
	for (int i=0; i < numAudioTracks; ++i)
	{
		CheckError(AudioUnitUninitialize(graph.outputBusArray[i].genericOutput), "Error uninitializing the generic output (GMBAVExporter::normalizationPass");
	}

	UInt32* c = malloc(sizeof(UInt32) * numAudioTracks);
	memset(c, 0, sizeof(UInt32) * numAudioTracks);
	AudioTimeStamp* timeStamps = malloc(sizeof(AudioTimeStamp) * numAudioTracks);
	memset(timeStamps, 0, sizeof(UInt32) * numAudioTracks);
	bufferListArray = malloc(sizeof(AudioBufferList) * numAudioTracks);
	memset(bufferListArray, 0, sizeof(AudioBufferList) * numAudioTracks);
	CMSampleTimingInfo* timingInfoStructs = malloc(sizeof(CMSampleTimingInfo) * numAudioTracks);
	memset(timingInfoStructs, 0, sizeof(CMSampleTimingInfo) * numAudioTracks);


	__block UInt32 numInputsMarkedAsFinished = 0;
	bool* finished = malloc(sizeof(bool) * numAudioTracks);
	__block bool vidFinished = false;
	for (int i = 0; i < numAudioTracks; ++i)
	{
		bufferListArray[i].mNumberBuffers = 1;
		bufferListArray[i].mBuffers->mNumberChannels = asbds[i].mChannelsPerFrame;
//		bufferListArray[i].mBuffers->mData = malloc(asbds[i].mBytesPerFrame * 512);
		bufferListArray[i].mBuffers->mDataByteSize = asbds[i].mBytesPerFrame * 512;
		GMBFillOutAudioTimeStampWithSampleTime(&timeStamps[i], 0);
		timingInfoStructs[i].duration = CMTimeMake(1, asbds[i].mSampleRate);
		timingInfoStructs[i].presentationTimeStamp = kCMTimeZero;
		timingInfoStructs[i].decodeTimeStamp = kCMTimeInvalid;

		AudioStreamBasicDescription goASBD = {0};
		AudioStreamBasicDescription goASBDi = {0};
		UInt32 propsize = sizeof(AudioStreamBasicDescription);

		AudioBufferList* ioDataArray = (AudioBufferList*)malloc( (sizeof(AudioBufferList) * numAudioTracks) + sizeof(AudioBuffer) * 2);
		int bufSize = 512;
		for (int i=0; i < numAudioTracks; ++i)
		{
			//Here we are discovering if the stream coming from the generic output output will be interleaved or not.
			AudioStreamBasicDescription testASBD = {0};
			UInt32 propsize = sizeof(testASBD);
			CheckError(AudioUnitGetProperty(graph.outputBusArray[i].genericOutput,
											kAudioUnitProperty_StreamFormat,
											kAudioUnitScope_Output,
											0,
											&testASBD,
											&propsize), "Error getting Audio unit stream format");
			bool isNonInterleaved = (testASBD.mFormatFlags & kAudioFormatFlagIsNonInterleaved);

			//Now set up our AudioBufferLists
			if (testASBD.mChannelsPerFrame == 2)
			{
				ioDataArray[i].mNumberBuffers = (isNonInterleaved) ? 2 : 1;
				ioDataArray[i].mBuffers[0].mDataByteSize = bufSize * sizeof(GMBAudioSample24Bit_t) * 2;
				ioDataArray[i].mBuffers[0].mNumberChannels = 2;
				ioDataArray[i].mBuffers[0].mData = calloc(bufSize * 2, sizeof(GMBAudioSample24Bit_t));
			} else			  //Stream is mono
			{
				ioDataArray[i].mNumberBuffers = (isNonInterleaved) ? 2 : 1;
				ioDataArray[i].mBuffers[0].mDataByteSize = bufSize * sizeof(GMBAudioSample24Bit_t);
				ioDataArray[i].mBuffers[0].mNumberChannels = 1;
				ioDataArray[i].mBuffers[0].mData = calloc(bufSize, sizeof(GMBAudioSample24Bit_t));
			}

		}
		AudioBufferList* ioDataConvertedArray32 = (AudioBufferList*)malloc( (sizeof(AudioBufferList) * numAudioTracks) + sizeof(AudioBuffer));
		for (int i=0; i < numAudioTracks; ++i)
		{
			ioDataConvertedArray32[i].mNumberBuffers = 1;
			ioDataConvertedArray32[i].mBuffers[0].mDataByteSize = bufSize * sizeof(GMBAudioSample32BitFloat_t) * 2;
			ioDataConvertedArray32[i].mBuffers[0].mNumberChannels = 2;
			ioDataConvertedArray32[i].mBuffers[0].mData = calloc(bufSize, sizeof(GMBAudioSample32BitFloat_t) * 2);
		}
		AudioBufferList* ioDataConvertedArray24 = (AudioBufferList*)malloc( (sizeof(AudioBufferList) * numAudioTracks) + sizeof(AudioBuffer));
		for (int i=0; i < numAudioTracks; ++i)
		{
			ioDataConvertedArray24[i].mNumberBuffers = 1;
			ioDataConvertedArray24[i].mBuffers[0].mDataByteSize = bufSize * sizeof(GMBAudioSample24Bit_t);
			ioDataConvertedArray24[i].mBuffers[0].mNumberChannels = 1;
//			ioDataConvertedArray24[i].mBuffers[0].mData = calloc(bufSize, sizeof(GMBAudioSample24Bit_t));
		}




		CheckError(AudioUnitGetProperty(graph.outputBusArray[i].genericOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &goASBD, &propsize), "Error getting the stream format of the generic output from within GMBAVExporter::startExport");
		CheckError(AudioUnitGetProperty(graph.outputBusArray[i].genericOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &goASBDi, &propsize), "Error obtaining stream format for generic output input");
		CheckError(AudioUnitSetProperty(graph.outputBusArray[i].genericOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbds[i], propsize), "Error updating stream format of generic output form within GMBAVExporter::startExport");
		CheckError(AudioUnitInitialize(graph.outputBusArray[i].genericOutput), "Error initializing generic output");

		bool* locked = malloc(sizeof(bool));
		*locked = true;
		CheckError(AudioUnitAddRenderNotify(graph.outputBusArray[i].genericOutput,
											inputRenderNotify,
											locked), "Error adding custom render complete notification");
		AVAssetWriterInput* currentInput = [assetWriterInputsAudio objectAtIndex:i];
		[currentInput requestMediaDataWhenReadyOnQueue:inputSerialDispatchQueue usingBlock:^
		{
			while ([currentInput isReadyForMoreMediaData])
			{
				ioDataArray[i].mBuffers->mData = NULL;
				AudioUnitRenderActionFlags renderActionFlags = 0;
				AudioStreamBasicDescription outputRenderFormat = {0};
				UInt32 propsize = sizeof(outputRenderFormat);
				CheckError(AudioUnitGetProperty(graph.outputBusArray[i].genericOutput,
												kAudioUnitProperty_StreamFormat,
												kAudioUnitScope_Output,
												0,
												&outputRenderFormat,
												&propsize), "Error getting output stream format GMBAVExporter::startExport");
				CheckError(AudioUnitRender(graph.outputBusArray[i].genericOutput,
											&renderActionFlags,
											&timeStamps[i],
											0,
											512,
											&ioDataArray[i]), "Error calling AudioUnitRender() in GMBAVExporter::startExport");
				while (*locked)
				{

				}





				//Now that we have the audio buffer list, we must convert it to a CMSampleBufferRef
				CMSampleBufferRef sampleBufferRef;
				int sampleCount = bufferListArray[i].mBuffers->mDataByteSize / ( (asbds[i].mBitsPerChannel / 8) * asbds[i].mChannelsPerFrame) ;
				size_t sampleSize = asbds[i].mBytesPerFrame / asbds[i].mChannelsPerFrame;

				CMFormatDescriptionRef streamFormat = NULL;
				CheckError(CMAudioFormatDescriptionCreate(kCFAllocatorDefault,
														&asbds[i],
														0,
														NULL,
														0,
														NULL,
														NULL,
														&streamFormat), "Error creating a cmaudioformatdescription");

				//				CMSampleTimingInfo timing = { CMTimeMake(1, asbds[i].mSampleRate), kCMTimeZero, kCMTimeInvalid };
				void* refCon = &refCon;
				sampleSize = (asbds[i].mBitsPerChannel / 8);
				CheckError(CMSampleBufferCreate(kCFAllocatorDefault,
												NULL,
												false,
												NULL,
												NULL,
												streamFormat,
												sampleCount,
												1,
												&timingInfoStructs[i],
												1,
												&sampleSize,
												&sampleBufferRef), "Error creating CMSampleBuffer");





				CheckError(CMSampleBufferSetDataBufferFromAudioBufferList(sampleBufferRef,
																		kCFAllocatorDefault,
																		kCFAllocatorDefault,
																		0,
																		&ioDataArray[i]), "Error copying audio buffer list into CMSampleBufferRef");
				[currentInput appendSampleBuffer:sampleBufferRef];
				//				CFRelease(sampleBufferRef);
				//				CheckError(AudioUnitUninitialize(graph.outputBusArray[i].genericOutput), "Error uninitializing generic output");
				CMTime timeAddend = CMTimeMake(512, asbds[i].mSampleRate);
				timingInfoStructs[i].presentationTimeStamp = CMTimeAdd(timingInfoStructs[i].presentationTimeStamp, timeAddend);
				if (graph.userDataStructs[i].isDone)
				{
					[currentInput markAsFinished];
					numInputsMarkedAsFinished++;
					finished[i] = true;
				}
			}
		}];
	}


	[videoInput requestMediaDataWhenReadyOnQueue:inputSerialDispatchQueue usingBlock:^
	{
		if (!vidFinished)
		{
			while ([videoInput isReadyForMoreMediaData])
			{
				CMSampleBufferRef bufferRef = [assetParser.videoTrackOutput copyNextSampleBuffer];
				if (bufferRef)
				{
					[videoInput appendSampleBuffer:bufferRef];
				} else
				{
					[videoInput markAsFinished];
					numInputsMarkedAsFinished++;
					vidFinished = true;
				}
			}
		}
	}];

	//Wait for all tracks to be written.
	while (numInputsMarkedAsFinished < numAudioTracks + 1)
	{

	}

	[assetWriter finishWritingWithCompletionHandler:^
	{
		NSLog(@"Export Complete");
	}];
}

-(void)normalizationPass
{
	UInt32* c = malloc(sizeof(UInt32) * numAudioTracks);
	memset(c, 0, sizeof(UInt32) * numAudioTracks);
	AudioTimeStamp* timeStamps = malloc(sizeof(AudioTimeStamp) * numAudioTracks);
	memset(timeStamps, 0, sizeof(UInt32) * numAudioTracks);
	bufferListArray = malloc(sizeof(AudioBufferList) * numAudioTracks);
	memset(bufferListArray, 0, sizeof(AudioBufferList) * numAudioTracks);
	CMSampleTimingInfo* timingInfoStructs = malloc(sizeof(CMSampleTimingInfo) * numAudioTracks);
	memset(timingInfoStructs, 0, sizeof(CMSampleTimingInfo) * numAudioTracks);
	bool* locked = malloc(sizeof(bool));
	*locked = true;

	for (int i = 0; i < numAudioTracks; ++i)
	{
		bufferListArray[i].mNumberBuffers = 1;
		bufferListArray[i].mBuffers->mNumberChannels = asbds[i].mChannelsPerFrame;
		//		bufferListArray[i].mBuffers->mData = malloc(asbds[i].mBytesPerFrame * 512);
		bufferListArray[i].mBuffers->mDataByteSize = asbds[i].mBytesPerFrame * 512;
		GMBFillOutAudioTimeStampWithSampleTime(&timeStamps[i], 0);
		timingInfoStructs[i].duration = CMTimeMake(1, asbds[i].mSampleRate);
		timingInfoStructs[i].presentationTimeStamp = kCMTimeZero;
		timingInfoStructs[i].decodeTimeStamp = kCMTimeInvalid;

		AudioStreamBasicDescription goASBD = {0};
		AudioStreamBasicDescription goASBDi = {0};
		AudioStreamBasicDescription origASBD = assetParser.originalASBD;
		AudioStreamBasicDescription outASBD = {0};
		AudioStreamBasicDescription hybridASBD = {0};


		AudioStreamBasicDescription customTestASBD = {0};
		UInt32 propSize = sizeof(AudioStreamBasicDescription);
		CheckError(AudioUnitGetProperty(graph.outputBusArray[i].splitter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &outASBD, &propSize), "Error obtaining generic output stream description in GMBAVExporter");
		GMBFillOutASBDForLPCM(&hybridASBD, origASBD.mSampleRate, outASBD.mChannelsPerFrame, 32, 32, true, false, false);
		UInt32 propsize = sizeof(AudioStreamBasicDescription);
		GMBFillOutASBDForLPCM(&customTestASBD,
							asbds[i].mSampleRate,
							outASBD.mChannelsPerFrame,
							32,
							32,
							true,
							false,
							false);


		CheckError(AudioUnitGetProperty(graph.outputBusArray[i].genericOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &goASBD, &propsize), "Error getting the stream format of the generic output from within GMBAVExporter::startExport");
		CheckError(AudioUnitGetProperty(graph.outputBusArray[i].genericOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &goASBDi, &propsize), "Error obtaining stream format for generic output input");

		//Previously we were using "hybrid ASBD" to set the stream format here.
		CheckError(AudioUnitSetProperty(graph.outputBusArray[i].genericOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &customTestASBD, propsize), "Error updating stream format of generic output form within GMBAVExporter::startExport");

		CheckError(AudioUnitInitialize(graph.outputBusArray[i].genericOutput), "Error initializing generic output");


		CheckError(AudioUnitAddRenderNotify(graph.outputBusArray[i].genericOutput,
											inputRenderNotify,
											locked), "Error adding custom render complete notification");
	}


	memset(bufferListArray, 0, sizeof(AudioBufferList) * numAudioTracks);


	AudioBufferList* ioDataArray = (AudioBufferList*)malloc( (sizeof(AudioBufferList) * numAudioTracks) + sizeof(AudioBuffer) * 2);
	int bufSize = 512;
	for (int i=0; i < numAudioTracks; ++i)
	{
		//Here we are discovering if the stream coming from the generic output output will be interleaved or not.
		AudioStreamBasicDescription testASBD = {0};
		UInt32 propsize = sizeof(testASBD);
		CheckError(AudioUnitGetProperty(graph.outputBusArray[i].genericOutput,
										kAudioUnitProperty_StreamFormat,
										kAudioUnitScope_Output,
										0,
										&testASBD,
										&propsize), "Error getting Audio unit stream format");
		bool isNonInterleaved = (testASBD.mFormatFlags & kAudioFormatFlagIsNonInterleaved);

		//Now set up our AudioBufferLists
		if (testASBD.mChannelsPerFrame == 2)
		{
			ioDataArray[i].mNumberBuffers = (isNonInterleaved) ? 2 : 1;
			ioDataArray[i].mBuffers[0].mDataByteSize = bufSize * sizeof(GMBAudioSample32BitFloat_t) * 2;
			ioDataArray[i].mBuffers[0].mNumberChannels = 2;
			ioDataArray[i].mBuffers[0].mData = calloc(bufSize * 2, sizeof(GMBAudioSample32BitFloat_t));
		} else			  //Stream is mono
		{
			ioDataArray[i].mNumberBuffers = (isNonInterleaved) ? 2 : 1;
			ioDataArray[i].mBuffers[0].mDataByteSize = bufSize * sizeof(GMBAudioSample32BitFloat_t);
			ioDataArray[i].mBuffers[0].mNumberChannels = 1;
			ioDataArray[i].mBuffers[0].mData = calloc(bufSize, sizeof(GMBAudioSample32BitFloat_t));
		}

	}
	AudioBufferList* ioDataConvertedArray = (AudioBufferList*)malloc( (sizeof(AudioBufferList) * numAudioTracks) + sizeof(AudioBuffer));
	for (int i=0; i < numAudioTracks; ++i)
	{
		ioDataConvertedArray[i].mNumberBuffers = 1;
		ioDataConvertedArray[i].mBuffers[0].mDataByteSize = bufSize * sizeof(GMBAudioSample32BitFloat_t);
		ioDataConvertedArray[i].mBuffers[0].mNumberChannels = 1;
		ioDataConvertedArray[i].mBuffers[0].mData = calloc(bufSize, sizeof(GMBAudioSample32BitFloat_t));
	}

#pragma mark StartGettingDataFromOutputUnit
	while (!userDataStructs->isDone)
	{
		for (int i=0; i < numAudioTracks; ++i)
		{
			ioDataArray[i].mBuffers->mData = NULL;
			AudioUnitRenderActionFlags renderActionFlags = 0;
			AudioStreamBasicDescription testASBD = {0};
			UInt32 propsize = sizeof(testASBD);
			CheckError(AudioUnitGetProperty(graph.outputBusArray[i].genericOutput,
											kAudioUnitProperty_StreamFormat,
											kAudioUnitScope_Output,
											0,
											&testASBD,
											&propsize), "Error getting stream description from output unit before render in GMBAVExport::normalizationPass");
			CheckError(AudioUnitRender(graph.outputBusArray[i].genericOutput,
									&renderActionFlags,
									&timeStamps[i],
									0,
									512,
									&ioDataArray[i]), "Error calling AudioUnitRender() in GMBAVExporter::normalizationPass");
			while (*locked)
			{
				//Wait for previous call to AudioUnitRender to complete
			}
			bool mono = (userRequestedASBDs[i].mChannelsPerFrame == 2) ? false : true;
			if (mono)
			{
				//In this section, we have to convert the stereo stream to a mono one.

				GMBAudioSample32BitFloat_t sampleL = 0;
				GMBAudioSample32BitFloat_t sampleR = 0;
				GMBAudioSample32BitFloat_t sSum = 0;


				UInt32 numPasses = ioDataArray[i].mBuffers->mDataByteSize / sizeof(GMBAudioSample32BitFloat_t);
				int k = 0;
				for (int j=0; j < numPasses; j += 2)
				{
					memcpy(&sampleL, ioDataArray[i].mBuffers->mData + (j * sizeof(GMBAudioSample32BitFloat_t)), sizeof(GMBAudioSample32BitFloat_t));
					memcpy(&sampleR, ioDataArray[i].mBuffers->mData + ((j * sizeof(GMBAudioSample32BitFloat_t)) + sizeof(GMBAudioSample32BitFloat_t)), sizeof(GMBAudioSample32BitFloat_t));
					sSum = (sampleL / 2.0) + (sampleR / 2.0);
					memcpy(ioDataConvertedArray[i].mBuffers->mData + (k * sizeof(GMBAudioSample32BitFloat_t)), &sSum, sizeof(sSum));
					k++;
				}
			}
		}

#pragma mark LoudestSample
		GMBAudioSample32BitFloat_t temp = 0;
		if (userRequestedASBDs[0].mSampleRate == 1)
		{
			temp = getLoudestAmplitudeFromBuffer(ioDataConvertedArray, numAudioTracks);
		}
		else
		{
			temp = getLoudestAmplitudeFromBuffer(ioDataArray, numAudioTracks);
		}


		//If the loudest amplitude from the current batch of bufferlists is greater than the loudest amplitude of the previous batch of bufferlists, then update the current record.
		if (temp > _normalizationUserData.loudestSampleValue)
			_normalizationUserData.loudestSampleValue = temp;

		++count;

}

	/**
	At the end of it all, we now have the loudest possible peak of the sum of the output busses. We can now set the limiter pregain for each output bus appropriately.

	First figure out the attenuation or gain as a logarithmic value.
	**/

	double attenuationAsLinearValue = (_normalizationUserData.targetAmplitude / _normalizationUserData.loudestSampleValue);
	double attenuationAsLogValue = 20 * log10(attenuationAsLinearValue);

	//Now set this value onto the limiter pre-gains for each output bus
	if (normalize)
	{
		for (int i=0; i < numAudioTracks; ++i)
		{
			CheckError(AudioUnitSetParameter(graph.outputBusArray[i].limiter,
											kLimiterParam_PreGain,
											kAudioUnitScope_Global,
											0,
											attenuationAsLogValue,
											0), "Error setting limiter pregain for normalization purposes (GMBAVExporter::normalizationPass)");
		}

	}

	//Don't forget to reset the playback position of the userDataStructs, otherwise silence when we actually export the movie
	for (int i=0; i < numAudioTracks; ++i)
	{
		graph.userDataStructs[i].bytePos = 0;
		graph.userDataStructs[i].isDone = false;
	}

	//Uninitalize the generic output so it can be reinitialized in the next function call.
	for (int i=0; i < numAudioTracks; ++i)
	{
		CheckError(AudioUnitUninitialize(graph.outputBusArray[i].genericOutput), "Error uninitializing the generic output (GMBAVExporter::normalizationPass");
	}
}

-(void)setConvertedBusNumbersArray:(bool *)convertedBusNumbersArray_
{

	_convertedBusNumbersArray = convertedBusNumbersArray_;
	[self didChangeValueForKey:NSStringFromSelector(@selector(convertedBusNumbersArray))];
}

-(bool*)convertedBusNumbersArray
{
	return _convertedBusNumbersArray;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == assetWriterStatusContext)
	{
		NSLog(@"assetWriter status changed");
		NSLog(@"assetWriter new status is %@", [change valueForKey:NSKeyValueChangeNewKey]);
	}

}

-(void) dealloc
{
	graph = nil;
	assetParser = nil;

}
@end

GMBAudioSample32BitFloat_t getLoudestAmplitudeFromBuffer(AudioBufferList* bufferLists, UInt32 numBufferLists)
{
	GMBAudioSample32BitFloat_t loudest = 0;
	GMBAudioSample32BitFloat_t temp = 0;
	GMBAudioSample32BitFloat_t* samplesPerChannel;
	int numChans = bufferLists->mBuffers->mNumberChannels;
	int numPasses = bufferLists->mBuffers->mDataByteSize / sizeof(GMBAudioSample32BitFloat_t) / numChans;

	samplesPerChannel = malloc(sizeof(GMBAudioSample32BitFloat_t) * numBufferLists);
	memset(samplesPerChannel, 0, sizeof(GMBAudioSample32BitFloat_t) * numBufferLists);

	for (int c = 0; c < numPasses; ++c)
	{
		//First, collect all samples that correspond to the same moment in time.
		for (int i=0; i < numBufferLists; ++i)
		{
			GMBAudioSample32BitFloat_t sample = 0;
			memcpy(&sample, (bufferLists[i].mBuffers->mData + (sizeof(GMBAudioSample32BitFloat_t) * i)), sizeof(GMBAudioSample32BitFloat_t));
			samplesPerChannel[i] = sample;
		}

		//Now sum those values
		for (int i=0; i < numBufferLists; ++i)
		{
			temp += (GMBAudioSample32BitFloat_t)samplesPerChannel[i];
		}

		if (temp > loudest)
			loudest = temp;
		temp = 0;
	}

//	free(samplesPerChannel);
	return loudest;

}


