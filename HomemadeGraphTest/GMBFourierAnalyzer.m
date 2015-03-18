//
//  GMBFourierAnalyzer.m
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/17/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import "GMBFourierAnalyzer.h"


@implementation GMBFourierAnalyzer
//@synthesize numChannels;

-(id) initWithBins: (unsigned int)N
{
	self = [super init];
	if (self) {
		fftd.N = N;
		fftd.pos = 0;
		_numChannels = 1;
	}
	return self;
}

-(void) process
{
	int ready;
	
	ready = (fftd.pos == fftd.N) ? 1 : 0;
	switch(ready) {
		case 1:
			mag_phase_response(fftd.REX1,
					   fftd.IMX1,
					   fftd.MAG1,
					   fftd.PHA1,
					   fftd.N);
			memset(fftd.REX1, 0, fftd.N * sizeof(float));
			memset(fftd.REX2, 0, fftd.N * sizeof(float));
			memset(fftd.IMX1, 0, fftd.N * sizeof(float));
			memset(fftd.IMX2, 0, fftd.N * sizeof(float));
			fftd.pos = 0;
			break;
		case 0:
			break;
	}
}

-(void) setNumChannels:(int)numChannels
{
	if (numChannels < 1)
		_numChannels = 1;
	else
		_numChannels = numChannels;
}

-(int) numChannels
{
	return _numChannels;
}



@end
