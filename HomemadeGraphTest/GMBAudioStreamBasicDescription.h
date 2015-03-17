//
//  GMBAudioStreamBasicDescription.h
//  AVAssets
//
//  Created by Graham Barab on 6/20/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

@interface GMBAudioStreamBasicDescription : NSObject

@property  AudioStreamBasicDescription* asbd;

-(id) initWithAudioStreamBasicDescription : (const AudioStreamBasicDescription*)asbd_;

@end


