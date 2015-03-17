//
//  GMBAudioChannel.m
//  AVAssets
//
//  Created by Graham Barab on 6/19/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBAudioChannel.h"
#import <math.h>

const AudioStreamBasicDescription* GMBConvertToAudioStreamBasicDescription(CMAudioFormatDescriptionRef descrptnRef)
{
	const AudioStreamBasicDescription* streamDscrptn = CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)descrptnRef);
	return streamDscrptn;
}

@implementation GMBNumberWithInclusiveDomain
@synthesize floor;
@synthesize ceiling;

-(id) initWithFloor:(NSNumber *)Floor andCeiling:(NSNumber*)Ceiling
{
	self = [super init];
	val = [[NSNumber alloc] init];
	if (Floor > Ceiling )
	{
		NSNumber* temp = Floor;
		Floor = Ceiling;
		Ceiling = temp;
	}
	floor =   [[NSNumber alloc] initWithDouble:[Floor doubleValue]];
	ceiling = [[NSNumber alloc] initWithDouble:[Ceiling doubleValue]];

	return self;
}

-(NSNumber*)Value
{
	return val;
}

-(void) setValue:(NSNumber *)value
{
//	if (value < floor || value > ceiling)
//	{
//		double distanceFromFloor = abs([floor doubleValue] - [value doubleValue]);
//		double distanceFromCeiling = abs([ceiling doubleValue] - [value doubleValue]);
//		value = (distanceFromFloor > distanceFromCeiling) ?
//	}

	if (value < floor)
	{
		val = floor;
	} else if (value > ceiling)
	{
		val = ceiling;
	} else
	{
		val = value;
	}
}

@end

@implementation GMBAudioChannel
@synthesize inputBuffers;
@synthesize volume;
@synthesize pan;
@synthesize chanAUGraph;
@synthesize channelInfo;
@synthesize assetReaderTrackOutput;

-(id) init
{
	self = [super init];
	linearVolume = [[NSNumber alloc] initWithInt:0];
	pan = [[GMBNumberWithInclusiveDomain alloc] initWithFloor:[NSNumber numberWithInt:-1] andCeiling:[NSNumber numberWithInt:1]];
	_signalType = kMonoType;
	chanAUGraph = [[GMBAUGraph alloc] init];
	channelInfo.inChannels = 1;
	channelInfo.outChannels = 1;
	return self;
}



-(int)signalType
{
	return _signalType;
}

-(void)setSignalType:(int)signalType_
{
	if (signalType_ != kMonoType && signalType_ != kStereoType && signalType_ != kSurroundType)
	{
		_signalType = kMonoType;
		return;
	}
	_signalType = signalType_;
}

-(void)connectCallback
{

	CheckError(AUGraphAddRenderNotify(chanAUGraph.graph, audioUnitRenderCallback, (__bridge void *)(self)), "AUGraphAddRenderNotify");
}


@end



static OSStatus audioUnitRenderCallback(void *inRefCon,
										AudioUnitRenderActionFlags *ioActionFlags,
										const AudioTimeStamp *inTimeStamp,
										UInt32 inBusNumber,
										UInt32 inNumberFrames,
										AudioBufferList *ioData) {
//	OSStatus err = noErr;
	__unsafe_unretained GMBAudioChannel *self = (__bridge GMBAudioChannel*)inRefCon;

	//Get more audio and route it to where it needs to go
	CMBlockBufferRef buffer;
	CMSampleBufferRef sampleBufferRef = [self.assetReaderTrackOutput copyNextSampleBuffer];
	AudioBufferList auBufferList;
	CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBufferRef, NULL, &auBufferList, sizeof(auBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &buffer);


	return noErr;

}




