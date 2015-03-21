//
//  GMBAUGraph.m
//  AVAssets2
//
//  Created by Graham Barab on 6/21/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBAUGraph.h"
//#import "CommonHeaders.h"

@implementation GMBAUGraph

@synthesize playing;
@synthesize setupDone;
@synthesize nSourceTracks;
@synthesize graph;
@synthesize limiter;
@synthesize limiterComponentDescription;
@synthesize multiMixer;
@synthesize limiterNode;
@synthesize multiMixerNode;
@synthesize multiMixerComponentDescription;
@synthesize outputComponentDescription;
@synthesize converterComponentDescription;
@synthesize splitterComponentDescription;
@synthesize mergerComponentDescription;
@synthesize outputNode;
@synthesize outputUnit;
@synthesize outputTrackBusArray;

@synthesize insertNodes;
@synthesize insertComponentDescriptions;
@synthesize inserts;
@synthesize nodeRenderCallbacks;
@synthesize renderCallback;
@synthesize renderCallbackStructs;
@synthesize renderCallbackList;
@synthesize userDataStructs;
@synthesize outputBusArray;
@synthesize genericOutputComponentDescription;



-(id) init
{
	self = [super init];
	setupDone = NO;
	renderCallbackList = [[NSMutableArray alloc] init];
	nSourceTracks = [NSNumber alloc];
	insertNodes = malloc(sizeof(AUNode)* MAXINSERTS);
	if (!insertNodes)
		die("insertNodes malloc failed\n");
	insertComponentDescriptions = malloc(sizeof(AudioComponentDescription) * MAXINSERTS);
	if (!insertComponentDescriptions)
		die("insertComponentDesriptions malloc failed\n");
	inserts = malloc(sizeof(AudioUnit) * MAXINSERTS);
	if (!inserts)
		die("inserts malloc failed\n");
	nodeRenderCallbacks = malloc(sizeof(AUNodeRenderCallback) * MAXINSERTS);
	if (!nodeRenderCallbacks)
		die("nodeRenderCallbacks malloc failed\n");
	renderCallbackStructs = malloc(sizeof(AURenderCallbackStruct));
	if (!renderCallbackStructs)
		die("renderCallbackStructs malloc failed\n");
	renderCallback = malloc(sizeof(AURenderCallback*));
	if (!renderCallback)
		die("renderCallback malloc failed\n");


	limiterComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	limiterComponentDescription.componentType = kAudioUnitType_Effect;
	limiterComponentDescription.componentSubType = kAudioUnitSubType_PeakLimiter;
	limiterComponentDescription.componentFlags = 0;
	limiterComponentDescription.componentFlagsMask = 0;

	multiMixerComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	multiMixerComponentDescription.componentType = kAudioUnitType_Mixer;
	multiMixerComponentDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	multiMixerComponentDescription.componentFlags = 0;
	multiMixerComponentDescription.componentFlagsMask = 0;

	outputComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	outputComponentDescription.componentType = kAudioUnitType_Output;
	outputComponentDescription.componentSubType = kAudioUnitSubType_DefaultOutput;
	outputComponentDescription.componentFlags = 0;
	outputComponentDescription.componentFlagsMask = 0;

	genericOutputComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	genericOutputComponentDescription.componentType = kAudioUnitType_Output;
	genericOutputComponentDescription.componentSubType = kAudioUnitSubType_GenericOutput;
	genericOutputComponentDescription.componentFlags = 0;
	genericOutputComponentDescription.componentFlagsMask = 0;

	splitterComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	splitterComponentDescription.componentType = kAudioUnitType_FormatConverter;
	splitterComponentDescription.componentSubType = kAudioUnitSubType_Splitter;
	splitterComponentDescription.componentFlags = 0;
	splitterComponentDescription.componentFlagsMask = 0;

	mergerComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	mergerComponentDescription.componentType = kAudioUnitType_FormatConverter;
	mergerComponentDescription.componentSubType = kAudioUnitSubType_Merger;
	mergerComponentDescription.componentFlags = 0;
	mergerComponentDescription.componentFlagsMask = 0;

	converterComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	converterComponentDescription.componentType = kAudioUnitType_FormatConverter;
	converterComponentDescription.componentSubType = kAudioUnitSubType_AUConverter;
	converterComponentDescription.componentFlags = 0;
	converterComponentDescription.componentFlagsMask = 0;


	return self;
}

