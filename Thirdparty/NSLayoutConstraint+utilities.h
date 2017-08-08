//
//  NSLayoutConstraint+utilities.h
//  GalleryBuilder
//
//  Created by Matthias Keiser on 02.01.15.
//  Copyright (c) 2015 RandomWalk Innovations Inc.  All rights reserved.
//

#import <TargetConditionals.h>

#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif


#if TARGET_OS_IPHONE

#define VIEW UIView
#else

#define VIEW NSView

#endif

@interface NSLayoutConstraint (utilities)


+ (NSArray<NSLayoutConstraint *> *)tr_fitView:(VIEW *)view;
+ (NSArray<NSLayoutConstraint *> *)tr_fitView:(VIEW *)view withMargin:(CGFloat)margin;
+ (NSArray<NSLayoutConstraint *> *)tr_constantSized:(VIEW *)view;
+ (NSLayoutConstraint *)tr_centerHorizontally:(VIEW *)view inView:(VIEW *)superview;
+ (NSLayoutConstraint *)tr_centerVertically:(VIEW *)view inView:(VIEW *)superview;
+ (NSArray<NSLayoutConstraint *> *)tr_center:(VIEW *)view inView:(VIEW *)superview;
+ (NSArray<NSLayoutConstraint *> *)tr_constrainToFrame:(VIEW *)view;
+ (NSArray<NSLayoutConstraint *> *)tr_constrainView:(VIEW *)view toFrame:(CGRect)frame;

@end
