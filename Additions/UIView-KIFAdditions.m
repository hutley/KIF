//
//  UIView-KIFAdditions.m
//  KIF
//
//  Created by Eric Firestone on 5/20/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "UIView-KIFAdditions.h"
#import "CGGeometry-KIFAdditions.h"
#import "UIAccessibilityElement-KIFAdditions.h"
#import "UIApplication-KIFAdditions.h"
#import "UITouch-KIFAdditions.h"
#import <objc/runtime.h>

typedef struct __GSEvent * GSEventRef;

//
// GSEvent is an undeclared object. We don't need to use it ourselves but some
// Apple APIs (UIScrollView in particular) require the x and y fields to be present.
//
@interface KIFEventProxy : NSObject
{
@public
	unsigned int flags;
	unsigned int type;
	unsigned int ignored1;
	float x1;
	float y1;
	float x2;
	float y2;
	unsigned int ignored2[10];
	unsigned int ignored3[7];
	float sizeX;
	float sizeY;
	float x3;
	float y3;
	unsigned int ignored4[3];
}

@end

@implementation KIFEventProxy
@end

// Exposes methods of UITouchesEvent so that the compiler doesn't complain
@interface UIEvent (KIFAdditionsPrivate)

- (void)_addTouch:(id)arg1 forDelayedDelivery:(BOOL)arg2;
- (void)_clearTouches;
- (void)_setGSEvent:(GSEventRef)event;

@end


@interface NSObject (UIWebDocumentViewInternal)

- (void)tapInteractionWithLocation:(CGPoint)point;

@end

@interface UIView (KIFAdditionsPrivate)

- (UIEvent *)_eventWithTouch:(UITouch *)touch;

@end


@implementation UIView (KIFAdditions)

+ (NSSet *)classesToSkipAccessibilitySearchRecursion
{
    static NSSet *classesToSkip;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // UIDatePicker contains hundreds of thousands of placeholder accessibility elements that aren't useful to KIF,
        // so don't recurse into a date picker when searching for matching accessibility elements
        classesToSkip = [[NSSet alloc] initWithObjects:[UIDatePicker class], nil];
    });
    
    return classesToSkip;
}

- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label
{
    return [self accessibilityElementWithLabel:label traits:UIAccessibilityTraitNone];
}

- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label traits:(UIAccessibilityTraits)traits;
{
    return [self accessibilityElementWithLabel:label accessibilityValue:nil traits:traits];
}

- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label accessibilityValue:(NSString *)value traits:(UIAccessibilityTraits)traits;
{
    return [self accessibilityElementMatchingBlock:^(UIAccessibilityElement *element) {
        
        // TODO: This is a temporary fix for an SDK defect.
        NSString *accessibilityValue = element.accessibilityValue;
        if ([accessibilityValue isKindOfClass:[NSAttributedString class]]) {
            accessibilityValue = [(NSAttributedString *)accessibilityValue string];
        }
        
        BOOL labelsMatch = [element.accessibilityLabel isEqual:label];
        BOOL traitsMatch = ((element.accessibilityTraits) & traits) == traits;
        BOOL valuesMatch = !value || [value isEqual:accessibilityValue];

        return (BOOL)(labelsMatch && traitsMatch && valuesMatch);
    }];
}

- (UIAccessibilityElement *)accessibilityElementWithLabelOrIdentifier:(NSString *)labelOrIdentifier accessibilityValue:(NSString *)value traits:(UIAccessibilityTraits)traits
{
    return [self accessibilityElementMatchingBlock:^(UIAccessibilityElement *element) {
        
        // TODO: This is a temporary fix for an SDK defect.
        NSString *accessibilityValue = element.accessibilityValue;
        if ([accessibilityValue isKindOfClass:[NSAttributedString class]]) {
            accessibilityValue = [(NSAttributedString *)accessibilityValue string];
        }
        
        BOOL labelsMatch = [element.accessibilityLabel isEqual:labelOrIdentifier];
        BOOL identifiersMatch = [element.accessibilityIdentifier isEqual:labelOrIdentifier];
        BOOL traitsMatch = ((element.accessibilityTraits) & traits) == traits;
        BOOL valuesMatch = !value || [value isEqual:accessibilityValue];
        
        return (BOOL)((labelsMatch||identifiersMatch) && traitsMatch && valuesMatch);
    }];
}


