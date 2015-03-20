//
//  GraphView.h
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/16/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GMBFourierAnalyzer.h"


#ifndef marginX
#define marginX 60
#endif

#ifndef marginY
#define marginY 60
#endif


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
	CGFloat _special[10];	/* Stores points for 20Hz, 50Hz, 100Hz,..20kHz */
	CGFloat spoints[10];	/* _special after log transform */
	NSArray *labels;
	NSTextView *tlabels[10];
	NSTextView *dblabels[5];
	NSArray *dbs;
	CGFloat dbpoints[5];
}

@property double width;
@property double fs;
@property double binw;
@property unsigned int N;
@property NSLock *lock;

@end