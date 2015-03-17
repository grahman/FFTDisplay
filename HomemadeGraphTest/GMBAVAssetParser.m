 //
//  GMBAVAssetParser.m
//  AVAssets
//
//  Created by Graham Barab on 6/20/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

static void* mediaStatusChangedInternalContext = &mediaStatusChangedInternalContext;

#import "GMBAVAssetParser.h"

@implementation GMBAVAssetParser

@synthesize URLAsset;
@synthesize asset;
@synthesize assetReader;
@synthesize audioAssetReader;
@synthesize audioAssetReaders;
@synthesize assetWriter;
@synthesize player;
@synthesize playerItem;
@synthesize assetReaderOutput;
@synthesize audioTracks;
@synthesize videoTracks;
@synthesize assetReaderAudioTrackOutputs;
@synthesize audioChannelStrips;
@synthesize sampleBuffer;
@synthesize outputSettings;
@synthesize duration;
@synthesize audioFormats;
@synthesize originalAudioStreamBasicDescriptions;
@synthesize playbackAudioStreamBasicDescriptions;
@synthesize playBackSettings;
@synthesize auBufList;
@synthesize assetASBD;
@synthesize assetReaderAudioMixOutputs;
@synthesize audioStreamDataStructs;
@synthesize userDataStructs;
@synthesize mediaIsReady;
@synthesize videoTrackOutput;
@synthesize originalASBD;
@synthesize audioBufferedAndReady = _audioBufferedAndReady;

