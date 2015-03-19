//
//  GraphView.m
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/16/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#import "GraphView.h"

extern struct fft_data fftd;

@implementation GraphView

@synthesize lock = _lock;

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		_W = _N = 2048;
		_H = 500.0;
		_fs = 48000.0;
		_binw = _fs / (float)_N;
		self.lock = [[NSLock alloc] init];
	}
	return self;
}

-(void) computePoints
{
	int i;
	CGFloat width = self.frame.size.width;
	CGFloat b = (2 * width) / (float)fftd.N;
	
	for (i = 0; i < fftd.N / 2; ++i) {
//		_plot[i].x = marginX + (i * b);
//		_plot[i].x = marginX + log(i * b);
		_plot[i].x = marginX + (.144 * width * log(i + 1));
		_plot[i].y =  marginY + fftd.MAG1[i] + 110;
	}
}

-(void) drawRect:(NSRect)dirtyRect
{
	int i;

	CGMutablePathRef plot_iter = NULL;
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
			  self.frame.origin.x + marginX,
			  marginY);
	CGPathAddLineToPoint(grid,
			     &CGAffineTransformIdentity,
			     self.frame.size.width,
			     marginY);
	
	/* y axis */
	CGPathMoveToPoint(grid,
			  &CGAffineTransformIdentity,
			  marginX,
			  marginY);
	CGPathAddLineToPoint(grid,
			     &CGAffineTransformIdentity,
			     marginX,
			     self.frame.size.height);
	CGPathCloseSubpath(grid);



	CGContextAddPath(ctx, grid);
	CGContextSetStrokeColorWithColor(ctx, [[NSColor blackColor] CGColor]);
	CGContextStrokePath(ctx);
	
	/* Loop to create plot */
	if (fftd.N - fftd.pos)
		[self computePoints];
	for (i = 0; i < fftd.N / 2; ++i) {
		plot_iter = CGPathCreateMutable();
		CGPathMoveToPoint(plot_iter,
				  &CGAffineTransformIdentity,
				  _plot[i].x,
				  marginY);
		CGPathAddLineToPoint(plot_iter,
				     &CGAffineTransformIdentity,
				     _plot[i].x,
				     _plot[i].y);
		CGPathCloseSubpath(plot_iter);
		CGContextAddPath(ctx, plot_iter);
		CGContextSetStrokeColorWithColor(ctx, [[NSColor redColor] CGColor]);
		CGContextStrokePath(ctx);
		plot_iter = NULL;
	}
	
	
	fftd.processed = 0;
	[self setNeedsDisplay:YES];
}


@end
