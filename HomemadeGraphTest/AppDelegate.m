//
//  AppDelegate.m
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/16/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate
@synthesize assetParser;
@synthesize mixer;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

- (IBAction)openMenuClicked:(id)sender
{
	/**
	 The following code snippet was obtained from http://stackoverflow.com/questions/1640419/open-file-dialog-box
	 **/
	
	NSString *openFileName = nil;
	
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
		
		if (assetParser.asset)
		{
			[assetParser.assetReader removeObserver:self forKeyPath:@"status"];
			assetParser = [[GMBAVAssetParser alloc] initWithFileURL:openFileName];
		}
		else
		{
			assetParser = [[GMBAVAssetParser alloc] initWithFileURL:openFileName];
		}
		openDlg = nil;
		[self applicationDidFinishLaunching:nil];
	}
}

- (IBAction)PlayAudioButtonClicked:(id)sender {
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
		
	}
	
}


@end
