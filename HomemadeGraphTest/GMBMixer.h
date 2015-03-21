//
//  GMBMixer.h
//  AVAssets2
//
//  Created by Graham Barab on 6/24/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonHeaders.h"
#import "GMBAUGraph.h"
#import "GMBAudioChannel.h"
#import "CAUtilityFunctions.h"
#import "GMBAVAssetParser.h"
#import "lpf.h"

static void* nSourceTracksContext = &nSourceTracksContext;

static OSStatus inputRenderCallback (void		*inRefCon,	  // A pointer to a struct containing the complete audio data
									//to play, as well as state information such as the
									//first sample to play on this invocation of the callback.
			AudioUnitRenderActionFlags 	*ioActionFlags, // Unused here. When generating audio, use ioActionFlags to indicate silence
									//between sounds; for silence, also memset the ioData buffers to 0.
			const AudioTimeStamp		*inTimeStamp,   // Unused here.
			UInt32				inBusNumber,	// The mixer unit input bus that is requesting some new
									//frames of audio data to play.
			UInt32				inNumberFrames, // The number of frames of audio to provide to the buffer(s)
									//pointed to by the ioData parameter.
			AudioBufferList			*ioData		// On output, the audio data to play. The callback's primary
									//responsibility is to fill the buffer(s) in the
									//AudioBufferList.
);

enum ChannelType
{
	kAudioChannelType,
	kBusChannelType,
	kOutputChannelType
};

@interface GMBMixer : NSObject

//---------All channel strip arrays contain GMBAudioChannel object instances--------------//
@property NSMutableArray*				   audioChannelStrips;
@property NSMutableArray*				   busChannelStrips;
@property NSMutableArray*				   outputChannelStrips;
@property GMBAUGraph*					   graph;					  //The main AUGraph
@property AUNode*							mixerNode;
@property AudioUnit*						mixer;
@property GMBAudioStreamBasicDescription*	asbd;
@property NSUInteger						mixerInputsUsed;
@property BOOL							  isProcessingGraph;
@property AudioConverterRef*				audioConverter;
@property BOOL							  needsNewSampleBuffer;
@property BOOL							  hasMoreSampleBuffersToProvide;
@property GMBAudioQueueUserData*			userDataStructs;
@property NSNumber*						 nSourceTracks;			  //Number of source tracks from asset
@property NSNumber*						 nOutputBusses;

-(id) init;
-(void)startGraph;
-(void)stopGraph;
-(void)dealloc;
-(void)registerCallbacks;
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;


@end


