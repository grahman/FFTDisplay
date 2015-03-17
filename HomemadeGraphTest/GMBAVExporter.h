//
//  GMBAVExporter.h
//  AVAssets2
//
//  Created by Graham Barab on 7/11/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CAUtilityFunctions.h"
#import "GMBAUGraph.h"
#import "GMBAVAssetParser.h"

static const UInt32 bufferSize = 512;

typedef struct
{
	AudioBufferList bufferList;
	UInt32 pos;
} GMBBufferListStruct;

typedef struct
{
	GMBAudioSample32BitFloat_t			 loudestSampleValue;			 //Linear, not log!
	GMBAudioSample32BitFloat_t			 targetAmplitude;				//Linear, not log!
}GMBNormalizationUserData;

@interface GMBAVExporter : NSObject
{
	unsigned long long					  _dataByteSizeOfUserDataStructs;
	GMBNormalizationUserData				_normalizationUserData;
	bool*								   _convertedBusNumbersArray;
	AudioConverterRef*					  _audioConverterRef;
}

@property AVAssetWriter*					assetWriter;
@property AVAssetReader*					videoTrackReader;
@property NSMutableArray*				   assetWriterInputsAudio;
@property AVAssetWriterInput*			   videoInput;
@property AudioBufferList*				  bufferListArray;
@property GMBAUGraph*					   graph;
@property GMBAVAssetParser*				 assetParser;
@property GMBAudioQueueUserData*			userDataStructs;
@property UInt32							numAudioTracks;				 //Number of audio tracks / user data structures
@property AudioStreamBasicDescription*	  asbds;
@property dispatch_queue_t				  inputSerialDispatchQueue;
@property BOOL							  normalizeOutputs;
@property bool*							 convertedBusNumbersArray;
@property AudioStreamBasicDescription*	  userRequestedASBDs;
@property BOOL							  normalize;

-(id) init;
-(id) initWithGraph:(GMBAUGraph*)graph_
	withUserDataStructs:(GMBAudioQueueUserData*)userDataStructs_
	numberOfStructs:(UInt32)numStructs_
	withAssetParser:(GMBAVAssetParser*)assetParser_
 withDestinationURL:(NSURL*)url_;
-(void)normalizationPass;
-(void) startExport;

@end

//Utility functions
GMBAudioSample32BitFloat_t getLoudestAmplitudeFromBuffer(AudioBufferList* bufferLists, UInt32 numBufferLists);