-(id) initGraphWithUserDataStruct:(GMBAudioQueueUserData *)userDataStructs_ numberOfStructs:(NSNumber *)nStructs_
{

	NSAssert((nStructs_ != nil), @"GMBAUGraph::initGraphWithUserDataStruct: nSructs_ cannot be nil");

	self = [self init];
	nSourceTracks = nStructs_;
	userDataStructs = userDataStructs_;
	outputTrackBusArray = [[NSMutableArray alloc] init];
	limiterNode = malloc(sizeof(AUNode));
	multiMixerNode = malloc(sizeof(AUNode));
	outputNode = malloc(sizeof(AUNode));
	CheckError(NewAUGraph(&graph), "Making a new AUGraph");

	CheckError(AUGraphAddNode(graph, &(multiMixerComponentDescription), multiMixerNode), "Adding graph node for mixer node");
	[self didChangeValueForKey:NSStringFromSelector(@selector(multiMixerNode))];
	CheckError(AUGraphAddNode(graph, &(outputComponentDescription), outputNode), "Adding graph node for output node");

	CheckError(AUGraphOpen(graph), "Opening the AUGraph");

	CheckError(AUGraphNodeInfo(graph, *(multiMixerNode), NULL, &(multiMixer)), "AUGraphNodeInfo");
	CheckError(AUGraphNodeInfo(graph, *(outputNode), NULL, &(outputUnit)), "Instantiating outputUnit with AUGraphNodeInfo failed");
	//Configure the mixer
	UInt32 busCount   = [nSourceTracks intValue];	// bus count for mixer unit input
	outputBusArray = malloc(sizeof(GMBOutputBus) * busCount);
	CheckError(AudioUnitSetProperty(multiMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof(busCount)), "AudioUnitSetProperty");

	for (int i=0; i < busCount; ++i)
	{
		//Get and set stream format property data
		Boolean *outBool = malloc(sizeof(Boolean));
		AudioStreamBasicDescription streamFormat = userDataStructs[i].streamFormat;
		GMBFillOutASBDForLPCM(&streamFormat, streamFormat.mSampleRate, streamFormat.mChannelsPerFrame, 32, 32, true, false, true);

		//Set up output bus array
		CheckError(AUGraphAddNode(graph, &converterComponentDescription, &outputBusArray[i].converter_preNode), "Error adding node for converter_pre");
		CheckError(AUGraphNodeInfo(graph, outputBusArray[i].converter_preNode, NULL, &outputBusArray[i].converter_pre), "Error obtaining converter_pre instance");

		CheckError(AUGraphAddNode(graph, &multiMixerComponentDescription, &outputBusArray[i].mixerNode), "Error adding node for converter_pre");
		CheckError(AUGraphNodeInfo(graph, outputBusArray[i].mixerNode, NULL, &outputBusArray[i].mixer), "Error obtaining converter_pre instance");

		CheckError(AUGraphAddNode(graph, &limiterComponentDescription, &outputBusArray[i].limiterNode), "Error adding node for limiter");
		CheckError(AUGraphNodeInfo(graph, outputBusArray[i].limiterNode, NULL, &outputBusArray[i].limiter), "Error obtaining limiter instance");

		CheckError(AUGraphAddNode(graph, &splitterComponentDescription, &outputBusArray[i].splitterNode), "Error adding node for splitter");
		CheckError(AUGraphNodeInfo(graph, outputBusArray[i].splitterNode, NULL, &outputBusArray[i].splitter), "Error obtaining splitter instance");


		//Now set properties for the output bus array
		CheckError(AudioUnitSetProperty(outputBusArray[i].converter_pre, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, sizeof(streamFormat)), "Error setting stream format of converter_pre input");
		CheckError(AudioUnitSetProperty(outputBusArray[i].converter_pre, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &streamFormat, sizeof(streamFormat)), "Error setting stream format of converter_pre input");
		CheckError(AudioUnitSetProperty(outputBusArray[i].mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, sizeof(streamFormat)), "Error setting stream format for mixer input");
		CheckError(AudioUnitSetProperty(outputBusArray[i].mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &streamFormat, sizeof(streamFormat)), "Error setting stream format for mixer output");
		CheckError(AudioUnitSetProperty(outputBusArray[i].splitter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, sizeof(streamFormat)), "Error setting stream format for splitter input");
		CheckError(AudioUnitSetProperty(outputBusArray[i].splitter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &streamFormat, sizeof(streamFormat)), "Error setting stream format for splitter output");
		CheckError(AudioUnitSetProperty(outputBusArray[i].splitter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &streamFormat, sizeof(streamFormat)), "Error setting stream format for splitter output");
		CheckError(AudioUnitSetProperty(outputBusArray[i].limiter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, sizeof(streamFormat)), "Error setting stream format for limiter input");
		CheckError(AudioUnitSetProperty(outputBusArray[i].limiter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &streamFormat, sizeof(streamFormat)), "Error setting stream format for limiter output");


		CheckError(AudioUnitSetProperty(multiMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &streamFormat, sizeof(streamFormat)), "Error setting stream format of main multimixer input i");


		//Unmute the mixers
		CheckError(AudioUnitSetParameter(outputBusArray[i].mixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, 1.0, 0), "Setting bus mixer input volume to 1.0");
		CheckError(AudioUnitSetParameter(outputBusArray[i].mixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, 1.0, 0), "Setting bus mixer output volume to 1.0");


		//Now wire up the output bus array
		CheckError(AUGraphConnectNodeInput(graph, outputBusArray[i].converter_preNode, 0, outputBusArray[i].mixerNode, 0), "Error connecting converter_pre to mixer");
		CheckError(AUGraphConnectNodeInput(graph, outputBusArray[i].mixerNode, 0, outputBusArray[i].limiterNode, 0), "Error connecting mixer to limiter");
		CheckError(AUGraphConnectNodeInput(graph, outputBusArray[i].limiterNode, 0, outputBusArray[i].splitterNode, 0), "Error connecting limiter to splitter");


		CheckError(AudioUnitSetProperty(multiMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &streamFormat, sizeof(streamFormat)), "Setting stream format of mixer input");
		CheckError(AudioUnitSetParameter(multiMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, i, 1.0, 0), "Setting mixer volume to 1.0");
		CheckError(AUGraphConnectNodeInput(graph, outputBusArray[i].splitterNode, 0, *(multiMixerNode), i), "Error connecting outputBusArray element to main multimixer");

		CheckError(AUGraphUpdate(graph, outBool), "Updating AUGraph");

		//Now set up a generic output that is separate from the AUGraph (only one output per graph!)
		AudioComponent outputComponent;
		outputComponent = AudioComponentFindNext(NULL, &genericOutputComponentDescription);
		AudioComponentInstanceNew(outputComponent, &outputBusArray[i].genericOutput);
		CheckError(AudioUnitSetProperty(outputBusArray[i].genericOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, sizeof(AudioStreamBasicDescription)), "Error setting stream format for generic output input");
		AudioUnitConnection splitterToGenOutputConnection = {0};
		splitterToGenOutputConnection.sourceAudioUnit = outputBusArray[i].splitter;
		splitterToGenOutputConnection.sourceOutputNumber = 1;
		splitterToGenOutputConnection.destInputNumber = 0;
		CheckError(AudioUnitSetProperty(outputBusArray[i].genericOutput, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, 0, &splitterToGenOutputConnection, sizeof(AudioUnitConnection)), "Error manually connecting splitter output 1 to generic output input bus 0");
		free(outBool);
	}
	CheckError(AudioUnitSetParameter(multiMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, 1.0, 0), "Setting mixer volume to 1.0");
	AudioStreamBasicDescription mixerOutASBD = {0};
	GMBFillOutASBDForLPCM(&mixerOutASBD, userDataStructs[0].streamFormat.mSampleRate, 2, 32, 32, true, false, true);
	CheckError(AudioUnitSetProperty(multiMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mixerOutASBD, sizeof(AudioStreamBasicDescription)), "Setting stream format of mixer output");
	//The last set property doesn't change the sample rate for some reason, let's try this...
	UInt32 propSize;
	Boolean writeable;
	CheckError(AudioUnitGetPropertyInfo(multiMixer, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &propSize, &writeable), "Couldn't get mixer output sampler rate propInfo");
	double sr = 0;
	CheckError(AudioUnitGetProperty(multiMixer, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &sr, &propSize), "Couldn't get mixer output samplerate");
	CheckError(AudioUnitSetProperty(multiMixer, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &sr, sizeof(sr)), "Couldn't set mixer output samplerate");
	CheckError(AudioUnitGetProperty(multiMixer, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &sr, &propSize), "Couldn't get mixer output samplerate");

	CheckError(AudioUnitGetPropertyInfo(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &propSize, &writeable), "Couldn't get property info about the stream format for the output unit");
	AudioStreamBasicDescription defaultOutputASBD = {0};
	UInt32 asbdSize = sizeof(AudioStreamBasicDescription);
	CheckError(AudioUnitGetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &defaultOutputASBD, &asbdSize), "Getting streamformat of output input bus 0");
	defaultOutputASBD.mSampleRate = userDataStructs->streamFormat.mSampleRate;
	CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &defaultOutputASBD, propSize), "Setting SR of the output input bus 0");
	CheckError(AUGraphConnectNodeInput(graph, *(multiMixerNode), 0, *(outputNode), 0), "Connecting the two nodes");

	//Set the sample rate for the mixer output
	CheckError(AudioUnitSetProperty(multiMixer, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &userDataStructs->streamFormat.mSampleRate , sizeof(userDataStructs->streamFormat.mSampleRate)), "Setting the sample rate of the mixer output");


	//Apparently, the next several lines "instantiate" the audio units
	//	CheckError(AUGraphNodeInfo(graph, *(multiMixerNode), NULL, &multiMixer), "Instantiating limiter with AUGraphNodeInfo");
	CheckError(AUGraphNodeInfo(graph, *(outputNode), NULL, &outputUnit), "Instantiating multiMixer with AUGraphNodeInfo");

	[self setSetupDone:YES];
	return self;
}






