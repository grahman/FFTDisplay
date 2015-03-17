//
//  CAUtilityFunctions.h
//  CAPractice
//
//  Created by Graham on 5/16/13.
//  Copyright (c) 2013 Graham. All rights reserved.
//

#ifndef CAPractice_CAUtilityFunctions_h
#define CAPractice_CAUtilityFunctions_h

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreMedia/CoreMedia.h>
#import "TPCircularBuffer.h"


typedef struct
{
	char c1;
	char c2;
	char c3;
} GMBErrorCodeChars_t;

static const bigBufferSizeInBytes = 26460000;					   //This will use about 25mb

static dispatch_queue_t backgroundQueue;

const static UInt32 BufferSize = 1024;
const static UInt32 BufferSizeInBytes = BufferSize * 4;
const static double SampleRate = 44100;
const static UInt32 BufferListArraySize = 2000;
const static UInt32 nBuffers = 3;

typedef struct
{
	char block1;
	char block2;
	char block3;
} GMBAudioSample24Bit_t ;

typedef Float32 GMBAudioSample32BitFloat_t;

typedef bool (*TriggerFn) ();		   //A generic pointer to a function that does something and returns a bool

typedef struct
{
	CMSampleBufferRef*	  bufferRefs;
	CMBlockBufferRef*	   blockBufferRefs;
	AudioBufferList*		bufferLists;
	UInt32				  bufferCount;

} GMBAudioBufferStructs;

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

typedef struct
{
	TPCircularBuffer							buf;
	unsigned long long						  bytePos;
	unsigned long long						  totalBytesInBuffer;
	bool										isDone;
	AudioStreamBasicDescription				 streamFormat;
}GMBAudioQueueUserData;

typedef struct GMBOutputBus
{
	AudioUnit converter_pre;
	AudioUnit mixer;
	AudioUnit limiter;
	AudioUnit splitter;
	AudioUnit genericOutput;

	AUNode	  converter_preNode;
	AUNode	  mixerNode;
	AUNode	  limiterNode;
	AUNode	  splitterNode;
//	AUNode	  genericOutputNode;
} GMBOutputBus;

enum
{
	GMBOutputSchemeMonoToStereoLinear				 = 0,	//Mono -> Stereo ([1],[2],[3],[4].. => [1,3],[2,4]...)
	GMBOutputSchemeMonoToStereoLinearWithPan		  = 1,	//Mono -> Stereo ([1],[2],[3],[4].. => [1,3],[2,4]...) hard pan
	GMBOutputSchemeMonoToStereoInterleaved			= 2,	//Mono -> Stereo ([1],[2],[3],[4].. => [1,2],[3,4]...)
	GMBOutputSchemeMonoToStereoInterleavedWithPan	 = 3,	//Mono -> Stereo ([1],[2],[3],[4].. => [1,2],[3,4]...) hard pan
	GMBOutputSchemeMonoToStereoOneToOne			   = 4,	//Mono -> Stereo ([1],[2],[3],[4].. => [1,1],[2,2]...)

	GMBOutputSchemeStereoToMonoSummed				 = 5,	//Stereo -> Mono ( [L,R] => [L+R] )
	GMBOutputSchemeStereoToMonoDeinterleave		   = 6,	//Stereo -> Mono ( [L,R] => [L],[R] )
};

typedef int GMBOutputScheme;


void GMBInitUserData(GMBAudioQueueUserData* inUserData);


void CheckError(OSStatus error, const char *operation);
OSStatus MyGetDefaultInputDeviceSampleRate(Float64 *outSampleRate);
int MyComputeRecordBufferSize(const AudioStreamBasicDescription *format,
							AudioQueueRef queue,
							float seconds);
void MyCopyEncoderCookieToFile(AudioQueueRef queue,
							AudioFileID theFile);


//CalculateLPCMFlags is adapted from the c++ inline function defined in Apple's Core Audio Data Types Reference
UInt32 GMBCalculateLPCMFlags (
							UInt32 inValidBitsPerChannel,
							UInt32 inTotalBitsPerChannel,
							bool inIsFloat,
							bool inIsBigEndian,
							bool inIsNonInterleaved
							);

//FillOutASBDForLPCM is adapted from the c++ inline function defined in Apple's Core Audio Data Types Reference
void GMBFillOutASBDForLPCM (
							AudioStreamBasicDescription *outASBD,
							Float64 inSampleRate,
							UInt32 inChannelsPerFrame,
							UInt32 inValidBitsPerChannel,
							UInt32 inTotalBitsPerChannel,
							bool inIsFloat,
							bool inIsBigEndian,
							bool inIsNonInterleaved
							);

inline void GMBFillOutAudioTimeStampWithSampleTime (
												AudioTimeStamp *outATS,
												Float64 inSampleTime
													);
#endif