- (UIAccessibilityElement *)accessibilityElementMatchingBlock:(BOOL(^)(UIAccessibilityElement *))matchBlock;
{

    if (self.hidden) {
        return nil;
    }
    
    // In case multiple elements with the same label exist, prefer ones that are currently visible
    UIAccessibilityElement *matchingButOccludedElement = nil;
    
    BOOL elementMatches = matchBlock((UIAccessibilityElement *)self);

    if (elementMatches) {
        if (self.isTappable) {
            return (UIAccessibilityElement *)self;
        } else {
            matchingButOccludedElement = (UIAccessibilityElement *)self;
        }
    }
    
    if ([[[self class] classesToSkipAccessibilitySearchRecursion] containsObject:[self class]]) {
        return matchingButOccludedElement;
    }
    
    // Check the subviews first. Even if the receiver says it's an accessibility container,
    // the returned objects are UIAccessibilityElementMockViews (which aren't actually views)
    // rather than the real subviews it contains. We want the real views if possible.
    // UITableViewCell is such an offender.
    for (UIView *view in [self.subviews reverseObjectEnumerator]) {
        UIAccessibilityElement *element = [view accessibilityElementMatchingBlock:matchBlock];
        if (!element) {
            continue;
        }
        
        UIView *viewForElement = [UIAccessibilityElement viewContainingAccessibilityElement:element];
        CGRect accessibilityFrame = [viewForElement.window convertRect:element.accessibilityFrame toView:viewForElement];
        
        if ([viewForElement isTappableInRect:accessibilityFrame]) {
            return element;
        } else {
            matchingButOccludedElement = element;
        }
    }
    
    NSMutableArray *elementStack = [NSMutableArray arrayWithObject:self];
    
    while (elementStack.count) {
        UIAccessibilityElement *element = [[[elementStack lastObject] retain] autorelease];
        [elementStack removeLastObject];
        BOOL elementMatches = matchBlock(element);

        if (elementMatches) {
            UIView *viewForElement = [UIAccessibilityElement viewContainingAccessibilityElement:element];
            CGRect accessibilityFrame = [viewForElement.window convertRect:element.accessibilityFrame toView:viewForElement];

            if ([viewForElement isTappableInRect:accessibilityFrame]) {
                return element;
            } else {
                matchingButOccludedElement = element;
                continue;
            }
        }
        
        // If the view is an accessibility container, and we didn't find a matching subview,
        // then check the actual accessibility elements
        NSInteger accessibilityElementCount = element.accessibilityElementCount;
        if (accessibilityElementCount == 0 || accessibilityElementCount == NSNotFound) {
            continue;
        }
        
        for (NSInteger accessibilityElementIndex = 0; accessibilityElementIndex < accessibilityElementCount; accessibilityElementIndex++) {
            UIAccessibilityElement *subelement = [element accessibilityElementAtIndex:accessibilityElementIndex];
            
            UIView *viewForElement = [UIAccessibilityElement viewContainingAccessibilityElement:element];
            CGRect accessibilityFrame = [viewForElement.window convertRect:element.accessibilityFrame toView:viewForElement];
            
            //don't cause scrollviews and tableviews to completely load by trying to access all the nonvisible
            //cells, only look at ones that should be onscreen or nearly onscreen.
            BOOL shouldBeVisibleAlready = YES;
            if ([viewForElement isKindOfClass:[UIScrollView class]])
            {
                UIScrollView* scrollView = (id)viewForElement;

                //Load double the height to account for possible partial visibility....
                shouldBeVisibleAlready = (accessibilityFrame.origin.y > scrollView.contentOffset.y+scrollView.frame.size.height*2 && accessibilityFrame.origin.y < scrollView.contentOffset.y-scrollView.frame.size.height*2);
                
            }
            
            if (subelement && shouldBeVisibleAlready) {
                [elementStack addObject:subelement];
            }
        }
    }

    return matchingButOccludedElement;
}

- (UIView *)subviewWithClassNamePrefix:(NSString *)prefix;
{
    NSArray *subviews = [self subviewsWithClassNamePrefix:prefix];
    if ([subviews count] == 0) {
        return nil;
    }
    
    return subviews[0];
}

- (NSArray *)subviewsWithClassNamePrefix:(NSString *)prefix;
{
    NSMutableArray *result = [NSMutableArray array];
    
    // Breadth-first population of matching subviews
    // First traverse the next level of subviews, adding matches.
    for (UIView *view in self.subviews) {
        if ([NSStringFromClass([view class]) hasPrefix:prefix]) {
            [result addObject:view];
        }
    }
    
    // Now traverse the subviews of the subviews, adding matches.
    for (UIView *view in self.subviews) {
        NSArray *matchingSubviews = [view subviewsWithClassNamePrefix:prefix];
        [result addObjectsFromArray:matchingSubviews];
    }

    return result;
}

