//
//  GMBBackgroundTimer.h
//  AVAssets2
//
//  Created by Graham Barab on 7/30/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GMBBackgroundTimer : NSOperation
{
	BOOL _done;
}
@property SEL		 externalSelector;
@property id		  target;
@property double	timeInterval;

-(id)init;
-(id) initWithSelector:(SEL)selector_ andTarget:(id)target_;
-(void)cancel;

@end