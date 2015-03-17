//
//  GMBChannelStrip.h
//  CollectionViewsTake2
//
//  Created by Graham Barab on 7/3/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CAUtilityFunctions.h"
#import "GMBAUGraph.h"
#import "GMBBackgroundTimer.h"
#import "GMBObject.h"

typedef struct
{
	float peak;

}GMBLevelMeterUserData;

typedef bool (*TriggerFn) ();		   //A generic pointer to a function that does something and returns a bool

//typedef struct
//{
//	char*								   buf;
//	unsigned long long					  bytePos;
//	unsigned long long					  totalBytesInBuffer;
//	int									 numberOfConsumedBlocks;
//	bool									isDone;
//	AudioStreamBasicDescription			 streamFormat;
//	TriggerFn*							  externalMessage;
//} GMBAudioQueueUserData;

enum
{
	kRadioButtonSelectedIndex_Mono = 0,
	kRadioButtonSelectedIndex_Stereo = 1
};


@interface GMBChannelStrip : GMBObject <NSCopying>
{
	double					  gain;
	double					  pan;
//	double					  gainLog;
	NSNumber*				   channelNum;
	GMBAudioQueueUserData*	  userData;
	float					   _levelMeterValue;
	NSString*				   name;
	NSMutableArray*			 outputDestinations;
	int						 monoOrStereo;
	NSNumber*				   _isMonoOrStereo;
	GMBOutputBus*			   outputBus;
	GMBLevelMeterUserData	   levelMeterUserData;
}

@property double			gain;
@property double			gainLog;
@property double			gainLogControlValue;
@property double			pan;
@property int			   monoOrStereo;
@property NSNumber*		 isMonoOrStereoNSNumber;
@property NSNumber*		 channelNum;
@property float			 levelMeterValue;
@property NSString*		 name;
@property GMBOutputBus*	 outputBus;
@property GMBAUGraph*		  graph;
@property GMBAudioQueueUserData*	 userDataStruct;
@property NSTimer*		  levelMeterTimer;
@property GMBBackgroundTimer*  bgTimer;

-(id)init;
-(id)initWithChannelNum:(NSNumber*)channelNum_
	withUserDataStruct: (GMBAudioQueueUserData*)userData_
	withOutputBusArray: (GMBOutputBus*)outputBus_
			withGraph: (GMBAUGraph*)graph_;
-(id)copyWithZone:(NSZone*)zone;
@end