- (UIView *)subviewWithClassNameOrSuperClassNamePrefix:(NSString *)prefix;
{
    NSArray *subviews = [self subviewsWithClassNameOrSuperClassNamePrefix:prefix];
    if ([subviews count] == 0) {
        return nil;
    }
    
    return subviews[0];
}

- (NSArray *)subviewsWithClassNameOrSuperClassNamePrefix:(NSString *)prefix;
{
    NSMutableArray * result = [NSMutableArray array];
    
    // Breadth-first population of matching subviews
    // First traverse the next level of subviews, adding matches
    for (UIView *view in self.subviews) {
        Class klass = [view class];
        while (klass) {
            if ([NSStringFromClass(klass) hasPrefix:prefix]) {
                [result addObject:view];
                break;
            }
            
            klass = [klass superclass];
        }
    }
    
    // Now traverse the subviews of the subviews, adding matches
    for (UIView *view in self.subviews) {
        NSArray * matchingSubviews = [view subviewsWithClassNameOrSuperClassNamePrefix:prefix];
        [result addObjectsFromArray:matchingSubviews];
    }

    return result;
}


- (BOOL)isDescendantOfFirstResponder;
{
    if ([self isFirstResponder]) {
        return YES;
    }
    return [self.superview isDescendantOfFirstResponder];
}

- (void)flash;
{
	UIColor *originalBackgroundColor = [self.backgroundColor retain];
    for (NSUInteger i = 0; i < 5; i++) {
        self.backgroundColor = [UIColor yellowColor];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
        self.backgroundColor = [UIColor blueColor];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
    }
    self.backgroundColor = originalBackgroundColor;
    [originalBackgroundColor release];
}

- (void)tap;
{
    CGPoint centerPoint = CGPointMake(self.frame.size.width * 0.5f, self.frame.size.height * 0.5f);
    
    [self tapAtPoint:centerPoint];
}

#define DRAG_TOUCH_DELAY 0.01
#define TAP_TOUCH_DELAY 0.1

- (void)tapAtPoint:(CGPoint)point;
{
    // Web views don't handle touches in a normal fashion, but they do have a method we can call to tap them
    // This may not be necessary anymore. We didn't properly support controls that used gesture recognizers
    // when this was added, but we now do. It needs to be tested before we can get rid of it.
    id /*UIWebBrowserView*/ webBrowserView = nil;
    
    if ([NSStringFromClass([self class]) isEqual:@"UIWebBrowserView"]) {
        webBrowserView = self;
    } else if ([self isKindOfClass:[UIWebView class]]) {
        id webViewInternal = nil;
        object_getInstanceVariable(self, "_internal", (void **)&webViewInternal);
        object_getInstanceVariable(webViewInternal, "browserView", (void **)&webBrowserView);
    }
    
    if (webBrowserView) {
        [webBrowserView tapInteractionWithLocation:point];
        return;
    }
    
    // Handle touches in the normal way for other views
    UITouch *touch = [[UITouch alloc] initAtPoint:point inView:self];
    [touch setPhase:UITouchPhaseBegan];
    
    UIEvent *event = [self _eventWithTouch:touch];

    [[UIApplication sharedApplication] sendEvent:event];

    //Give the UI a chance to update
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, TAP_TOUCH_DELAY, false);

    [touch setPhase:UITouchPhaseEnded];
    [[UIApplication sharedApplication] sendEvent:event];

    // Dispatching the event doesn't actually update the first responder, so fake it
    if ([touch.view isDescendantOfView:self] && [self canBecomeFirstResponder]) {
        [self becomeFirstResponder];
    }

    [touch release];
}


- (void)longPressAtPoint:(CGPoint)point duration:(NSTimeInterval)duration
{
    UITouch *touch = [[UITouch alloc] initAtPoint:point inView:self];
    [touch setPhase:UITouchPhaseBegan];
    
    UIEvent *eventDown = [self _eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventDown];
    
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, DRAG_TOUCH_DELAY, false);
    
    for (NSTimeInterval timeSpent = DRAG_TOUCH_DELAY; timeSpent < duration; timeSpent += DRAG_TOUCH_DELAY)
    {
        [touch setPhase:UITouchPhaseStationary];
        
        UIEvent *eventStillDown = [self _eventWithTouch:touch];
        [[UIApplication sharedApplication] sendEvent:eventStillDown];
        
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, DRAG_TOUCH_DELAY, false);
    }
    
    [touch setPhase:UITouchPhaseEnded];
    UIEvent *eventUp = [self _eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventUp];
    
    // Dispatching the event doesn't actually update the first responder, so fake it
    if ([touch.view isDescendantOfView:self] && [self canBecomeFirstResponder]) {
        [self becomeFirstResponder];
    }
    
    [touch release];
}

