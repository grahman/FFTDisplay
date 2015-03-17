 //
//  MixerWindow.m
//  AVAssets2
//
//  Created by Graham Barab on 7/9/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "MixerWindow.h"

@interface MixerWindow ()

@end

@implementation MixerWindow
//@synthesize playing;
@synthesize normalizeChecked;
@synthesize optKeyPressed;

- (id)init
{
	self=[super initWithWindowNibName:@"MixerWindow"];
	_playing = NO;
	normalizeChecked = true;
	if(self)
	{
		//perform any initializations
	}
	return self;
}

-(void)setPlaying:(BOOL)playing_
{
	_playing = playing_;
	[self didChangeValueForKey:NSStringFromSelector(@selector(playing))];
}

-(BOOL)playing
{
	return _playing;
}


-(void)insertObject:(GMBChannelStrip *)object inChannelStripArrayAtIndex:(NSUInteger)index
{
	[channelStripArray insertObject:object atIndex:index];
}

- (IBAction)NormalizeCheckboxClicked:(id)sender
{
	normalizeChecked = !normalizeChecked;
}

-(void)removeObjectFromChannelStripArrayAtIndex:(NSUInteger)index
{
	if (channelStripArray.count > index)
		[channelStripArray removeObjectAtIndex:index];
}

-(void)setChannelStripArray:(NSMutableArray *)channelStripArray_
{
	channelStripArray = channelStripArray_;
}

- (IBAction)PlayPauseButtonClicked:(id)sender
{
	[self setValue:[NSNumber numberWithBool:YES] forKey:NSStringFromSelector(@selector(playing))];
}

- (IBAction)ResetButtonClicked:(id)sender
{
	[self setValue:[NSNumber numberWithBool:YES] forKey:NSStringFromSelector(@selector(reset))];
}

- (IBAction)GainSliderClicked:(id)sender
{
//	if (optKeyPressed)
//	{
//
//	}
}

-(void) setReset:(BOOL)reset_
{
	_reset = reset_;
	[self didChangeValueForKey:NSStringFromSelector(@selector(reset))];
}

-(BOOL) reset
{
	return _reset;
}
-(NSMutableArray*)channelStripArray
{
	return channelStripArray;
}

- (IBAction)PreservePanningButtonClicked:(id)sender
{
	[self monoToStereoPreservePanning];
}

- (IBAction)OriginalButtonClicked:(id)sender
{
	[self setToOriginal];
}

-(void)monoToStereoPreservePanning
{
	int numTracks = (int)channelStripArray.count;
	int numChannels = 0;
	int numChannelsFirst = 0;

	//First, find out if we are dealing with a homogenous group of mono or stereo tracks
	for (int i=0; i < numTracks; ++i)
	{
		GMBChannelStrip* chstrip = [channelStripArray objectAtIndex:i];
		if (i == 0)
			numChannelsFirst = chstrip.monoOrStereo + 1;
		numChannels = chstrip.monoOrStereo + 1;
		if (numChannels != numChannelsFirst)
		{
			NSAssert(numChannels != numChannelsFirst, @"Audio tracks are not homogenous");
		}

	}
	bool mono = (numChannelsFirst == 1) ? true : false;
	for (int i=0; i < numTracks; ++i)
	{
			GMBChannelStrip* chstrip = [channelStripArray objectAtIndex:i];
			if (mono)
			{
				chstrip.monoOrStereo = 1;		   //Convert to stereo
				if (i + 1 <= numTracks / 2)	 //Pan all of these left
					chstrip.pan = -1.0;				 //Pan hard left
				else
					chstrip.pan = 1.0;

				//Here we are boosting the gain of each output bus by 6.02db (2x as loud) for gain makeup.
//				CheckError(AudioUnitSetParameter(chstrip.outputBus->limiter, kLimiterParam_PreGain, kAudioUnitScope_Global, 0, 6.02,  0), "Error setting limiter pregain");
			}
	}

}

-(void)setToOriginal
{
	int numTracks = (int)channelStripArray.count;

	//First, find out if we are dealing with a homogenous group of mono or stereo tracks
	for (int i=0; i < numTracks; ++i)
	{
		GMBChannelStrip* chstrip = [channelStripArray objectAtIndex:i];
		chstrip.monoOrStereo = chstrip.userDataStruct->streamFormat.mChannelsPerFrame - 1;
		chstrip.gainLogControlValue = 0;
		chstrip.pan = 0.0;
		CheckError(AudioUnitSetParameter(chstrip.outputBus->limiter, kLimiterParam_PreGain, kAudioUnitScope_Global, 0, 0,  0), "Error setting limiter pregain");
	}
}

-(void)keyDown:(NSEvent *)theEvent
{
	NSUInteger modkeys = [theEvent modifierFlags];
	if (modkeys & NSAlternateKeyMask)
	{
		optKeyPressed = YES;
	}
}

-(void)keyUp:(NSEvent *)theEvent
{
	NSUInteger modkeys = [theEvent modifierFlags];
	if (modkeys & NSAlternateKeyMask)
	{
		optKeyPressed = NO;
	}
}

-(void)mouseDown:(NSEvent *)theEvent
{
	NSUInteger modkeys = [theEvent modifierFlags];
	if (modkeys & NSAlternateKeyMask)
	{
		optKeyPressed = YES;
	}
}

-(void)mouseUp:(NSEvent *)theEvent
{
	NSUInteger modkeys = [theEvent modifierFlags];
	if (modkeys & NSAlternateKeyMask)
	{
		optKeyPressed = NO;
	}
}

-(void)dealloc
{
	channelStripArray = nil;
}

@end

