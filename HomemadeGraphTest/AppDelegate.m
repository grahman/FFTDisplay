//
//  AppDelegate.m
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/16/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import "AppDelegate.h"

static void* mixerPlayPauseContext = &mixerPlayPauseContext;
static void* mixerResetButtonContext = &mixerResetButtonContext;
static void* movieWindowSpacebarPressedContext = &movieWindowSpacebarPressedContext;
static void* normalizeCheckboxChangedContext = &normalizeCheckboxChangedContext;
static void* transportHUDSeekPosChangedContext = &transportHUDSeekPosChangedContext;
static void* transportHUDSeekPosChangedMouseUpContext = &transportHUDSeekPosChangedMouseUpContext;
static void* transportHUDSeekPosChangedMouseDownContext = &transportHUDSeekPosChangedMouseDownContext;


@implementation AppDelegate

@synthesize assetParser;
@synthesize mixer;
@synthesize asbd;
@synthesize dspASBD;
@synthesize streamDscrptn;
@synthesize del;
@synthesize stopPlayingDelegate;
@synthesize needsNewBufferDelegate;
@synthesize exporter;
@synthesize openFileName;
@synthesize playing;
@synthesize initialized;
@synthesize upperLeftCornerOfScreen;
@synthesize movieWindowCreated;
@synthesize fourierAnalyzer;
@synthesize graphView;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	_seekPosMouseUp = YES;
	initialized = NO;
	_wasPlayingBeforeChangingSeek = NO;
	//Deal with window positioning
	
	/*********DEBUG AREA*****************/
	
	NSLog(@"\n-----------\n%p:\tMediaStatusContext\n%p:\tneedsNewBufferContext\n%p:\tmediaIsReadyContext\n%p:\tmixerNodeChangedContext\n%p:\tmixerPlayPauseContext\n%p:\tmixerResetButtonContext\n%p:\tmovieWindowSpacebarPressedContext\n%p:\tnormalizeCheckboxChangedContext\n%p:\tassetReaderDeallocContext\n--------------------", mediaStatusContext, needsNewBufferContext, mediaIsReadyContext, mixerNodeChangedContext);
	
	/********END DEBUG AREA**************/
	
	NSScreen* primaryDisplay = [NSScreen mainScreen];
	NSRect visibleFrame = primaryDisplay.visibleFrame;
	NSRect originRect = {0};
	originRect.origin.x = 0;
	originRect.origin.y = visibleFrame.size.height;
	originRect.size = [[self window] frame].size;
	
	
	[[self window] cascadeTopLeftFromPoint:originRect.origin];
	[[self window] setFrame:originRect display:YES];
	if (!mixer)
	{
		mixer = [[GMBMixer alloc] init];
	}

	[self resetBackgroundQueues];
	
	_mediaReady = NO;
	__weak typeof(self) weakSelf = self;
	weakSelf.del.callback = ^
	{
		_mediaReady = YES;
	};
	playing = NO;
	[[self window] setDefaultButtonCell:nil];
	
	initialized = YES;
	fourierAnalyzer = [[GMBFourierAnalyzer alloc] initWithBins:2048];
	
	/* Reload the view to initialize properly */
	graphView = [[GraphView alloc] initWithFrame:self.window.frame];
	[self.window setContentView:graphView];
}

- (IBAction)openMenuClicked:(id)sender
{
	/**
	 The following code snippet was obtained from http://stackoverflow.com/questions/1640419/open-file-dialog-box
	 **/
	
	// Create the File Open Dialog class.
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
	
	// Enable the selection of files in the dialog.
	[openDlg setCanChooseFiles:YES];
	
	// Multiple files not allowed
	[openDlg setAllowsMultipleSelection:NO];
	
	// Can't select a directory
	[openDlg setCanChooseDirectories:NO];
	
	// Display the dialog. If the OK button was pressed,
	// process the files.
	if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
	{
		//Now that user has chosen a new file, stop current playback if necessary and dealloc the old userDataStructs and graph
				
		// Get an array containing the full filenames of all
		// files and directories selected.
		NSArray* files = [openDlg filenames];
		openFileName = [files firstObject];
		
		if (assetParser && assetParser.asset)
		{
			if (playing)
				[self stopAudioQuietly];
			/* I think the the old user data structs may still be getting called by the mixer,
			 * so make a brand new mixer to play it safe for now. If this fixes issue, maybe
			 * look into more efficient solution (like unregister old callbacks before
			 * deallocating them */
			mixer = [[GMBMixer alloc] init];
			[fourierAnalyzer reset];
			[assetParser removeObserver:self forKeyPath:NSStringFromSelector(@selector(mediaIsReady))];
			assetParser = [[GMBAVAssetParser alloc] initWithFileURL:openFileName];
			[assetParser addObserver:self
				forKeyPath:NSStringFromSelector(@selector(mediaIsReady))
				options:NSKeyValueObservingOptionNew
				context:mediaIsReadyContext];

		}
		else
		{
			if (assetParser) {
				[assetParser removeObserver:self forKeyPath:NSStringFromSelector(@selector(mediaIsReady))];
			}
			assetParser = [[GMBAVAssetParser alloc] initWithFileURL:openFileName];
			[assetParser addObserver:self
				forKeyPath:NSStringFromSelector(@selector(mediaIsReady))
				options:NSKeyValueObservingOptionNew
				context:mediaIsReadyContext];
		}
		
		if (assetParser.mediaIsReady) {
			lpf.Fs = assetParser.originalASBD.mSampleRate;
			[self setupMixer];
			[self PlayAudioButtonClicked:nil];
		}
		
		openDlg = nil;
	}
}

