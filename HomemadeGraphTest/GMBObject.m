//
//  GMBObject.m
//  AVAssets2
//
//  Created by Graham Barab on 8/12/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBObject.h"

@implementation GMBObject
@synthesize kvoRegistrations = _kvoRegistrations;
@synthesize aboutToDealloc = _aboutToDealloc;

-(id) init
{
	self = [super init];

	_kvoRegistrations = [[NSMutableDictionary alloc] init];

	return self;
}

-(void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
	if (!_kvoRegistrations)
	{
		_kvoRegistrations = [[NSMutableDictionary alloc] init];
	}
	[super addObserver:observer forKeyPath:keyPath options:options context:context];
	if ([_kvoRegistrations valueForKey:keyPath])
	{
		[(NSCountedSet*)[_kvoRegistrations valueForKey:keyPath] addObject:observer];
	} else
	{
		NSCountedSet* registeredObjectsCountedSet = [[NSCountedSet alloc] initWithArray:nil];
		[registeredObjectsCountedSet addObject:observer];
		[_kvoRegistrations addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:registeredObjectsCountedSet, keyPath, nil]];
	}

//	NSLog(@"GMBEventHandlerView::Total observers for keypath %@: %lu", keyPath, (unsigned long)[[(NSCountedSet*)_kvoRegistrations valueForKey:keyPath] count]);
}

-(void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
	[super removeObserver:observer forKeyPath:keyPath];
	if ([_kvoRegistrations valueForKey:keyPath])
	{
		[(NSCountedSet*)[_kvoRegistrations valueForKey:keyPath] removeObject:observer];
	} else
	{

	}
}

-(void)dealloc
{

}

-(NSCountedSet*)objectsObservingKeyPath:(NSString *)keyPath
{
	NSLog(@"%@", keyPath);
	return nil;
}

+(BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	return YES;
}

@end

