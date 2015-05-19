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
		int i;

		_W = _N = 2048;
		_H = 500.0;
		_fs = 48000.0;
		_binw = _fs / (float)_N;
		self.lock = [[NSLock alloc] init];
		_special[0] = 20;
		_special[1] = 50;
		_special[2] = 100;
		_special[3] = 200;
		_special[4] = 500;
		_special[5] = 1000;
		_special[6] = 2000;
		_special[7] = 5000;
		_special[8] = 10000;
		_special[9] = 20000;
		
		
		/* Text labels */
		NSRect textframe;
		textframe.origin.x = -100;
		textframe.size.width = 20;
		textframe.size.height = 20;
		labels = [[NSArray alloc] initWithObjects:@"20Hz", @"50Hz", @"100Hz", @"200Hz", @"500Hz",
			  @"1kHz", @"2kHz", @"5kHz", @"10kHz", @"20kHz", nil];
		dbs = [[NSArray alloc] initWithObjects:@"-60dB", @"-40dB", @"-20dB", @"0dB", @"20dB", nil];
		for (i = 0; i < 10; ++i) {
			tlabels[i] = [[NSTextView alloc] initWithFrame:textframe];
			[tlabels[i] setString:[labels objectAtIndex:(NSUInteger)i]];
			[tlabels[i] setFont:[NSFont fontWithName:@"Courier" size:10]];
			[tlabels[i] setTextColor:[NSColor whiteColor]];
			[tlabels[i] setBackgroundColor:[NSColor blackColor]];
			[self addSubview:tlabels[i]];
		}
		for (i = 0; i < 5; ++i) {
			dblabels[i] = [[NSTextView alloc] initWithFrame:textframe];
			[dblabels[i] setString:[dbs objectAtIndex:(NSUInteger)i]];
			[dblabels[i] setFont:[NSFont fontWithName:@"Courier" size:10]];
			[dblabels[i] setTextColor:[NSColor whiteColor]];
			[dblabels[i] setBackgroundColor:[NSColor blackColor]];
			[self addSubview:dblabels[i]];
		}
		
		NSRect trackingRect = self.frame;
		trackingRect.size.width -= marginX;
		trackingRect.size.height -= marginY;
		trackingRect.origin.x += marginX;
		trackingRect.origin.y += marginY;
		
		filterTrackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect
							options:NSTrackingActiveAlways |
								NSTrackingMouseEnteredAndExited |
				      				NSTrackingMouseMoved
							owner:self
							userInfo:nil];
		
		[self addTrackingArea:filterTrackingArea];
		mouseDownInTrackingArea = NO;

	}
	return self;
}


-(void) updateTrackingAreas {
	NSRect trackingRect = self.frame;
	trackingRect.size.width -= marginX;
	trackingRect.size.height -= marginY;
	trackingRect.origin.x += marginX;
	trackingRect.origin.y += marginY;
	[self removeTrackingArea:filterTrackingArea];
	filterTrackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect
							  options:NSTrackingActiveAlways |
			      NSTrackingMouseEnteredAndExited
							    owner:self
							 userInfo:nil];
	
	[self addTrackingArea:filterTrackingArea];
}

//-(void) mouseDown:(NSEvent *)theEvent
//{
//	NSPoint eventOrigin = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//	if (CGRectContainsPoint(filterTrackingArea.rect, eventOrigin)) {
//		float x = eventOrigin.x;
//		float k;
//		CGFloat width = self.frame.size.width - marginX;
//		
//		mouseDownInTrackingArea = YES;
//
////		k = expf((x - marginX) / (.144 * width)) - 1;
////		lpf.fc = (k * fftd.Fs) / (float)fftd.N;
////		lpf.Q = eventOrigin.y / filterTrackingArea.rect.size.height;
//	}
//}
//
//-(void) mouseMoved:(NSEvent *)theEvent
//{
//	if (mouseDownInTrackingArea) {
//		NSPoint eventOrigin = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//		float x = eventOrigin.x;
//		float k;
//		
//		CGFloat width = self.frame.size.width - marginX;
//		
//		k = expf((x - marginX) / (.144 * width)) - 1;
//		lpf.fc = (k * fftd.Fs) / (float)fftd.N;
//		lpf.Q = eventOrigin.y / filterTrackingArea.rect.size.height;
//	}
//
//}
//
//-(void) mouseUp:(NSEvent *)theEvent
//{
//	NSPoint loc = [theEvent locationInWindow];
//	if (CGRectContainsPoint(filterTrackingArea.rect, loc)) {
//		mouseDownInTrackingArea = NO;
//	}
//}

-(void) mouseDragged:(NSEvent *)theEvent
{
	NSPoint eventOrigin = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	float x = eventOrigin.x;
	float k;
	
	CGFloat width = self.frame.size.width - marginX;
	
	k = expf((x - marginX) / (.144 * width)) - 1;
	lpf.fc = (k * fftd.Fs) / (float)fftd.N;
	lpf.Q = 10 * eventOrigin.y / filterTrackingArea.rect.size.height;
}

