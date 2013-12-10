//
//  UIAccessibilityElement-KIFAdditions.m
//  KIF
//
//  Created by Eric Firestone on 5/23/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "NSError-KIFAdditions.h"
#import "UIAccessibilityElement-KIFAdditions.h"
#import "UIApplication-KIFAdditions.h"
#import "UIScrollView-KIFAdditions.h"
#import "UIView-KIFAdditions.h"
#import "LoadableCategory.h"
#import "KIFTestActor.h"

MAKE_CATEGORIES_LOADABLE(UIAccessibilityElement_KIFAdditions)


@implementation UIAccessibilityElement (KIFAdditions)

+ (UIView*) viewContainingAccessibilityElement:(UIAccessibilityElement*)element;
{
    while (element && ![element isKindOfClass:[UIView class]])
    {
        element = [element accessibilityContainer];
    }

    return (UIView*)element;
}

+ (BOOL) accessibilityElement:(out UIAccessibilityElement**)foundElement view:(out UIView**)foundView withLabel:(NSString*)label value:(NSString*)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable error:(out NSError**)error;
{
    UIAccessibilityElement* element = [self accessibilityElementWithLabel:label value:value traits:traits error:error];
    if (!element)
    {
        return NO;
    }

    UIView* view = [self viewContainingAccessibilityElement:element tappable:mustBeTappable error:error];
    if (!view)
    {
        return NO;
    }

    if (foundElement)
    {
        *foundElement = element;
    }
    if (foundView)
    {
        *foundView = view;
    }
    return YES;
}

+ (BOOL) accessibilityElement:(out UIAccessibilityElement**)foundElement view:(out UIView**)foundView withLabelOrIdentifier:(NSString*)labelOrIdentifier value:(NSString*)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable error:(out NSError**)error
{
    UIAccessibilityElement* element = [self accessibilityElementWithLabelOrIdentifier:labelOrIdentifier value:value traits:traits error:error];

    if (!element)
    {
        return NO;
    }

    UIView* view = [self viewContainingAccessibilityElement:element tappable:mustBeTappable error:error];
    if (!view)
    {
        return NO;
    }

    if (foundElement)
    {
        *foundElement = element;
    }
    if (foundView)
    {
        *foundView = view;
    }
    return YES;
}

+ (UIAccessibilityElement*) accessibilityElementWithLabel:(NSString*)label value:(NSString*)value traits:(UIAccessibilityTraits)traits error:(out NSError**)error;
{
    UIAccessibilityElement* element = [[UIApplication sharedApplication] accessibilityElementWithLabel:label accessibilityValue:value traits:traits];
    if (element || !error)
    {
        return element;
    }

    if (value)
    {
        element = [[UIApplication sharedApplication] accessibilityElementWithLabel:label accessibilityValue:nil traits:traits];
        // For purposes of a better error message, see if we can find the view, just not a view with the specified value.
        if (value && element)
        {
            *error = [NSError KIFErrorWithFormat:@"Found an accessibility element with the label \"%@\", but with the value \"%@\", not \"%@\"", label, element.accessibilityValue, value];
            return nil;
        }
    }

    if (traits > UIAccessibilityTraitNone)
    {
        // Check the traits, too.
        element = [[UIApplication sharedApplication] accessibilityElementWithLabel:label accessibilityValue:nil traits:UIAccessibilityTraitNone];
        if (traits != UIAccessibilityTraitNone && element)
        {
            *error = [NSError KIFErrorWithFormat:@"Found an accessibility element with the label \"%@\", but not with the traits \"%llu\"", label, traits];
            return nil;
        }
    }

    *error = [NSError KIFErrorWithFormat:@"Failed to find accessibility element with the label \"%@\"", label];
    return nil;
}

+ (UIAccessibilityElement*) accessibilityElementWithLabelOrIdentifier:(NSString*)labelOrIdentifier value:(NSString*)value traits:(UIAccessibilityTraits)traits error:(out NSError**)error
{
    UIAccessibilityElement* element = [[UIApplication sharedApplication] accessibilityElementWithLabelOrIdentifier:labelOrIdentifier accessibilityValue:value traits:traits];

    if (element || !error)
    {
        return element;
    }

    if (value)
    {
        element = [[UIApplication sharedApplication] accessibilityElementWithLabelOrIdentifier:labelOrIdentifier accessibilityValue:nil traits:traits];
        // For purposes of a better error message, see if we can find the view, just not a view with the specified value.
        if (value && element)
        {
            *error = [NSError KIFErrorWithFormat:@"Found an accessibility element with the label or identifier  \"%@\", but with the value \"%@\", not \"%@\"", labelOrIdentifier, element.accessibilityValue, value];
            return nil;
        }
    }

    if (traits > UIAccessibilityTraitNone)
    {
        // Check the traits, too.
        element = [[UIApplication sharedApplication] accessibilityElementWithLabel:labelOrIdentifier accessibilityValue:nil traits:UIAccessibilityTraitNone];
        if (traits != UIAccessibilityTraitNone && element)
        {
            *error = [NSError KIFErrorWithFormat:@"Found an accessibility element with the label or identifier \"%@\", but not with the traits \"%llu\"", labelOrIdentifier, traits];
            return nil;
        }
    }

    *error = [NSError KIFErrorWithFormat:@"Failed to find accessibility element with the label or identifier  \"%@\"", labelOrIdentifier];
    return nil;
}

