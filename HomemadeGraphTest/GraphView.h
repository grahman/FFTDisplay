//
//  GraphView.h
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/16/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GMBFourierAnalyzer.h"

/* Margins */
const CGFloat marginX = 40;
const CGFloat marginY = 40;

@interface GraphView : NSView
{
	/*
	 * W = graph width in pts
	 * fs = sampling frequency
	 * binw = fft bin width in pts
	 */
	double _W, _H, _fs, _binw;
	unsigned int _N;	/* num samples */
	
	/* Graph data */
	NSLock *_lock;
	float *MAG;
	float *PHA;
	CGPoint _plot[FFT_MAX_N];
}

@property double width;
@property double fs;
@property double binw;
@property unsigned int N;
@property NSLock *lock;

@end