-(id) initWithFileURL:(NSString*)mediaItemPath_
 {
	_audioBufferedAndReady = NO;
	mediaIsReady = [[NSNumber alloc] initWithInt:0];
	_numAudioAssetReadersReady = 0;
	asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:mediaItemPath_]];
	audioAssetReaders = [[NSMutableArray alloc] init];
	assetReaderAudioTrackOutputs = [[NSMutableArray alloc] init];
	audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
	userDataStructs = calloc(audioTracks.count, sizeof(GMBAudioQueueUserData));

	assetReader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
	playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
	player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
	player.volume = 0;

	int size = sizeof(GMBLeftoverBufferList);
	int tracks = (int)audioTracks.count;
	_leftoverBufferList = malloc(size * tracks);



	int i = 0;
	for (AVAssetTrack* auTrack in audioTracks)
	{
		AVAssetReader* assetReader_ = [[AVAssetReader alloc] initWithAsset:asset error:nil];
		[audioAssetReaders addObject:assetReader_];
		[assetReader_ addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:mediaStatusChangedInternalContext];

		AudioStreamBasicDescription* origASBD;
		AudioStreamBasicDescription destASBD;
		memset(&destASBD, 0, sizeof(AudioStreamBasicDescription));

		origASBD = CMAudioFormatDescriptionGetStreamBasicDescription((__bridge CMAudioFormatDescriptionRef)(auTrack.formatDescriptions.firstObject));
		originalASBD = *origASBD;
		GMBFillOutASBDForLPCM(&destASBD,
							origASBD->mSampleRate,
							origASBD->mChannelsPerFrame,
							32,
							32,
							true,
							false,
							(origASBD->mChannelsPerFrame > 1) ? false : true);

		(userDataStructs + i)->streamFormat = destASBD;
		TPCircularBufferInit(&userDataStructs[i].buf, CIRCULARBUFFERLISTSIZE );		 //This gives us about 15 seconds of mono audio at 48000khz total in the buffer, and is divisible by the average size of an audio buffer list read out of an avassettrackoutput.
		(_leftoverBufferList + i)->buf = malloc((32768 + 16) * 2);
		(_leftoverBufferList + i)->bufSize = 32768 * 2;
		(_leftoverBufferList + i)->bytesUsed = 0;
		(_leftoverBufferList + i)->bytePos = 0;

		AVAssetReaderTrackOutput* track1output = [[AVAssetReaderTrackOutput alloc]
			initWithTrack:auTrack outputSettings:[[NSDictionary alloc]
							initWithObjectsAndKeys:
							[NSNumber numberWithInt:32], AVLinearPCMBitDepthKey,
							[NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
							[NSNumber numberWithBool:YES], AVLinearPCMIsFloatKey,
							[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
							[NSNumber numberWithInteger:origASBD->mSampleRate], AVSampleRateKey,
							[NSNumber numberWithInt:destASBD.mFormatID], AVFormatIDKey ,
							[NSNumber numberWithInteger:origASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
							nil]];
		//Get the asset reader ready to start playing.
		if ([assetReader_ canAddOutput:track1output])
		{
			[assetReader_ addOutput:track1output];
		}

		[assetReaderAudioTrackOutputs addObject:track1output];
		[assetReader_ startReading];

		//Set up our data structures
		duration = asset.duration;

		bool done = false;
		int c = 0;
		int bufWritePos = 0;
		while(!done)
		{
			int availableBytes = 0;
			void* head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);

			//First we check to see if there is a leftover buffer list from the previous run.
			if (_leftoverBufferList[i].bytesUsed)
			{
				//Finish copying the leftover buffer list.
				availableBytes = _leftoverBufferList[i].bufSize - _leftoverBufferList[i].bytePos;
				memcpy(head, _leftoverBufferList + _leftoverBufferList[i].bytePos, availableBytes);
				TPCircularBufferProduce(&userDataStructs[i].buf, availableBytes);
				freeLeftOverBuffer(&_leftoverBufferList[i]);

			}
			else									//If there is no leftover buffer list, control flow goes here.
			{
				CMSampleBufferRef bufferRef;
				AudioBufferList bufferList;
				CMBlockBufferRef blockBufferRef;
				unsigned long bufSizeInFrames  = BufferSize;
				bufferRef = [track1output copyNextSampleBuffer];

				if (bufferRef)
				{

					CheckError(CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(bufferRef,  &bufSizeInFrames, &bufferList, sizeof(AudioBufferList), kCFAllocatorDefault, kCFAllocatorDefault, 0, &blockBufferRef), "Getting Audio Buffer List from avassettrackoutput");

					//				memcpy(&(userDataStructs + i)->buf[bufWritePos], bufferList.mBuffers->mData, bufferList.mBuffers->mDataByteSize);
					bufWritePos += bufferList.mBuffers->mDataByteSize;
					if (availableBytes >= bufferList.mBuffers[0].mDataByteSize)
					{
						//If the number of bytes available in the circular buffer is greater than the size of the incoming buffer list, copy the whole thing.
						memcpy(head, bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize);
						TPCircularBufferProduce(&userDataStructs[i].buf, bufferList.mBuffers[0].mDataByteSize);
						head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
						CMSampleBufferInvalidate(bufferRef);
						CFRelease(blockBufferRef);
						CFRelease(bufferRef);
						bufferRef = NULL;
					}
					else
					{
						//If the number of bytes available in the circular buffer is less than the size of the incoming buffer, copy what we can and store the incompletely copied buffer list in a member variable.
						int bytesToWrite = /*bufferList.mBuffers[0].mDataByteSize -*/ availableBytes;
						memcpy(head, bufferList.mBuffers[0].mData, bytesToWrite);
						TPCircularBufferProduce(&userDataStructs[i].buf, bytesToWrite);
						int leftoverBytes = bufferList.mBuffers[0].mDataByteSize - availableBytes;
						int totalBufferListBytes = bufferList.mBuffers[0].mDataByteSize;
						memcpy(_leftoverBufferList[i].buf, bufferList.mBuffers[0].mData,  totalBufferListBytes);
						_leftoverBufferList[i].bytesUsed = bufferList.mBuffers[0].mDataByteSize;
						_leftoverBufferList[i].bytePos = totalBufferListBytes - leftoverBytes;
						head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
						CMSampleBufferInvalidate(bufferRef);
						CFRelease(blockBufferRef);
						CFRelease(bufferRef);
						bufferRef = NULL;
					}
					if (bufWritePos >= CIRCULARBUFFERLISTSIZE)
					{
						done = true;
						break;
					}
				} else
				{
					done = true;
					break;
				}
			}
			++c;
		}
		++i;
	}
	if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0)
	{
		videoTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject outputSettings:nil];
	}





	//****************************End For Looop******************************************/
