//
//  CAUtilityFunctions.c
//  CAPractice
//
//  Created by Graham on 5/16/13.
//  Copyright (c) 2013 Graham. All rights reserved.
//

#include <stdio.h>
//#include <AudioToolbox/AudioToolbox.h>
#include "CAUtilityFunctions.h"

void CheckError(OSStatus error, const char *operation)
{
	if (error==noErr) return;

	char errorString[20];
	//see if it appears to be a 4-character code.
	*(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
	if (isprint(errorString[1] && isprint(errorString[2] &&
										isprint(errorString[3] &&
												isprint(errorString[4])))))
	{
		errorString[0] = errorString[5] = '\'';
		errorString[6] = '\0';
	} else {
		//No, format it as an integer
		sprintf(errorString, "%d", (int)error);
	}

	sprintf(errorString, "Error: %s (%s)\n", operation, errorString);
	printf("Error: %s (%s)\n", operation, errorString);

	exit(1);
}

OSStatus MyGetDefaultInputDeviceSampleRate(Float64 *outSampleRate)
{
	OSStatus error;

	AudioObjectPropertyAddress propertyAddress;
	UInt32 propertySize;
	propertyAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice;
	propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
	propertyAddress.mElement = 0;
	propertySize = sizeof(AudioDeviceID);
	error = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, outSampleRate);
	return error;
}

int MyComputeRecordBufferSize(const AudioStreamBasicDescription *format,
							AudioQueueRef queue,
							float seconds)
{
	int packets, frames, bytes;
	frames = (int)ceil(seconds * format->mSampleRate);

	if (format->mBytesPerFrame > 0)
	{
		bytes = frames * format->mBytesPerFrame;
	} else {
		UInt32 maxPacketSize;
		if (format->mBytesPerPacket)
			//constant packet size
			maxPacketSize = format->mBytesPerPacket;
		else
		{
			//Get the largest single packet size possible
			UInt32 propertySize = sizeof(maxPacketSize);
			CheckError(AudioQueueGetProperty(queue,
											kAudioConverterPropertyMaximumOutputPacketSize,
											&maxPacketSize,
											&propertySize),
					"Couldn't get queue's maximum output packet size");
		}
		if (format->mFramesPerPacket > 0)
			packets = frames /format->mFramesPerPacket;
		else
			//Worst case scenario: 1 frame in a packet
			packets = frames;

		//Sanity Check
		if (packets == 0)
			packets = 1;
		bytes = packets * maxPacketSize;
	}
	return bytes;
}

void MyCopyEncoderCookieToFile(AudioQueueRef queue,
							AudioFileID theFile)
{
	OSStatus error;
	UInt32 propertySize;

	error = AudioQueueGetPropertySize(queue, kAudioConverterCompressionMagicCookie, &propertySize);

	if (error == noErr && propertySize > 0)
	{
		Byte *magicCookie = (Byte *)malloc(propertySize);
		CheckError(AudioQueueGetProperty(queue,
										kAudioQueueProperty_MagicCookie,
										magicCookie,
										&propertySize),
				"Couldn't get audio queue's magic cookie!");

		CheckError(AudioFileSetProperty(theFile,
										kAudioFilePropertyMagicCookieData,
										propertySize,
										magicCookie),
				"Couldn't set audio file's magic cookie");
		free(magicCookie);
	}
}

UInt32 GMBCalculateLPCMFlags (
							UInt32 inValidBitsPerChannel,
							UInt32 inTotalBitsPerChannel,
							bool inIsFloat,
							bool inIsBigEndian,
							bool inIsNonInterleaved
							)
{
	return
	(inIsFloat ? kAudioFormatFlagIsFloat : kAudioFormatFlagIsSignedInteger) |
	(inIsBigEndian ? ((UInt32)kAudioFormatFlagIsBigEndian) : 0)			 |
	((!inIsFloat && (inValidBitsPerChannel == inTotalBitsPerChannel)) ?
	kAudioFormatFlagIsPacked : kAudioFormatFlagIsAlignedHigh)		   |
	(inIsNonInterleaved ? ((UInt32)kAudioFormatFlagIsNonInterleaved) : 0);
}

void GMBFillOutASBDForLPCM (AudioStreamBasicDescription *outASBD,
							Float64 inSampleRate,
							UInt32 inChannelsPerFrame,
							UInt32 inValidBitsPerChannel,
							UInt32 inTotalBitsPerChannel,
							bool inIsFloat,
							bool inIsBigEndian,
							bool inIsNonInterleaved
							)
{
	outASBD->mSampleRate = inSampleRate;
	outASBD->mFormatID = kAudioFormatLinearPCM;
	outASBD->mFormatFlags =	GMBCalculateLPCMFlags (
													inValidBitsPerChannel,
													inTotalBitsPerChannel,
													inIsFloat,
													inIsBigEndian,
													inIsNonInterleaved
													);
	outASBD->mBytesPerPacket =
	(inIsNonInterleaved ? 1 : inChannelsPerFrame) * (inTotalBitsPerChannel/8);
	outASBD->mFramesPerPacket = 1;
	outASBD->mBytesPerFrame =
	(inIsNonInterleaved ? 1 : inChannelsPerFrame) * (inTotalBitsPerChannel/8);
	outASBD->mChannelsPerFrame = inChannelsPerFrame;
	outASBD->mBitsPerChannel = inValidBitsPerChannel;
}

void GMBInitUserData(GMBAudioQueueUserData* inUserData)
{
//	inUserData->buf = NULL;
//	inUserData->bytePos = 0;
//	inUserData->totalBytesInBuffer = 0;
//	inUserData->numberOfConsumedBlocks = 0;
//	inUserData->isDone = false;
//	memset(&inUserData->streamFormat, 0, sizeof(AudioStreamBasicDescription));
//	inUserData->externalMessage = NULL;
}

void GMBFillOutAudioTimeStampWithSampleTime (
													AudioTimeStamp *outATS,
													Float64 inSampleTime
													) {
	outATS->mSampleTime = inSampleTime;
	outATS->mHostTime = 0;
	outATS->mRateScalar = 0;
	outATS->mWordClockTime = 0;
	memset (&outATS->mSMPTETime, 0, sizeof (SMPTETime));
	outATS->mFlags = kAudioTimeStampSampleTimeValid;
}