-(void)startGraph
{
	if (graph)
	{
		Boolean outIsInitialized;
		Boolean isRunning;
		CheckError(AUGraphIsInitialized(graph, &outIsInitialized), "Checking if Graph is initialized");

		if (!outIsInitialized)
		{
			CheckError(AUGraphInitialize(graph), "AUGraphInitialize");
		}

		CheckError(AUGraphIsRunning(graph, &isRunning), "AUGraphIsRunning");

		if (!isRunning)
		{
			CheckError(AUGraphStart(graph), "AUGraphStart");
			playing = YES;
		}
	}
}

-(void) setAsbd:(GMBAudioStreamBasicDescription *)asbd
{
	_asbd = [[GMBAudioStreamBasicDescription alloc] initWithAudioStreamBasicDescription:asbd.asbd];
}

-(GMBAudioStreamBasicDescription*) asbd
{
	return _asbd;
}

-(void)connectCallback
{
	if (renderCallback)
	{
		CheckError(AUGraphAddRenderNotify(graph, *renderCallback, (__bridge void *)(self)), "AUGraphAddRenderNotify");
	} else{
		assert(false);
	}
}


-(BOOL)convertBusOutputStreamFormat:(NSUInteger)busNumber withStreamType:(AudioStreamBasicDescription)asbd_
{
	Boolean isInitialized;
	Boolean isRunning;
	AudioStreamBasicDescription currentASBD = {0};
	UInt32 asbdSize;
	CheckError(AUGraphIsRunning(graph, &isRunning), "Error checking if graph is running");
	if (isRunning)
		CheckError(AUGraphStop(graph), "Error stopping the graph");

	CheckError(AUGraphIsInitialized(graph, &isInitialized), "Error checking if graph is initialized");
	if (isInitialized)
	{
		CheckError(AUGraphUninitialize(graph), "Error uninitializing the graph");

		//Disconnect audio units from eachother before setting their properties.
		CheckError(AUGraphDisconnectNodeInput(graph, outputBusArray[busNumber].mixerNode, 0), "Error disconnecting converter from mixer");
		CheckError(AUGraphDisconnectNodeInput(graph, outputBusArray[busNumber].limiterNode, 0), "Error disconnecting mixer from limiter");
		CheckError(AUGraphDisconnectNodeInput(graph, outputBusArray[busNumber].splitterNode, 0), "Error disconnecting limiter from splitter");
		CheckError(AUGraphDisconnectNodeInput(graph, *(multiMixerNode), (UInt32)busNumber), "Error disconnecting converter from mixer");

		//Set the properties
		CheckError(AudioUnitGetProperty(outputBusArray[busNumber].converter_pre, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &currentASBD, &asbdSize), "Error obtaining the current stream format of converter_pre input");
		CheckError(AudioUnitSetProperty(outputBusArray[busNumber].converter_pre, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd_, sizeof(AudioStreamBasicDescription)), "Error setting the input stream description for converter_pre");
		CheckError(AudioUnitSetProperty(outputBusArray[busNumber].converter_pre, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd_, sizeof(asbd_)), "Error setting the input stream description for converter_pre");
		CheckError(AudioUnitSetProperty(outputBusArray[busNumber].mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd_, sizeof(AudioStreamBasicDescription)), "Error updating the stream format of mixer output");
		CheckError(AudioUnitSetProperty(outputBusArray[busNumber].limiter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd_, sizeof(AudioStreamBasicDescription)), "Error updating the stream format of mixer output");
		CheckError(AudioUnitSetProperty(outputBusArray[busNumber].splitter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd_, sizeof(AudioStreamBasicDescription)), "Error updating the stream format of mixer output");
		CheckError(AudioUnitSetProperty(outputBusArray[busNumber].splitter, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd_, sizeof(AudioStreamBasicDescription)), "Error updating the stream format of mixer output");


		//Now reconnect all the nodes
		CheckError(AUGraphConnectNodeInput(graph, outputBusArray[busNumber].converter_preNode, 0, outputBusArray[busNumber].mixerNode, 0), "Error re-connecting converter_pre to mixer");
		CheckError(AUGraphConnectNodeInput(graph, outputBusArray[busNumber].mixerNode, 0, outputBusArray[busNumber].limiterNode, 0), "Error re-connecting mixernode to limiternode");
		CheckError(AUGraphConnectNodeInput(graph, outputBusArray[busNumber].limiterNode, 0, outputBusArray[busNumber].splitterNode, 0), "Error re-connecting converter_pre to mixer");
		CheckError(AUGraphConnectNodeInput(graph, outputBusArray[busNumber].splitterNode, 0, *multiMixerNode, (UInt32)busNumber), "Error re-connecting converter_pre to mixer");

		CheckError(AUGraphInitialize(graph), "Error re-initializing the graph");

		//If graph had been running before, then resume playing back audio automatically
		if (isRunning)
			CheckError(AUGraphStart(graph), "Error resuming playback");
	}
	return YES;
}

-(void)dealloc
{
	free(insertNodes);
	free(insertComponentDescriptions);
	free(inserts);
	free(nodeRenderCallbacks);
	free(renderCallbackStructs);
	free(renderCallback);
	free(limiterNode);
	free(multiMixerNode);
	free(outputNode);
}
@end


