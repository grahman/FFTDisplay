//
//  CommonHeaders.h
//  AVAssets2
//
//  Created by Graham Barab on 6/20/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CAUtilityFunctions.h"
#import "GMBAudioStreamBasicDescription.h"
#import "TPCircularBuffer.h"
#import "GMBUtil.h"
#import <dispatch/dispatch.h>


static void* mediaStatusContext = &mediaStatusContext;
static void* needsNewBufferContext = &needsNewBufferContext;
static void* mediaIsReadyContext = &mediaIsReadyContext;
static void* mixerNodeChangedContext = &mixerNodeChangedContext;