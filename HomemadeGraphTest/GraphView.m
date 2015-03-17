//
//  GraphView.m
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/16/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import "GraphView.h"

@implementation GraphView

@synthesize lock = _lock;

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		_W = _N = 1024;
		_H = 500.0;
		_fs = 48000.0;
		_binw = _fs / (float)_N;
		self.lock = [[NSLock alloc] init];
	}
	return self;
}

-(void) drawRect:(NSRect)dirtyRect
{
	CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
	CGMutablePathRef outerBarPathRef = CGPathCreateMutable();
	CGPathMoveToPoint(outerBarPathRef, NULL, 0, 0);
	CGPathAddRect(outerBarPathRef, NULL, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
	CGPathCloseSubpath(outerBarPathRef);
	
	CGContextAddPath(ctx, outerBarPathRef);
	CGContextSetFillColorWithColor(ctx, [NSColor whiteColor].CGColor);
	CGContextFillPath(ctx);
	
	/* Draw the grid lines */
	CGMutablePathRef grid = CGPathCreateMutable();
	
	/* x axis */
	CGPathMoveToPoint(grid, &CGAffineTransformIdentity,
			  self.frame.origin.x + 40,
			  40);
	CGPathAddLineToPoint(grid,
			     &CGAffineTransformIdentity,
			     self.frame.size.width,
			     40);
	
	/* y axis */
	CGPathMoveToPoint(grid,
			  &CGAffineTransformIdentity,
			  40,
			  40);
	CGPathAddLineToPoint(grid,
			     &CGAffineTransformIdentity,
			     40,
			     self.frame.size.height);
	CGPathCloseSubpath(grid);
	
	CGContextAddPath(ctx, grid);
	CGContextSetStrokeColorWithColor(ctx, [[NSColor blackColor] CGColor]);
	CGContextStrokePath(ctx);
	[self setNeedsDisplay:YES];
}


@end
