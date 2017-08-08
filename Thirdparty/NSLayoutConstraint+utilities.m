//
//  NSLayoutConstraint+utilities.m
//  GalleryBuilder
//
//  Created by Matthias Keiser on 02.01.15.
//  Copyright (c) 2015 RandomWalk Innovations Inc.  All rights reserved.
//

#import "NSLayoutConstraint+utilities.h"

@implementation NSLayoutConstraint (utilities)

+ (NSArray<NSLayoutConstraint *> *)tr_fitView:(VIEW *)view
{
	return [[self class] tr_fitView:view withMargin:0];
}

+ (NSArray<NSLayoutConstraint *> *)tr_fitView:(VIEW *)view withMargin:(CGFloat)margin
{
	NSMutableArray *constraints = [NSMutableArray new];

	NSDictionary *metrics = @{@"margin":@(margin)};

	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-margin-[contentView]-margin-|" options:0 metrics:metrics views:@{@"contentView":view}]];
	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[contentView]-margin-|" options:0 metrics:metrics views:@{@"contentView":view}]];

	return constraints;
}

+ (NSArray<NSLayoutConstraint *> *)tr_constrainToFrame:(VIEW *)view {

	return [self tr_constrainView:view toFrame:view.frame];
}

+ (NSArray<NSLayoutConstraint *> *)tr_constrainView:(VIEW *)view toFrame:(CGRect)frame {

	NSMutableArray *constraints = [NSMutableArray new];

	NSDictionary *metrics = @{
							  @"originX":@(CGRectGetMinX(frame)),
							  @"originY":@(CGRectGetMinY(frame)),
							  @"width":@(CGRectGetWidth(frame)),
							  @"height":@(CGRectGetHeight(frame))
							  };

	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-originX-[contentView(width)]" options:0 metrics:metrics views:@{@"contentView":view}]];

#if !TARGET_OS_IPHONE

	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView(height)]-originY-|" options:0 metrics:metrics views:@{@"contentView":view}]];

#else
	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-originY-[contentView(height)]" options:0 metrics:metrics views:@{@"contentView":view}]];
#endif
	return constraints;
}

+ (NSArray<NSLayoutConstraint *> *)tr_constantSized:(VIEW *)view {

	return @[
			 [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:CGRectGetWidth(view.frame)],
			 [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:CGRectGetHeight(view.frame)]
			];
}

+ (NSLayoutConstraint *)tr_centerHorizontally:(VIEW *)view inView:(VIEW *)superview {

	return [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterX
														relatedBy:NSLayoutRelationEqual
														   toItem:superview
														attribute:NSLayoutAttributeCenterX
													   multiplier:1.f constant:0.f];

}

+ (NSLayoutConstraint *)tr_centerVertically:(VIEW *)view inView:(VIEW *)superview {

	return [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY
														relatedBy:NSLayoutRelationEqual
														   toItem:superview
														attribute:NSLayoutAttributeCenterY
													   multiplier:1.f constant:0.f];
}

+ (NSArray<NSLayoutConstraint *> *)tr_center:(VIEW *)view inView:(VIEW *)superview {

	return @[
			 [[self class] tr_centerHorizontally:view inView:superview],
			 [[self class] tr_centerVertically:view inView:superview]
			 ];
}

@end
