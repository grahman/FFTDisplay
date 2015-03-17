//
//  GMBDelegate.h
//  QTTest
//
//  Created by Graham Barab on 6/16/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GMBDelegate : NSObject
{
	void (^_callback)(void);
}

@property (nonatomic, copy, readwrite) void (^callback)(void);


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
@end

@interface GMBQueue : NSObject
{
	NSUInteger						  _count;
	NSMutableArray*					 _array;
}

@property (readonly) NSObject*		  front;
@property (readonly) NSUInteger		 count;

-(id) init;
-(void) push : (NSObject*) object;
-(void) pop;								  //Pops off the first element in the queue.

@end