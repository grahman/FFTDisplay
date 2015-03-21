//
//  GMBAVAssetParser.h
//  AVAssets
//
//  Created by Graham Barab on 6/20/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import "GMBAudioChannel.h"
#import "GMBAudioStreamBasicDescription.h"
#import "GMBAUGraph.h"

#import "GMBUtil.h"
#import "CAUtilityFunctions.h"
#import "GMBObject.h"
#import "GMBFourierAnalyzer.h"

#ifndef CIRCULARBUFFERLISTSIZE
#define CIRCULARBUFFERLISTSIZE 2883584
#endif

typedef struct
{
	UInt32			  bytePos;
	void*			   buf;
	UInt32			  bufSize;
	UInt32			  bytesUsed;
}GMBLeftoverBufferList;

@interface GMBAVAssetParser : GMBObject
{
	GMBLeftoverBufferList*   _leftoverBufferList;
	UInt32			_numAudioAssetReadersReady;
	BOOL			_audioBufferedAndReady;
}


@property AVURLAsset*				URLAsset;
@property AVAsset*				asset;
//@property AVAssetReader*			audioAssetReader;					   //Singular!
@property NSMutableArray*			audioAssetReaders;					  //Contains AVAssetReaders for the audio tracks.
@property AVAssetWriter*			assetWriter;
@property AVPlayerItem*				playerItem;
@property AVPlayer*				player;
@property AVAssetReaderOutput*			assetReaderOutput;
@property NSArray*				audioTracks;
@property NSArray*				videoTracks;
@property AVAssetReaderTrackOutput*		videoTrackOutput;
@property NSMutableArray*			assetReaderAudioTrackOutputs;		   //This will contain GMBAudioChannel's and GMBStereoAudioChannels
@property NSMutableArray*			assetReaderAudioMixOutputs;
@property NSMutableArray*			audioChannelStrips;
@property NSDictionary*				outputSettings;						 //Configure this at some point
@property CMSampleBufferRef			sampleBuffer;						   //Raw audio samples
@property CMAudioFormatDescriptionRef	   	audioFormats;
@property CMTime				duration;							   //in seconds
@property NSMutableArray*			originalAudioStreamBasicDescriptions;   //Stream descriptions from media file metadata
@property NSMutableArray*			playbackAudioStreamBasicDescriptions;   //Stream descriptions for processing and playback
@property GMBAudioStreamBasicDescription*   	assetASBD;
@property (weak) NSDictionary*			playBackSettings;
@property AudioBufferList*			auBufList;
@property NSMutableArray*			audioStreamDataStructs;
@property GMBAudioQueueUserData*		userDataStructs;
@property NSNumber*				mediaIsReady;						   //1 is yes, 0 is no
@property AudioStreamBasicDescription	   	originalASBD;
@property BOOL					audioBufferedAndReady;

-(id) initWithFileURL:(NSString*)mediaItemPath_;
-(void) startReading;
-(void) connectGraph;
-(void) copyNextBuffers;
-(void) seekToTime:(CMTime)time;
-(void)freeUserDataStructs;

+(NSDictionary*) convertASBDToNSDictionary : (AudioStreamBasicDescription)asbd_;

@end

void freeLeftOverBuffer(GMBLeftoverBufferList* inLeftoverBuffer);