//	[self setValue:[NSNumber numberWithBool:YES] forKey:NSStringFromSelector(@selector(mediaIsReady))] ;
	NSLog(@"AVAsset with URL \"%@\" has been parsed!", mediaItemPath_);
	NSLog(@"GMBAVAssetParser has finished initializing, address %p", &self);
	return self;
}

-(void)fillCircularBuffer
{
	//Set up our data structures
	duration = asset.duration;
	_audioBufferedAndReady = NO;

	for (int i=0; i < audioTracks.count; ++i)
	{
		bool done = false;
		int c = 0;
		int bufWritePos = 0;
		AVAssetReaderTrackOutput* track1output = [assetReaderAudioTrackOutputs objectAtIndex:i];
		while(!done)
		{
			int availableBytes = 0;
			void* head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
			if (!head)
			{
				return;
			}

			//First we check to see if there is a leftover buffer list from the previous run.
			if (_leftoverBufferList[i].bytesUsed)
			{
				//Finish copying the leftover buffer list.
				availableBytes = _leftoverBufferList[i].bufSize - _leftoverBufferList[i].bytePos;
				memcpy(head, _leftoverBufferList + _leftoverBufferList[i].bytePos, availableBytes);
				TPCircularBufferProduce(&userDataStructs[i].buf, availableBytes);
				freeLeftOverBuffer(&_leftoverBufferList[i]);

			}
			else									//If there is no leftover buffer list, control flow goes here.
			{
				CMSampleBufferRef bufferRef;
				AudioBufferList bufferList;
				CMBlockBufferRef blockBufferRef;
				unsigned long bufSizeInFrames  = BufferSize;
				bufferRef = [track1output copyNextSampleBuffer];

				if (bufferRef)
				{

					CheckError(CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(bufferRef,  &bufSizeInFrames, &bufferList, sizeof(AudioBufferList), kCFAllocatorDefault, kCFAllocatorDefault, 0, &blockBufferRef), "Getting Audio Buffer List from avassettrackoutput");

					//				memcpy(&(userDataStructs + i)->buf[bufWritePos], bufferList.mBuffers->mData, bufferList.mBuffers->mDataByteSize);
					bufWritePos += bufferList.mBuffers->mDataByteSize;
					if (availableBytes >= bufferList.mBuffers[0].mDataByteSize)
					{
						//If the number of bytes available in the circular buffer is greater than the size of the incoming buffer list, copy the whole thing.
						memcpy(head, bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize);
						TPCircularBufferProduce(&userDataStructs[i].buf, bufferList.mBuffers[0].mDataByteSize);
						head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
						CMSampleBufferInvalidate(bufferRef);
						CFRelease(blockBufferRef);
						CFRelease(bufferRef);
						bufferRef = NULL;
					}
					else
					{
						//If the number of bytes available in the circular buffer is less than the size of the incoming buffer, copy what we can and store the incompletely copied buffer list in a member variable.
						int bytesToWrite = /*bufferList.mBuffers[0].mDataByteSize -*/ availableBytes;
						memcpy(head, bufferList.mBuffers[0].mData, bytesToWrite);
						TPCircularBufferProduce(&userDataStructs[i].buf, bytesToWrite);
						int leftoverBytes = bufferList.mBuffers[0].mDataByteSize - availableBytes;
						int totalBufferListBytes = bufferList.mBuffers[0].mDataByteSize;
						memcpy(_leftoverBufferList[i].buf, bufferList.mBuffers[0].mData,  totalBufferListBytes);
						_leftoverBufferList[i].bytesUsed = bufferList.mBuffers[0].mDataByteSize;
						_leftoverBufferList[i].bytePos = totalBufferListBytes - leftoverBytes;
						head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
						CMSampleBufferInvalidate(bufferRef);
						CFRelease(blockBufferRef);
						CFRelease(bufferRef);
						bufferRef = NULL;
					}
					if (bufWritePos >= CIRCULARBUFFERLISTSIZE)
					{
						done = true;
						break;
					}
				} else
				{
					done = true;
					break;
				}
			}
			++c;
		}
	}
	_audioBufferedAndReady = YES;
}

