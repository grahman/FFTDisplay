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
	float REX2[FFT_MAX_N];	/* For stereo support */
	float IMX1[FFT_MAX_N];
	float IMX2[FFT_MAX_N];	/* For stereo support */
	float MAG1[FFT_MAX_N];
	float MAG2[FFT_MAX_N];
	float PHA1[FFT_MAX_N];
	float PHA2[FFT_MAX_N];
	float Fs;		/* Sample rate */
	unsigned int N;
	unsigned int pos;	/* When pos == N, REX* is frequency domain data */
	int processed;		/* 0 = has not had hann window or mag_phase_response
				 * applied to it yet
				 * 1 = otherwise
				 */
};



struct fft_data fftd;

@interface GMBFourierAnalyzer : GMBObject
{
	int _numChannels;
}

@property int	numChannels;
-(id) initWithBins: (unsigned int)N;
-(void) process;
@end

#endif