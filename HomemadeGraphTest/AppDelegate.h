//
//  AppDelegate.h
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/16/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GMBAVAssetParser.h"
#import "GMBAUGraph.h"
#import "GMBMixer.h"
#import "GMBDelegate.h"
#import "CAUtilityFunctions.h"
#import "GMBChannelStrip.h"
#import "MixerWindow.h"
#import "GMBAVExporter.h"
#import "GMBFourierAnalyzer.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	BOOL playing;
	BOOL						_mediaReady;
	BOOL						_wasPlayingBeforeChangingSeek;
	dispatch_queue_t				backgroundQueue;
	dispatch_queue_t				backgroundQueueSerial;
	NSMutableArray*			 		channelStripArray;
	

	NSTimer*					_bgTimerBasic;
	BOOL						_seekPosMouseUp;
	BOOL						_seekPosMouseDown;
}

@property (assign) IBOutlet NSWindow *window;

@property GMBAVAssetParser*				assetParser;
@property GMBAVExporter*				exporter;
@property GMBMixer*					mixer;
@property GMBAudioStreamBasicDescription*   		asbd;
@property AudioStreamBasicDescription*	  		streamDscrptn;
@property GMBAudioStreamBasicDescription*		dspASBD;
@property GMBDelegate*					del;
@property GMBDelegate*					stopPlayingDelegate;
@property GMBDelegate*					needsNewBufferDelegate;
@property NSMutableArray*				channelStripArray;
@property NSString*					openFileName;
@property BOOL						playing;
@property BOOL						initialized;
@property (weak) IBOutlet NSButton		 	*resetButton;
@property CGPoint					upperLeftCornerOfScreen;
@property BOOL						movieWindowCreated;
@property GMBFourierAnalyzer* 				fourierAnalyzer;


@end