- (void)dragFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint;
{
    [self dragFromPoint:startPoint toPoint:endPoint steps:3];
}


- (void)dragFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint steps:(NSUInteger)stepCount;
{
    KIFDisplacement displacement = CGPointMake(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
    [self dragFromPoint:startPoint displacement:displacement steps:stepCount];
}

- (void)dragFromPoint:(CGPoint)startPoint displacement:(KIFDisplacement)displacement steps:(NSUInteger)stepCount;
{
    CGPoint *path = alloca(stepCount * sizeof(CGPoint));
    
    for (NSUInteger i = 0; i < stepCount; i++)
    {
        CGFloat progress = ((CGFloat)i)/(stepCount - 1);
        path[i] = CGPointMake(startPoint.x + (progress * displacement.x),
                              startPoint.y + (progress * displacement.y));
        
        //NSLog (@"PATH_POINT_%i: %f,%f", i, path[i].x, path[i].y);

    }
    
    [self dragAlongPathWithPoints:path count:stepCount];
}

- (void)dragAlongPathWithPoints:(CGPoint *)points count:(NSInteger)count;
{
    // we need at least two points in order to make segments
    if (count < 2) {
        return;
    }

    // Create the touch (there should only be one touch object for the whole drag)
    UITouch *touch = [[UITouch alloc] initAtPoint:points[0] inView:self];
    [touch setPhase:UITouchPhaseBegan];
    
    UIEvent *eventDown = [self _eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventDown];

    CGPoint centerA = [self.window convertPoint:self.center fromView:self];
    //NSLog(@"CENTER_POINT_%i: %f %f", 0, centerA.x, centerA.y);

    CFRunLoopRunInMode(UIApplicationCurrentRunMode, DRAG_TOUCH_DELAY, false);

    for (NSInteger pointIndex = 1; pointIndex < count; pointIndex++) {
        CGPoint centerB = [self.window convertPoint:self.center fromView:self];
        //NSLog(@"CENTER_POINT_%i: %f %f DIFF:%f %f", pointIndex, centerB.x, centerB.y, centerA.x - centerB.x, centerA.y - centerB.y);
        CGFloat changeX = centerB.x - centerA.x;
        CGFloat changeY = centerB.y - centerA.y;
        
        CGPoint dragPoint =[self.window convertPoint:points[pointIndex] fromView:self];
        dragPoint = CGPointMake(dragPoint.x-changeX, dragPoint.y-changeY);
        [touch setLocationInWindow:dragPoint];
        //NSLog(@"DRAG_POINT_%i: %f %f", pointIndex, dragPoint.x, dragPoint.y);

        [touch setPhase:UITouchPhaseMoved];
                UIEvent *eventDrag = [self _eventWithTouch:touch];
        [[UIApplication sharedApplication] sendEvent:eventDrag];

        CFRunLoopRunInMode(UIApplicationCurrentRunMode, DRAG_TOUCH_DELAY, false);
    }
    
    [touch setPhase:UITouchPhaseEnded];
    
    UIEvent *eventUp = [self _eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventUp];
    
    // Dispatching the event doesn't actually update the first responder, so fake it
    if (touch.view == self && [self canBecomeFirstResponder]) {
        [self becomeFirstResponder];
    }
    
    while (UIApplicationCurrentRunMode != kCFRunLoopDefaultMode) {
        CFRunLoopRunInMode(UIApplicationCurrentRunMode, 0.1, false);
    }
    [touch release];
}

- (BOOL)isProbablyTappable
{
    // There are some issues with the tappability check in UIWebViews, so if the view is a UIWebView we will just skip the check.
    return [NSStringFromClass([self class]) isEqualToString:@"UIWebBrowserView"] || self.isTappable;
}

// Is this view currently on screen?
- (BOOL)isTappable;
{
    return [self isTappableInRect:self.bounds];
}

- (BOOL)isTappableInRect:(CGRect)rect;
{
    CGPoint tappablePoint = [self tappablePointInRect:rect];
    
    return !isnan(tappablePoint.x);
}

- (BOOL)isTappableWithHitTestResultView:(UIView *)hitView;
{
    // Special case for UIControls, which may have subviews which don't respond to -hitTest:,
    // but which are tappable. In this case the hit view will be the containing
    // UIControl, and it will forward the tap to the appropriate subview.
    // This applies with UISegmentedControl which contains UISegment views (a private UIView
    // representing a single segment).
    if ([hitView isKindOfClass:[UIControl class]] && [self isDescendantOfView:hitView]) {
        return YES;
    }
    
    // Button views in the nav bar (a private class derived from UINavigationItemView), do not return
    // themselves in a -hitTest:. Instead they return the nav bar.
    if ([hitView isKindOfClass:[UINavigationBar class]] && [self isNavigationItemView] && [self isDescendantOfView:hitView]) {
        return YES;
    }
    
    return [hitView isDescendantOfView:self];
}

- (CGPoint)tappablePointInRect:(CGRect)rect;
{
    // Start at the top and recurse down
    CGRect frame = [self.window convertRect:rect fromView:self];
    
    UIView *hitView = nil;
    CGPoint tapPoint = CGPointZero;
    
    // Mid point
    tapPoint = CGPointCenteredInRect(frame);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    // Top left
    tapPoint = CGPointMake(frame.origin.x + 1.0f, frame.origin.y + 1.0f);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    // Top right
    tapPoint = CGPointMake(frame.origin.x + 1.0f + frame.size.width - 1.0f, frame.origin.y + 1.0f);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    // Bottom left
    tapPoint = CGPointMake(frame.origin.x + 1.0f, frame.origin.y + frame.size.height - 1.0f);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    // Bottom right
    tapPoint = CGPointMake(frame.origin.x + frame.size.width - 1.0f, frame.origin.y + frame.size.height - 1.0f);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    return CGPointMake(NAN, NAN);
}

- (UIEvent *)_eventWithTouch:(UITouch *)touch;
{
    UIEvent *event = [[UIApplication sharedApplication] performSelector:@selector(_touchesEvent)];
    
    CGPoint location = [touch locationInView:touch.window];
    KIFEventProxy *eventProxy = [[KIFEventProxy alloc] init];
    eventProxy->x1 = location.x;
    eventProxy->y1 = location.y;
    eventProxy->x2 = location.x;
    eventProxy->y2 = location.y;
    eventProxy->x3 = location.x;
    eventProxy->y3 = location.y;
    eventProxy->sizeX = 1.0;
    eventProxy->sizeY = 1.0;
    eventProxy->flags = ([touch phase] == UITouchPhaseEnded) ? 0x1010180 : 0x3010180;
    eventProxy->type = 3001;	

    NSSet *allTouches = [event allTouches];
    [event _clearTouches];
    [allTouches makeObjectsPerformSelector:@selector(autorelease)];
    [event _setGSEvent:(struct __GSEvent *)eventProxy];
    [event _addTouch:touch forDelayedDelivery:NO];
    
    [eventProxy release];
    return event;
}

- (BOOL)isUserInteractionActuallyEnabled;
{
    BOOL isUserInteractionEnabled = self.userInteractionEnabled;
    
    // Navigation item views don't have user interaction enabled, but their parent nav bar does and will forward the event
    if (!isUserInteractionEnabled && [self isNavigationItemView]) {
        // If this view is inside a nav bar, and the nav bar is enabled, then consider it enabled
        UIView *navBar = [self superview];
        while (navBar && ![navBar isKindOfClass:[UINavigationBar class]]) {
            navBar = [navBar superview];
        }
        if (navBar && navBar.userInteractionEnabled) {
            isUserInteractionEnabled = YES;
        }
    }
    
    // UIActionsheet Buttons have UIButtonLabels with userInteractionEnabled=NO inside,
    // grab the superview UINavigationButton instead.
    if (!isUserInteractionEnabled && [self isKindOfClass:NSClassFromString(@"UIButtonLabel")]) {
        UIView *button = [self superview];
        while (button && ![button isKindOfClass:NSClassFromString(@"UIButton")]) {
            button = [button superview];
        }
        if (button && button.userInteractionEnabled) {
            isUserInteractionEnabled = YES;
        }
    }
    
    return isUserInteractionEnabled;
}

- (BOOL)isNavigationItemView;
{
    return [self isKindOfClass:NSClassFromString(@"UINavigationItemView")] || [self isKindOfClass:NSClassFromString(@"_UINavigationBarBackIndicatorView")];
}

- (UIWindow *)windowOrIdentityWindow
{
    if (CGAffineTransformIsIdentity(self.window.transform)) {
        return self.window;
    }
    
    for (UIWindow *window in [[UIApplication sharedApplication] windowsWithKeyWindow]) {
        if (CGAffineTransformIsIdentity(window.transform)) {
            return window;
        }
    }
    
    return nil;
}

@end
