//
//  GMBFourierAnalyzer.h
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/17/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import "GMBObject.h"
#import "fft.h"

#ifndef FFT
#define FFT

#define FFT_MAX_N 2048

struct fft_data {
	float REX1[FFT_MAX_N];
	float REX2[FFT_MAX_N];
	float IMX1[FFT_MAX_N];
	float IMX2[FFT_MAX_N];
	float MAG1[FFT_MAX_N];
	float MAG2[FFT_MAX_N];
	float PHA1[FFT_MAX_N];
	float PHA2[FFT_MAX_N];
	unsigned int N;
	unsigned int pos;
};

struct fft_data fftd;

@interface GMBFourierAnalyzer : GMBObject
{
	
}

-(id) initWithBins: (unsigned int)N;
@end

#endif