-(void)copyNextBuffers
{
	int i = 0;
	if (!_audioBufferedAndReady)
	{
		return;
	}
	for (AVAssetTrack* auTrack in audioTracks)
	{

		AudioStreamBasicDescription* origASBD;
		AudioStreamBasicDescription destASBD;
		memset(&destASBD, 0, sizeof(AudioStreamBasicDescription));

		origASBD = CMAudioFormatDescriptionGetStreamBasicDescription((__bridge CMAudioFormatDescriptionRef)(auTrack.formatDescriptions.firstObject));
		originalASBD = *origASBD;
		GMBFillOutASBDForLPCM(&destASBD,
							origASBD->mSampleRate,
							origASBD->mChannelsPerFrame,
							32,
							32,
							true,
							false,
							(origASBD->mChannelsPerFrame > 1) ? false : true);



		AVAssetReaderTrackOutput* track1output = [assetReaderAudioTrackOutputs objectAtIndex:i];


		//Set up our data structures
		duration = asset.duration;
		(userDataStructs + i)->streamFormat = destASBD;

		bool done = false;
		int c = 0;
		int bufWritePos = 0;

		int availableBytes = 0;
		int bytesToWrite = 0;
		void* head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
		int originalAvailableBytes = availableBytes;

		while(availableBytes && !done)
		{


			//First we check to see if there is a leftover buffer list from the previous run.
			if (_leftoverBufferList[i].bytesUsed)
			{
				//Finish copying the leftover buffer list.
				if (availableBytes > (_leftoverBufferList[i].bytesUsed - _leftoverBufferList[i].bytePos))
				{
					bytesToWrite = _leftoverBufferList[i].bytesUsed - _leftoverBufferList[i].bytePos;
				}
				else
				{
					bytesToWrite = availableBytes;
				}

				memcpy(head, _leftoverBufferList[i].buf + _leftoverBufferList[i].bytePos, bytesToWrite);
				_leftoverBufferList[i].bytesUsed -= bytesToWrite;
				TPCircularBufferProduce(&userDataStructs[i].buf, bytesToWrite);
				head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
				if (!_leftoverBufferList[i].bytesUsed)
					freeLeftOverBuffer(&_leftoverBufferList[i]);

			}
												//If there is no leftover buffer list, control flow goes here.
			{
				if (!_audioBufferedAndReady)
				{
					return;
				}
				CMSampleBufferRef bufferRef;
				AudioBufferList bufferList;
				CMBlockBufferRef blockBufferRef;
				unsigned long bufSizeInFrames  = BufferSize;
				bufferRef = [track1output copyNextSampleBuffer];

				if (bufferRef)
				{

					CheckError(CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(bufferRef,  &bufSizeInFrames, &bufferList, sizeof(AudioBufferList), kCFAllocatorDefault, kCFAllocatorDefault, 0, &blockBufferRef), "Getting Audio Buffer List from avassettrackoutput");

					bufWritePos += bufferList.mBuffers->mDataByteSize;
					head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);

					if (availableBytes >= bufferList.mBuffers[0].mDataByteSize)
					{
						//If the number of bytes available in the circular buffer is greater than the size of the incoming buffer list, copy the whole thing.
						memcpy(head, bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize);
						TPCircularBufferProduce(&userDataStructs[i].buf, bufferList.mBuffers[0].mDataByteSize);
						head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
						CMSampleBufferInvalidate(bufferRef);
						CFRelease(blockBufferRef);
						CFRelease(bufferRef);
						bufferRef = NULL;
					}
					else
					{
						//If the number of bytes available in the circular buffer is less than the size of the incoming buffer, copy what we can and store the incompletely copied buffer list in a member variable.
						if (head)
						{
							bytesToWrite = /*bufferList.mBuffers[0].mDataByteSize - */availableBytes;
							memcpy(head, bufferList.mBuffers[0].mData, bytesToWrite);
							TPCircularBufferProduce(&userDataStructs[i].buf, bytesToWrite);
							done = true;
						}
						else bytesToWrite = 0;

						int totalBufferListBytes = bufferList.mBuffers[0].mDataByteSize;

						//Now fill the leftover buffer list
						memcpy(_leftoverBufferList[i].buf, bufferList.mBuffers[0].mData,  totalBufferListBytes);
						_leftoverBufferList[i].bytesUsed = bufferList.mBuffers[0].mDataByteSize;
						_leftoverBufferList[i].bytePos = availableBytes;
						head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
						CMSampleBufferInvalidate(bufferRef);
						CFRelease(blockBufferRef);
						CFRelease(bufferRef);
						bufferRef = NULL;
					}
					if (bufWritePos >= originalAvailableBytes)
					{
						done = true;
						break;
					}
				} else
				{
					done = true;
					break;
				}
			}
			++c;
			availableBytes = 0;
			bytesToWrite = 0;
			head = TPCircularBufferHead(&userDataStructs[i].buf, &availableBytes);
		}
		++i;
		//		assetReader_ = nil;
	}

}

