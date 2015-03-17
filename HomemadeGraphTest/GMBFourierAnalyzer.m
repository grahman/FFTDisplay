//
//  GMBFourierAnalyzer.m
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/17/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import "GMBFourierAnalyzer.h"

@implementation GMBFourierAnalyzer

-(id) initWithBins: (unsigned int)N
{
	self = [super init];
	if (self) {
		fftd.N = N;
		fftd.pos = 0;
	}
	return self;
}

@end