-(void) computePoints
{
	int i;
	CGFloat width = self.frame.size.width - marginX;

	for (i = 0; i < fftd.N / 2; ++i) {
		_plot[i].x = marginX + (.144 * width * log(i + 1));
		_plot[i].y =  (((fftd.MAG1[i] / 80.0)) * (self.frame.size.height - marginY)) + marginY;
		if (_plot[i].y < marginY)
			_plot[i].y = marginY;
	}
}

-(void) computeSpecialPoints
{
	int i;
	CGFloat f;
	CGFloat width = self.frame.size.width - marginX;
	CGFloat height = self.frame.size.height;

	/* Transform special points */
	for (i = 0; i < 10; ++i) {
		f = _special[i];
		spoints[i] = marginX + (.144 * width * log((fftd.N * f / fftd.Fs) + 1));
		[tlabels[i] setFrameOrigin:CGPointMake(spoints[i] - 25, marginY - 30)];
		[tlabels[i] setFrameSize:CGSizeMake(50, 20)];
		[tlabels[i] setAlphaValue:1.0];
		[tlabels[i] setNeedsDisplay:YES];
	}
	
	/* Set db gridlines (y axis) */
	for (i = 0; i < 5; ++i) {
		dbpoints[i] = (i / 5.0) * (height - marginY) + marginY;
		[dblabels[i] setFrameOrigin:CGPointMake(2, ((i / 5.0) * (height - marginY)) + marginY)];
		[dblabels[i] setFrameSize:CGSizeMake(50, 20)];
		[dblabels[i] setAlphaValue:1.0];
		[dblabels[i] setNeedsDisplay:YES];
	}
	
}

-(void) drawRect:(NSRect)dirtyRect
{
	int i;

	CGMutablePathRef plot_iter = NULL;
	CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
	CGMutablePathRef outerBarPathRef = CGPathCreateMutable();
	CGMutablePathRef specialFrequencies = CGPathCreateMutable();
	CGMutablePathRef dblines = CGPathCreateMutable();
	CGPathMoveToPoint(outerBarPathRef, NULL, 0, 0);
	CGPathAddRect(outerBarPathRef, NULL, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
	CGPathCloseSubpath(outerBarPathRef);
	
	CGContextAddPath(ctx, outerBarPathRef);
	CGContextSetFillColorWithColor(ctx, [NSColor blackColor].CGColor);
	CGContextFillPath(ctx);
	
	/* Draw the grid lines */
	CGMutablePathRef grid = CGPathCreateMutable();
	
	
	[self computeSpecialPoints];
	/* Loop to create plot */
	if (fftd.N - fftd.pos)
		[self computePoints];
	
	plot_iter = CGPathCreateMutable();
	CGPathMoveToPoint(plot_iter,
			  &CGAffineTransformIdentity,
			  marginX,
			  _plot[0].y);
	
	for (i = 1; i < (fftd.N / 2); ++i) {
		CGPathAddLineToPoint(plot_iter,
				     &CGAffineTransformIdentity,
				     _plot[i].x,
				     _plot[i].y);
	}
	CGPathAddLineToPoint(plot_iter, &CGAffineTransformIdentity, self.frame.size.width, marginY);
	CGPathAddLineToPoint(plot_iter, &CGAffineTransformIdentity, marginX, marginY);
	CGPathCloseSubpath(plot_iter);
	CGContextAddPath(ctx, plot_iter);
	CGContextSetStrokeColorWithColor(ctx, [[NSColor greenColor] CGColor]);
	CGContextStrokePath(ctx);
	CGPathRelease(plot_iter);
	plot_iter = NULL;
	/* x axis */
	CGPathMoveToPoint(grid, &CGAffineTransformIdentity,
			  self.frame.origin.x + marginX,
			  marginY);
	CGPathAddLineToPoint(grid,
			     &CGAffineTransformIdentity,
			     self.frame.size.width - marginX,
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
	CGContextSetStrokeColorWithColor(ctx, [[NSColor yellowColor] CGColor]);
	CGContextStrokePath(ctx);
	CGPathRelease(grid);
	
	/* Special points */
	for (i = 0; i < 10; ++i) {
		CGPathMoveToPoint(specialFrequencies, &CGAffineTransformIdentity, spoints[i], marginY);
		CGPathAddLineToPoint(specialFrequencies, &CGAffineTransformIdentity, spoints[i], self.frame.size.height);
	}
	
	CGContextAddPath(ctx, specialFrequencies);
	CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.5] CGColor]);
	CGContextStrokePath(ctx);
	
	/* dblines */
	for (i = 0; i < 5; ++i) {
		CGPathMoveToPoint(dblines, &CGAffineTransformIdentity, marginX, dbpoints[i]);
		CGPathAddLineToPoint(dblines, &CGAffineTransformIdentity, self.frame.size.width, dbpoints[i]);
	}

	CGContextAddPath(ctx, dblines);
	CGContextStrokePath(ctx);
	CGPathRelease(dblines);
	CGPathRelease(specialFrequencies);
	CGPathRelease(outerBarPathRef);
	
	fftd.processed = 0;
	[self setNeedsDisplay:YES];
}

-(void) dealloc
{
	/* Not sure if this is necessary? */
	[self removeTrackingArea:filterTrackingArea];
	filterTrackingArea = nil;
}

@end
