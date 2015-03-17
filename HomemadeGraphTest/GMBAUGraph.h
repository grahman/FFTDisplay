//
//  GMBAUGraph.h
//  AVAssets2
//
//  Created by Graham Barab on 6/21/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonHeaders.h"
#import "CAUtilityFunctions.h"

#ifndef MAXINSERTS
#define MAXINSERTS 10
#endif


@interface GMBAUGraph : NSObject
{
	GMBAudioStreamBasicDescription* _asbd;
}

@property (readwrite) BOOL							  playing;

@property (readwrite) AUGraph						   graph;
@property			 NSNumber*						 nSourceTracks;
@property BOOL										  setupDone;

@property (readwrite) AUNode*						   insertNodes;
@property (readwrite) AudioUnit*						inserts;
@property (readwrite) AudioComponentDescription*		insertComponentDescriptions;
@property (readwrite) AUNode*						   limiterNode;
@property (readwrite) AUNode*						   multiMixerNode;
@property (readwrite) AUNode*						   outputNode;
@property (readwrite) AUNode*						   splitterNode;
@property (readwrite) AudioUnit						 limiter;
@property (readwrite) AudioUnit						 multiMixer;
@property (readwrite) AudioUnit						 outputUnit;
@property (readwrite) AudioUnit						 splitter;
@property (readwrite) AudioComponentDescription		 limiterComponentDescription;
@property (readwrite) AudioComponentDescription		 multiMixerComponentDescription;
@property (readwrite) AudioComponentDescription		 outputComponentDescription;
@property (readwrite) AudioComponentDescription		 splitterComponentDescription;
@property (readwrite) AudioComponentDescription		 mergerComponentDescription;
@property (readwrite) AudioComponentDescription		 converterComponentDescription;
@property (readwrite) AudioComponentDescription		 genericOutputComponentDescription;
@property (strong)	GMBAudioStreamBasicDescription*   asbd;
@property NSMutableArray*							   outputTrackBusArray;
@property AUNodeRenderCallback*						 nodeRenderCallbacks;
@property AURenderCallbackStruct*					   renderCallbackStructs;
@property AURenderCallback*							 renderCallback;
@property NSMutableArray*							   renderCallbackList;
@property GMBAudioQueueUserData*						userDataStructs;
@property GMBOutputBus*								 outputBusArray;



-(id) init;
-(id) initGraphWithUserDataStruct : (GMBAudioQueueUserData*)userDataStructs
									numberOfStructs : (NSNumber*)nStructs;

-(void) startGraph;
-(void) connectCallback;
-(BOOL) convertBusOutputStreamFormat : (NSUInteger)busNumber withStreamType:(AudioStreamBasicDescription) asbd_;
-(BOOL) useDefaultOutput;


//-(BOOL) stopAUGraph;

@end


