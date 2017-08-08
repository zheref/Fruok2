//
//  NSView+SubviewHelpers.m
//  Fruok
//
//  Created by Matthias Keiser on 08.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

#import "NSView+SubviewHelpers.h"
#import "NSLayoutConstraint+utilities.h"

@implementation NSView (SubviewHelpers)

- (void)tr_addFillingSubview:(NSView *)subview {

	subview.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:subview];
	[self addConstraints:[NSLayoutConstraint tr_fitView:subview]];
}
@end
