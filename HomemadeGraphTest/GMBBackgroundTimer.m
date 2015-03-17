//
//  GMBBackgroundTimer.m
//  AVAssets2
//
//  Created by Graham Barab on 7/30/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBBackgroundTimer.h"

static void* isCancelledContext = &isCancelledContext;

@implementation GMBBackgroundTimer
@synthesize externalSelector;
@synthesize target;
@synthesize timeInterval;

-(id) init
{
	self = [super init];
	timeInterval = 0.05;
	[self addObserver:self forKeyPath:NSStringFromSelector(@selector(isCancelled)) options:NSKeyValueObservingOptionNew context:isCancelledContext];
	return self;
}

-(id) initWithSelector:(SEL)selector_ andTarget:(id)target_
{
	self = [self init];
	externalSelector = selector_;
	target = target_;
	return self;
}

/**
 The following code example was obtained from http://stackoverflow.com/questions/15710908/nstimer-callback-on-background-thread
 **/
-(void) main
{
	if ([self isCancelled] || _done)
	{
		return;
	}

	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
													target:target
													selector:externalSelector
													userInfo:nil
													repeats:YES];

	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

	//keep the runloop going as long as needed
	while (!_done && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
											beforeDate:[NSDate distantFuture]]);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == isCancelledContext) {
		_done = YES;
	}
}

-(void)dealloc
{
	[self removeObserver:self forKeyPath:NSStringFromSelector(@selector(isCancelled))];
}

//-(void)cancel
//{
//	[super cancel];
//	_done = YES;
//}



@end