+ (UIAccessibilityElement*) accessibilityElementWithLabelOrIdentifier:(NSString*)labelOrIdentifier error:(out NSError**)error
{
    return [UIAccessibilityElement accessibilityElementWithLabelOrIdentifier:labelOrIdentifier value:nil traits:UIAccessibilityTraitNone error:error];
}

+ (UIAccessibilityElement*) accessibilityElementMatchingBlock:(BOOL (^)(UIAccessibilityElement*))matchBlock error:(out NSError**)error;
{
    UIAccessibilityElement* element = [[UIApplication sharedApplication] accessibilityElementMatchingBlock:matchBlock];
    if (element || !error)
    {
        return element;
    }
    *error = [NSError KIFErrorWithFormat:@"Failed to find accessibility element with the match block \"%@\"", matchBlock];
    return nil;
}

+ (NSArray*) accessibilityElementsMatchingBlock:(BOOL (^)(UIAccessibilityElement*))matchBlock error:(out NSError**)error;
{
    NSArray* elements = [[UIApplication sharedApplication] accessibilityElementsMatchingBlock:matchBlock];
    if (elements || !error)
    {
        return elements;
    }
    *error = [NSError KIFErrorWithFormat:@"Failed to find accessibility elements with the match block \"%@\"", matchBlock];
    return nil;
}

+ (BOOL) accessibilityElement:(out UIAccessibilityElement**)foundElement view:(out UIView**)foundView matchingBlock:(BOOL (^)(UIAccessibilityElement*))matchBlock error:(out NSError**)error;
{
    UIAccessibilityElement* element = [self accessibilityElementMatchingBlock:matchBlock error:error];
    if (!element)
    {
        return NO;
    }

    UIView* view = [self viewContainingAccessibilityElement:element tappable:NO error:error];
    if (!view)
    {
        return NO;
    }

    if (foundElement)
    {
        *foundElement = element;
    }
    if (foundView)
    {
        *foundView = view;
    }
    return YES;
}

+ (UIView*) viewContainingAccessibilityElement:(UIAccessibilityElement*)element tappable:(BOOL)mustBeTappable error:(NSError**)error;
{
    // Small safety mechanism.  If someone calls this method after a failing call to accessibilityElementWithLabel:..., we don't want to wipe out the error message.
    if (!element && error && *error)
    {
        return nil;
    }

    // Make sure the element is visible
    UIView* view = [UIAccessibilityElement viewContainingAccessibilityElement:element];
    if (!view)
    {
        if (error)
        {
            *error = [NSError KIFErrorWithFormat:@"Cannot find view containing accessibility element with the label \"%@\"", element.accessibilityLabel];
        }
        return nil;
    }

    // Scroll the view to be visible if necessary
    UIScrollView* scrollView = (UIScrollView*)view;
    while (scrollView && ![scrollView isKindOfClass:[UIScrollView class]])
    {
        scrollView = (UIScrollView*)scrollView.superview;
    }
    if (scrollView)
    {
        if ((UIAccessibilityElement*)view == element)
        {
            [scrollView scrollViewToVisible:view animated:YES];
        }
        else
        {
            CGRect elementFrame = [view.window convertRect:element.accessibilityFrame toView:scrollView];
            [scrollView scrollRectToVisible:elementFrame animated:YES];
        }

        // Give the scroll view a small amount of time to perform the scroll.
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.3, false);
    }

    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents])
    {
        if (error)
        {
            *error = [NSError KIFErrorWithFormat:@"Application is ignoring interaction events"];
        }
        return nil;
    }

    // If we don't require tappability, at least make sure it's not hidden
    if ([view isHidden] || view.alpha == 0.0)
    {
        if (error)
        {
            *error = [NSError KIFErrorWithFormat:@"Accessibility element with label \"%@\" is hidden.", element.accessibilityLabel];
        }
        return nil;
    }

    if (mustBeTappable && !view.isProbablyTappable)
    {
        if (error)
        {
            NSString* label = (element.accessibilityIdentifier ? element.accessibilityIdentifier : element.accessibilityLabel);
            *error = [NSError KIFErrorWithFormat:@"Accessibility element with label \"%@\" is not tappable. It may be blocked by other views.", label];
        }
        return nil;
    }

    return view;
}

@end
