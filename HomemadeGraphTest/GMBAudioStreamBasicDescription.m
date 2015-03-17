//
//  GMBAudioStreamBasicDescription.m
//  AVAssets
//
//  Created by Graham Barab on 6/20/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBAudioStreamBasicDescription.h"

@implementation GMBAudioStreamBasicDescription

@synthesize asbd;

-(id) initWithAudioStreamBasicDescription:(const AudioStreamBasicDescription *)asbd_
{
	self = [super init];
	asbd = asbd_;
	return self;
}



@end

