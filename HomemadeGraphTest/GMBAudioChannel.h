//
//  GMBAudioChannel.h
//  AVAssets
//
//  Created by Graham Barab on 6/19/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "CommonHeaders.h"
#import "GMBAUGraph.h"


const AudioStreamBasicDescription* GMBConvertToAudioStreamBasicDescription(CMAudioFormatDescriptionRef descrptnRef);

typedef CMSampleBufferRef ConnectionBufferRef;
enum AUSignalType{
	kMonoType,
	kStereoType,
	kSurroundType,
};

@interface GMBNumberWithInclusiveDomain : NSObject
{
	NSNumber*   val;
	bool		floorSet;
	bool		ceilSet;
}

@property NSNumber* Value;
@property NSNumber* floor;
@property NSNumber* ceiling;

-(id) initWithFloor : (NSNumber*)Floor andCeiling:(NSNumber*)Ceiling;


@end

@interface GMBAudioChannel : NSObject
{
	NSNumber* linearVolume;
	int	   _signalType;
}

@property NSMutableArray*			   inputBuffers;
@property NSMutableArray*			   outputBuffers;
@property AVAssetReaderTrackOutput*	 assetReaderTrackOutput;
@property GMBAUGraph*				   chanAUGraph;			//This is where the signal processing happens
@property NSNumber*					 volume;
@property GMBNumberWithInclusiveDomain* pan;					//Domain is -1 to 1 (left to right)
//@property
@property int						   signalType;			 //kMonoType or kStereoType
@property AUChannelInfo				 channelInfo;			//number of input and output channels


-(id)init;
//-(BOOL)createGraph;
-(void)connectCallback;



@end

static OSStatus audioUnitRenderCallback(void *inRefCon,
										AudioUnitRenderActionFlags *ioActionFlags,
										const AudioTimeStamp *inTimeStamp,
										UInt32 inBusNumber,
										UInt32 inNumberFrames,
										AudioBufferList *ioData);



