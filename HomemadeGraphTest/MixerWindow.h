//
//  MixerWindow.h
//  AVAssets2
//
//  Created by Graham Barab on 7/9/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GMBChannelStrip.h"

@interface MixerWindow : NSWindowController
{
	NSMutableArray*		 channelStripArray;
	BOOL					_playing;
	BOOL					_reset;
}

@property (retain) NSMutableArray*   channelStripArray;
@property BOOL					   playing;
@property BOOL					   reset;
@property BOOL					   normalizeChecked;
@property BOOL					   optKeyPressed;
@property (weak) IBOutlet NSCollectionView *collectionView;
- (IBAction)PreservePanningButtonClicked:(id)sender;
- (IBAction)OriginalButtonClicked:(id)sender;

-(void)insertObject:(GMBChannelStrip *)object inChannelStripArrayAtIndex:(NSUInteger)index;
- (IBAction)NormalizeCheckboxClicked:(id)sender;

-(void)removeObjectFromChannelStripArrayAtIndex:(NSUInteger)index;

-(void)setChannelStripArray:(NSMutableArray *)channelStripArray_;
- (IBAction)PlayPauseButtonClicked:(id)sender;
- (IBAction)ResetButtonClicked:(id)sender;
- (IBAction)GainSliderClicked:(id)sender;

-(NSMutableArray*)channelStripArray;

//***************Quick Fixes************************/
-(void)monoToStereoPreservePanning;
-(void)setToOriginal;

@end


