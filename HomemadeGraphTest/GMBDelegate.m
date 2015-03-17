//
//  GMBDelegate.m
//  QTTest
//
//  Created by Graham Barab on 6/16/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBDelegate.h"

@implementation GMBDelegate

@synthesize callback = _callback;

- (id) init
{
	self = [super init];
	if (self)
	{

	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (self.callback != nil)
	{
		self.callback();
	}

}

@end

@implementation GMBQueue

//@synthesize front;

-(id) init;
{
	self = [super init];
	_count = 0;
	_array = [[NSMutableArray alloc] init];
	return self;
}

-(NSObject*)front
{
	if ([_array count]  < 1)
	{
		return nil;
	}
	return [[_array mutableArrayValueForKey:@"self"] objectAtIndex:0];
}

-(NSUInteger)count
{
	return [_array count];
}


-(void) push:(NSObject *)object
{
	[_array addObject:object];
	++_count;
}

-(void) pop
{
	if ([_array count] > 0)
	{
		[_array removeObjectAtIndex:0];
	}
}

@end