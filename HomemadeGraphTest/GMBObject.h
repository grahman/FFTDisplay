//
//  GMBObject.h
//  AVAssets2
//
//  Created by Graham Barab on 8/12/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GMBObject : NSObject
{
	NSMutableDictionary*  _kvoRegistrations;
	BOOL					_aboutToDealloc;
}

@property (strong, readonly) NSMutableDictionary*  kvoRegistrations;
@property (readonly) BOOL				   aboutToDealloc;


-(id) init;

-(void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
-(NSCountedSet*) objectsObservingKeyPath: (NSString*)keyPath;

@end