-(void) resetBackgroundQueues
{
	backgroundQueue = dispatch_queue_create("backgroundQueue", DISPATCH_QUEUE_CONCURRENT);
	backgroundQueueSerial = dispatch_queue_create("backgroundQueueSerial", DISPATCH_QUEUE_SERIAL);
}
- (IBAction)PlayAudioButtonClicked:(id)sender {
	if (playing)
		return;
	_wasPlayingBeforeChangingSeek = YES;
	dispatch_async(backgroundQueue, ^{
		while (!assetParser.audioBufferedAndReady);
		BOOL success = YES;
		if (success)
		{
			[mixer startGraph];
		}
	});
	playing = YES;
	if (assetParser)
	{
		//Without bgtimer...
		dispatch_async(backgroundQueueSerial, ^
			       {
				       do
				       {
					       [assetParser copyNextBuffers];
					       sleep(1);
				       } while (playing);
				       NSLog(@"AppDelegate: Exiting copyNextBuffersLoop");
			       });
		dispatch_async(backgroundQueue, ^
			       {
				       do
				       {
					       [fourierAnalyzer process];
					       [self.window.contentView setNeedsDisplay:YES];
					       usleep(80000);
				       } while (playing);
				       NSLog(@"AppDelegate: Exiting graph redraw loop");
			       });
	}
}

- (void)setupMixer
{
	mixer.userDataStructs = assetParser.userDataStructs;
	mixer.nSourceTracks = [[NSNumber alloc] initWithInt:(int)assetParser.audioTracks.count];
	mixer.graph = [mixer.graph initGraphWithUserDataStruct:assetParser.userDataStructs numberOfStructs:[NSNumber numberWithInteger:assetParser.audioTracks.count]];
	
	[mixer registerCallbacks];
	
//	if (_wasPlayingBeforeChangingSeek && _seekPosMouseUp)
//		[self PlayAudioButtonClicked:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	
	if (context == &mediaStatusContext) {
		NSLog(@"Calling media status observer\n");
		NSLog(@"AssetReader status is %@\n", [change valueForKey:NSKeyValueChangeNewKey]);
	}
	if (context == &needsNewBufferContext)
	{
		
	}
#pragma mark MEDIA_READY
	if (context == &mediaIsReadyContext)
	{
		if ([change valueForKey:NSKeyValueChangeNewKey] == [NSNumber numberWithBool:YES])
		{
			if ([assetParser.mediaIsReady intValue] == [[NSNumber numberWithBool:YES]intValue])
			{
//				[self setupMixer];
//				[self PlayAudioButtonClicked:nil];
			}
			
		}
	}
	if (context == transportHUDSeekPosChangedMouseUpContext)
	{
		_seekPosMouseUp = YES;
		_seekPosMouseDown = NO;
		if (_wasPlayingBeforeChangingSeek && !playing)
			if (assetParser.mediaIsReady)
				[self PlayAudioButtonClicked:nil];
		
	}
	if (context == transportHUDSeekPosChangedMouseDownContext)
	{
		_seekPosMouseDown = YES;
		_seekPosMouseUp = NO;
		if (playing)
		{
			_wasPlayingBeforeChangingSeek = YES;
			[self stopAudioQuietly];
		}
	}
#pragma mark TRANSPORT_HUD_CHANGED
	if (context == transportHUDSeekPosChangedContext)
	{
		if (playing)
			[self stopAudioQuietly];
		
		double seekToTime = 0;
		CMTime seekToTimeAsCMTime = CMTimeMake(seekToTime * assetParser.duration.timescale, assetParser.duration.timescale);
		
		
		//Now do the same for the audio.
		[assetParser seekToTime:seekToTimeAsCMTime];
	}
}

-(IBAction)stopAudio:(id)sender
{
	[self stopAudioQuietly];
}

-(void) stopAudioQuietly
{
	[mixer stopGraph];
	playing = NO;
}
@end