-(void)seekToTime:(CMTime)time
{
	//Make sure player is paused before doing this!
	if (!_audioBufferedAndReady)
	{
		return;
	}

	[self recreateAudioAssetReaders];
	CMTimeRange newTimeRange = CMTimeRangeMake(time, asset.duration);
	int i=0;
//	while (![[self mediaIsReady] boolValue]);
	for (AVAssetReader* reader in audioAssetReaders)
	{
//		[reader addOutput:[assetReaderAudioTrackOutputs objectAtIndex:i]];
		++i;
		reader.timeRange = newTimeRange;
		[self clearCircularBuffers];
		if([reader startReading])
			NSLog(@"GMBAVAssetParser: [reader startReading] was successful");
	}
//	[audioAssetReader startReading];
	[self fillCircularBuffer];

}

-(void)recreateAudioAssetReaders
{
	//Deallocate all the old stuff.
	for (int i=0; i < audioTracks.count; ++i)
	{
		freeLeftOverBuffer(&_leftoverBufferList[i]);
	}
	for (AVAssetReader* auReader in audioAssetReaders)
	{
		[auReader removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
	}

//	[assetReader removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
	_numAudioAssetReadersReady = 0;
	[self setValue:[NSNumber numberWithBool:NO] forKey:NSStringFromSelector(@selector(mediaIsReady))];
	_numAudioAssetReadersReady = 0; 
	assetReaderAudioTrackOutputs = nil;
	audioAssetReaders = nil;

	//Reallocate the new stuff.
	audioAssetReaders = [[NSMutableArray alloc] init];
	assetReaderAudioTrackOutputs = [[NSMutableArray alloc] init];

	NSError* err;
	audioAssetReader = [[AVAssetReader alloc] initWithAsset:asset error:&err];
	//Set up kvo to know when the status is ready. Will need to report back to AppDelegate.
//	[audioAssetReader addObserver:self
//					   forKeyPath:NSStringFromSelector(@selector(status))
//						  options:NSKeyValueObservingOptionNew
//						  context:mediaStatusChangedInternalContext];

	int i = 0;
	for (AVAssetTrack* auTrack in audioTracks)
	{
		TPCircularBufferClear(&userDataStructs[i].buf);
		[self clearCircularBuffers];

		AVAssetReader* assetReader_ = [[AVAssetReader alloc] initWithAsset:asset error:nil];
		[audioAssetReaders addObject:assetReader_];
		[assetReader_ addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:mediaStatusChangedInternalContext];




		AudioStreamBasicDescription* origASBD;
		AudioStreamBasicDescription destASBD;
		memset(&destASBD, 0, sizeof(AudioStreamBasicDescription));

		origASBD = CMAudioFormatDescriptionGetStreamBasicDescription((__bridge CMAudioFormatDescriptionRef)(auTrack.formatDescriptions.firstObject));
		originalASBD = *origASBD;
		GMBFillOutASBDForLPCM(&destASBD,
							origASBD->mSampleRate,
							origASBD->mChannelsPerFrame,
							32,
							32,
							true,
							false,
							(origASBD->mChannelsPerFrame > 1) ? false : true);
		//			myUserData.streamFormat = destASBD;

		AVAssetReaderTrackOutput* track1output = [[AVAssetReaderTrackOutput alloc]
					initWithTrack:auTrack outputSettings:[[NSDictionary alloc]
							initWithObjectsAndKeys:
							[NSNumber numberWithInt:32], AVLinearPCMBitDepthKey,
							[NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
							[NSNumber numberWithBool:YES], AVLinearPCMIsFloatKey,
							[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
							[NSNumber numberWithInteger:origASBD->mSampleRate], AVSampleRateKey,
							[NSNumber numberWithInt:destASBD.mFormatID], AVFormatIDKey ,
							[NSNumber numberWithInteger:origASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
							nil]];
//Get the asset reader ready to start playing.
		if ([assetReader_ canAddOutput:track1output])
		{
			[assetReader_ addOutput:track1output];
		}

		[assetReaderAudioTrackOutputs addObject:track1output];

	}

//	[self setValue:[NSNumber numberWithBool:YES] forKey:NSStringFromSelector(@selector(mediaIsReady))];
}

//This does not deallocate the user data structs
-(void)clearCircularBuffers
{
	for (int i=0; i < audioTracks.count; ++i)
	{
		_leftoverBufferList[i].bytesUsed = 0;
		_leftoverBufferList[i].bytePos = 0;
		int availableBytes = 0;
		TPCircularBufferConsume(&userDataStructs[i].buf, availableBytes);
	}
}

-(void) startReading
{

}

-(void) connectGraph
{

}

-(void) freeUserDataStructs
{
//	if (userDataStructs != NULL)
//	{
//		for (int i=0; i < audioTracks.count; ++i)
//		{
//			free(userDataStructs[i].buf);
//		}
//		free(userDataStructs);
//		NSLog(@"userDataStructs have been freed\n");
//	}
}

+(NSDictionary*)convertASBDToNSDictionary:(AudioStreamBasicDescription)asbd_
{
	BOOL isFloat = (asbd_.mFormatFlags & kAudioFormatFlagIsFloat) ? YES : NO;
	BOOL isNonInterleaved = (asbd_.mFormatFlags & kAudioFormatFlagIsNonInterleaved) ? YES : NO;
	BOOL isBigEndian = (asbd_.mFormatFlags & kAudioFormatFlagIsBigEndian);
	NSDictionary* dict = [[NSDictionary alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
						[NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
						[NSNumber numberWithFloat:asbd_.mSampleRate], AVSampleRateKey,
						[NSNumber numberWithInt:asbd_.mChannelsPerFrame], AVNumberOfChannelsKey,
						[NSNumber numberWithInt:asbd_.mBitsPerChannel], AVLinearPCMBitDepthKey,
						[NSNumber numberWithBool:isNonInterleaved], AVLinearPCMIsNonInterleaved,
						[NSNumber numberWithBool:isFloat], AVLinearPCMIsFloatKey,
						[NSNumber numberWithBool:isBigEndian], AVLinearPCMIsBigEndianKey, nil]copyItems:NO];
	return dict;

}

-(void)dealloc
{
	[self freeUserDataStructs];
	for (int i=0; i < audioTracks.count; ++i)
	{
		free(_leftoverBufferList[i].buf);
		TPCircularBufferCleanup(&userDataStructs[i].buf);
	}
	asset = nil;
	audioTracks = nil;
	userDataStructs = NULL;
	mediaIsReady = nil;
	assetReaderAudioTrackOutputs = nil;
//	NSLog(@"AVAssetParser and asoociated userDataStructs have been freed");

	NSLog(@"GMBAVAssetParser::dealloc: deallocated");

}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == mediaStatusChangedInternalContext)
	{
		if (_numAudioAssetReadersReady < audioTracks.count)
		{
			++_numAudioAssetReadersReady;
			if (_numAudioAssetReadersReady == audioTracks.count)
			{
				[self setValue:[NSNumber numberWithBool:YES] forKey:NSStringFromSelector(@selector(mediaIsReady))];
				_audioBufferedAndReady = YES;
			}
		}
	}
}

@end

void freeLeftOverBuffer(GMBLeftoverBufferList* inLeftoverBuffer)
{
	memset(inLeftoverBuffer->buf, 0, inLeftoverBuffer->bufSize);
	inLeftoverBuffer->bytePos = 0;
	inLeftoverBuffer->bytesUsed = 0;
}


