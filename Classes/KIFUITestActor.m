//
//  KIFTester+UI.m
//  KIF
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "KIFUITestActor.h"
#import "UIApplication-KIFAdditions.h"
#import "UIWindow-KIFAdditions.h"
#import "UIAccessibilityElement-KIFAdditions.h"
#import "UIView-KIFAdditions.h"
#import "CGGeometry-KIFAdditions.h"
#import "NSError-KIFAdditions.h"
#import "KIFTypist.h"

@implementation KIFUITestActor


- (UIView*) waitForViewWithAccessibilityLabel:(NSString*)label
{
    return [self waitForViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone tappable:NO];
}

- (UIView*) waitForViewWithAccessibilityLabel:(NSString*)label traits:(UIAccessibilityTraits)traits
{
    return [self waitForViewWithAccessibilityLabel:label value:nil traits:traits tappable:NO];
}

- (UIView*) waitForViewWithAccessibilityLabel:(NSString*)label value:(NSString*)value traits:(UIAccessibilityTraits)traits
{
    return [self waitForViewWithAccessibilityLabel:label value:value traits:traits tappable:NO];
}

- (UIView*) waitForTappableViewWithAccessibilityLabel:(NSString*)label
{
    return [self waitForViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone tappable:YES];
}

- (UIView*) waitForTappableViewWithAccessibilityLabel:(NSString*)label traits:(UIAccessibilityTraits)traits
{
    return [self waitForViewWithAccessibilityLabel:label value:nil traits:traits tappable:YES];
}

- (UIView*) waitForTappableViewWithAccessibilityLabel:(NSString*)label value:(NSString*)value traits:(UIAccessibilityTraits)traits
{
    return [self waitForViewWithAccessibilityLabel:label value:value traits:traits tappable:YES];
}

- (UIView*) waitForViewWithAccessibilityLabel:(NSString*)label value:(NSString*)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable
{
    UIView* view = nil;

    [self waitForAccessibilityElement:NULL view:&view withLabel:label value:value traits:traits tappable:mustBeTappable];
    return view;
}

- (void) waitForAccessibilityElement:(UIAccessibilityElement**)element view:(out UIView**)view withLabel:(NSString*)label value:(NSString*)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
         return [UIAccessibilityElement accessibilityElement:element view:view withLabel:label value:value traits:traits tappable:mustBeTappable error:error] ? KIFTestStepResultSuccess : KIFTestStepResultWait;
     }];
}

- (void) waitForAccessibilityElement:(UIAccessibilityElement**)element view:(out UIView**)view withLabelOrIdentifier:(NSString*)labelOrIdentifier value:(NSString*)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
         return [UIAccessibilityElement accessibilityElement:element view:view withLabelOrIdentifier:labelOrIdentifier value:value traits:traits tappable:mustBeTappable error:error] ? KIFTestStepResultSuccess : KIFTestStepResultWait;
     }];
}

- (void) waitForAccessibilityElement:(UIAccessibilityElement**)element view:(out UIView**)view matchingBlock:(BOOL (^)(UIAccessibilityElement* element))matchBlock
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
         return [UIAccessibilityElement accessibilityElement:element view:view matchingBlock:matchBlock error:error] ? KIFTestStepResultSuccess : KIFTestStepResultWait;
     }];
}

- (UIView*) waitForViewWithAccessibilityIdentifier:(NSString*)identifier
{
    UIView* view = nil;

    [self waitForAccessibilityElement:NULL view:&view matchingBlock:^BOOL (UIAccessibilityElement* element) {
         return [element.accessibilityIdentifier isEqualToString:identifier];
     }];
    return view;
}

- (UIView*) waitForViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier
{
    return [self waitForViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier traits:UIAccessibilityTraitNone mustBeTappable:NO];
}

- (UIView*) waitForViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier traits:(UIAccessibilityTraits)traits
{
    return [self waitForViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier traits:traits mustBeTappable:NO];
}

- (UIView*) waitForViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier traits:(UIAccessibilityTraits)traits mustBeTappable:(BOOL)tappable
{
    UIView* view = nil;
    [self waitForAccessibilityElement:NULL view:&view withLabelOrIdentifier:labelOrIdentifier value:nil traits:traits tappable:tappable];
    return view;
}

- (void) waitForAbsenceOfViewWithAccessibilityLabel:(NSString*)label
{
    [self waitForAbsenceOfViewWithAccessibilityLabel:label traits:UIAccessibilityTraitNone];
}

- (void) waitForAbsenceOfViewWithAccessibilityLabel:(NSString*)label traits:(UIAccessibilityTraits)traits
{
    [self waitForAbsenceOfViewWithAccessibilityLabel:label value:nil traits:traits];
}

- (void) waitForAbsenceOfViewWithAccessibilityLabel:(NSString*)label value:(NSString*)value traits:(UIAccessibilityTraits)traits
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
         // If the app is ignoring interaction events, then wait before doing our analysis
         KIFTestWaitCondition(![[UIApplication sharedApplication] isIgnoringInteractionEvents], error, @"Application is ignoring interaction events.");

         // If the element can't be found, then we're done
         UIAccessibilityElement* element = [[UIApplication sharedApplication] accessibilityElementWithLabel:label accessibilityValue:value traits:traits];
         if (!element)
         {
             return KIFTestStepResultSuccess;
         }

         UIView* view = [UIAccessibilityElement viewContainingAccessibilityElement:element];

         // If we found an element, but it's not associated with a view, then something's wrong. Wait it out and try again.
         KIFTestWaitCondition(view, error, @"Cannot find view containing accessibility element with the label \"%@\"", label);

         // Hidden views count as absent
         KIFTestWaitCondition(view.isHidden || !view.isProbablyTappable, error, @"Accessibility element with label \"%@\" is visible and not hidden.", label);

         return KIFTestStepResultSuccess;
     }];
}

- (void) waitForAbsenceOfViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier
{
    [self waitForAbsenceOfViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier traits:UIAccessibilityTraitNone];
}

- (void) waitForAbsenceOfViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier traits:(UIAccessibilityTraits)traits
{
    [self waitForAbsenceOfViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier value:nil traits:traits];
}

- (void) waitForAbsenceOfViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier value:(NSString*)value traits:(UIAccessibilityTraits)traits
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
        // If the app is ignoring interaction events, then wait before doing our analysis
        KIFTestWaitCondition(![[UIApplication sharedApplication] isIgnoringInteractionEvents], error, @"Application is ignoring interaction events.");
        
        // If the element can't be found, then we're done
        UIAccessibilityElement* element = [[UIApplication sharedApplication] accessibilityElementWithLabelOrIdentifier:labelOrIdentifier accessibilityValue:value traits:traits];
        if (!element)
        {
            return KIFTestStepResultSuccess;
        }
        
        UIView* view = [UIAccessibilityElement viewContainingAccessibilityElement:element];
        // If we found an element, but it's not associated with a view, then something's wrong. Wait it out and try again.
        KIFTestWaitCondition(view, error, @"Cannot find view containing accessibility element with the label or identifier \"%@\"", labelOrIdentifier);
        
        // Hidden views count as absent
        KIFTestWaitCondition(view.isHidden || !view.isProbablyTappable, error, @"Accessibility element with label \"%@\" is visible and not hidden.", labelOrIdentifier);
        
        return KIFTestStepResultSuccess;
    }];
}



- (void) tapViewWithAccessibilityLabel:(NSString*)label
{
    [self tapViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone];
}

- (void) tapViewWithAccessibilityLabel:(NSString*)label traits:(UIAccessibilityTraits)traits
{
    [self tapViewWithAccessibilityLabel:label value:nil traits:traits];
}

- (void) tapViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier
{
    [self tapViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier value:nil traits:UIAccessibilityTraitNone];
}

- (void) tapViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier value:(NSString*)value traits:(UIAccessibilityTraits)traits
{
    UIView* view = nil;
    UIAccessibilityElement* element = nil;

    [self waitForAccessibilityElement:&element view:&view withLabelOrIdentifier:labelOrIdentifier value:nil traits:UIAccessibilityTraitNone tappable:YES];
    [self tapAccessibilityElement:element inView:view];
}

- (void) tapViewWithAccessibilityLabel:(NSString*)label value:(NSString*)value traits:(UIAccessibilityTraits)traits
{
    UIView* view = nil;
    UIAccessibilityElement* element = nil;

    [self waitForAccessibilityElement:&element view:&view withLabel:label value:value traits:traits tappable:YES];
    [self tapAccessibilityElement:element inView:view];
}

- (void) tapAccessibilityElement:(UIAccessibilityElement*)element inView:(UIView*)view
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
         KIFTestWaitCondition(view.isUserInteractionActuallyEnabled, error, @"View is not enabled for interaction");

         // If the accessibilityFrame is not set, fallback to the view frame.
         CGRect elementFrame;
         if (CGRectEqualToRect(CGRectZero, element.accessibilityFrame))
         {
             elementFrame.origin = CGPointZero;
             elementFrame.size = view.frame.size;
         }
         else
         {
             elementFrame = [view.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:view];
         }
         CGPoint tappablePointInElement = [view tappablePointInRect:elementFrame];

         // This is mostly redundant of the test in _accessibilityElementWithLabel:
         KIFTestWaitCondition(!isnan(tappablePointInElement.x), error, @"View is not tappable");
         [view tapAtPoint:tappablePointInElement];

         KIFTestCondition(![view canBecomeFirstResponder] || [view isDescendantOfFirstResponder], error, @"Failed to make the view into the first responder");

         return KIFTestStepResultSuccess;
     }];

    // Wait for the view to stabilize.
    [self waitForTimeInterval:0.5];
}

- (void) tapScreenAtPoint:(CGPoint)screenPoint
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
         // Try all the windows until we get one back that actually has something in it at the given point
         UIView* view = nil;
         for (UIWindow *window in [[[UIApplication sharedApplication] windowsWithKeyWindow] reverseObjectEnumerator])
         {
             CGPoint windowPoint = [window convertPoint:screenPoint fromView:nil];
             view = [window hitTest:windowPoint withEvent:nil];

         // If we hit the window itself, then skip it.
             if (view == window || view == nil)
             {
                 continue;
             }
         }

         KIFTestWaitCondition(view, error, @"No view was found at the point %@", NSStringFromCGPoint(screenPoint));

         // This is mostly redundant of the test in _accessibilityElementWithLabel:
         CGPoint viewPoint = [view convertPoint:screenPoint fromView:nil];
         [view tapAtPoint:viewPoint];

         return KIFTestStepResultSuccess;
     }];
}

- (void) longPressViewWithAccessibilityLabel:(NSString*)label duration:(NSTimeInterval)duration;
{
    [self longPressViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone duration:duration];
}

- (void) longPressViewWithAccessibilityLabel:(NSString*)label value:(NSString*)value duration:(NSTimeInterval)duration;
{
    [self longPressViewWithAccessibilityLabel:label value:value traits:UIAccessibilityTraitNone duration:duration];
}

- (void) longPressViewWithAccessibilityLabel:(NSString*)label value:(NSString*)value traits:(UIAccessibilityTraits)traits duration:(NSTimeInterval)duration;
{
    UIView* view = nil;
    UIAccessibilityElement* element = nil;

    [self waitForAccessibilityElement:&element view:&view withLabel:label value:value traits:traits tappable:YES];
    [self longPressAccessibilityElement:element inView:view duration:duration];
}

- (void) longPressAccessibilityElement:(UIAccessibilityElement*)element inView:(UIView*)view duration:(NSTimeInterval)duration;
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
         KIFTestWaitCondition(view.isUserInteractionActuallyEnabled, error, @"View is not enabled for interaction");

         CGRect elementFrame = [view.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:view];
         CGPoint tappablePointInElement = [view tappablePointInRect:elementFrame];

         // This is mostly redundant of the test in _accessibilityElementWithLabel:
         KIFTestWaitCondition(!isnan(tappablePointInElement.x), error, @"View is not tappable");
         [view longPressAtPoint:tappablePointInElement duration:duration];

         KIFTestCondition(![view canBecomeFirstResponder] || [view isDescendantOfFirstResponder], error, @"Failed to make the view into the first responder");

         return KIFTestStepResultSuccess;
     }];

    // Wait for view to settle.
    [self waitForTimeInterval:0.5];
}

- (void) enterTextIntoCurrentFirstResponder:(NSString*)text;
{
    // Wait for the keyboard
    [self waitForTimeInterval:1.0];
    [self enterTextIntoCurrentFirstResponder:text fallbackView:nil];
}

- (void) enterTextIntoCurrentFirstResponder:(NSString*)text fallbackView:(UIView*)fallbackView;
{
    for (NSUInteger characterIndex = 0; characterIndex < [text length]; characterIndex++)
    {
        NSString* characterString = [text substringWithRange:NSMakeRange(characterIndex, 1)];

        if (![KIFTypist enterCharacter:characterString])
        {
            // Attempt to cheat if we couldn't find the character
            if (!fallbackView)
            {
                UIResponder* firstResponder = [[[UIApplication sharedApplication] keyWindow] firstResponder];

                if ([firstResponder isKindOfClass:[UIView class]])
                {
                    fallbackView = (UIView*)firstResponder;
                }
            }

            if ([fallbackView isKindOfClass:[UITextField class]] || [fallbackView isKindOfClass:[UITextView class]])
            {
                NSLog(@"KIF: Unable to find keyboard key for %@. Inserting manually.", characterString);
                [(UITextField*)fallbackView setText:[[(UITextField*)fallbackView text] stringByAppendingString:characterString]];
            }
            else
            {
                [self failWithError:[NSError KIFErrorWithFormat:@"Failed to find key for character \"%@\"", characterString] stopTest:YES];
            }
        }
    }
}

- (void) enterText:(NSString*)text intoViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier
{
    return [self enterText:text intoViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier traits:UIAccessibilityTraitNone expectedResult:nil];
}

- (void) enterText:(NSString*)text intoViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier traits:(UIAccessibilityTraits)traits expectedResult:(NSString*)expectedResult
{
    UIView* view = nil;
    UIAccessibilityElement* element = nil;

    [self waitForAccessibilityElement:&element view:&view withLabelOrIdentifier:labelOrIdentifier value:nil traits:traits tappable:YES];
    [self tapAccessibilityElement:element inView:view];
    
    //wait for any other animations -- like searchbar etc
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);

    [self enterTextIntoCurrentFirstResponder:text fallbackView:view];

    // We will perform some additional validation if the view is UITextField or UITextView.
    if (![view respondsToSelector:@selector(text)])
    {
        return;
    }

    UITextView* textView = (UITextView*)view;

    // Some slower machines take longer for typing to catch up, so wait for a bit before failing
    [self runBlock:^KIFTestStepResult (NSError** error) {
         // We trim \n and \r because they trigger the return key, so they won't show up in the final product on single-line inputs
         NSString* expected = [expectedResult ? : text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
         NSString* actual = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

         KIFTestWaitCondition([actual isEqualToString:expected], error, @"Failed to get text \"%@\" in field; instead, it was \"%@\"", expected, actual);

         return KIFTestStepResultSuccess;
     } timeout:1.0];
}


- (void) clearTextFromViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier
{
    [self clearTextFromViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier traits:UIAccessibilityTraitNone];
}

- (void) clearTextFromViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier traits:(UIAccessibilityTraits)traits
{
    UIView* view = nil;
    UIAccessibilityElement* element = nil;

    [self waitForAccessibilityElement:&element view:&view withLabelOrIdentifier:labelOrIdentifier value:nil traits:traits tappable:YES];

    NSUInteger numberOfCharacters = [element respondsToSelector:@selector(text)] ? [(UITextField*)element text].length : element.accessibilityValue.length;

    NSMutableString* text = [NSMutableString string];
    for (NSInteger i = 0; i < numberOfCharacters; i++)
    {
        [text appendString:@"\b"];
    }

    [self enterText:text intoViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier traits:UIAccessibilityTraitNone expectedResult:@""];
}

- (void) clearTextFromAndThenEnterText:(NSString*)text intoViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier
{
    [self clearTextFromViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier];
    [self enterText:text intoViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier];
}

- (void) clearTextFromAndThenEnterText:(NSString*)text intoViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier traits:(UIAccessibilityTraits)traits expectedResult:(NSString*)expectedResult
{
    [self clearTextFromViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier traits:traits];
    [self enterText:text intoViewWithAccessibilityLabelOrIdentifier:labelOrIdentifier traits:traits expectedResult:expectedResult];
}

- (void) selectPickerViewRowWithTitle:(NSString*)title
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
         // Find the picker view
         UIPickerView* pickerView = [[[[UIApplication sharedApplication] pickerViewWindow] subviewsWithClassNameOrSuperClassNamePrefix:@"UIPickerView"] lastObject];
         KIFTestCondition(pickerView, error, @"No picker view is present");

         NSInteger componentCount = [pickerView.dataSource numberOfComponentsInPickerView:pickerView];
         //KIFTestCondition(componentCount == 1, error, @"The picker view has multiple columns, which is not supported in testing.");

         for (NSInteger componentIndex = 0; componentIndex < componentCount; componentIndex++)
         {
             NSInteger rowCount = [pickerView.dataSource pickerView:pickerView numberOfRowsInComponent:componentIndex];
             for (NSInteger rowIndex = 0; rowIndex < rowCount; rowIndex++)
             {
                 NSString* rowTitle = nil;
                 if ([pickerView.delegate respondsToSelector:@selector(pickerView:titleForRow:forComponent:)])
                 {
                     rowTitle = [pickerView.delegate pickerView:pickerView titleForRow:rowIndex forComponent:componentIndex];
                 }
                 else if ([pickerView.delegate respondsToSelector:@selector(pickerView:viewForRow:forComponent:reusingView:)])
                 {
                     // This delegate inserts views directly, so try to figure out what the title is by looking for a label
                     UIView* rowView = [pickerView.delegate pickerView:pickerView viewForRow:rowIndex forComponent:componentIndex reusingView:nil];
                     NSArray* labels = [rowView subviewsWithClassNameOrSuperClassNamePrefix:@"UILabel"];
                     UILabel* label = (labels.count > 0 ? labels[0] : nil);
                     rowTitle = label.text;
                 }

                 if ([rowTitle isEqual:title])
                 {
                     [pickerView selectRow:rowIndex inComponent:componentIndex animated:YES];
                     CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);

                     // Tap in the middle of the picker view to select the item
                     [pickerView tap];

                     // The combination of selectRow:inComponent:animated: and tap does not consistently result in
                     // pickerView:didSelectRow:inComponent: being called on the delegate. We need to do it explicitly.
                     if ([pickerView.delegate respondsToSelector:@selector(pickerView:didSelectRow:inComponent:)])
                     {
                         [pickerView.delegate pickerView:pickerView didSelectRow:rowIndex inComponent:componentIndex];
                     }

                     return KIFTestStepResultSuccess;
                 }
             }
         }

         KIFTestCondition(NO, error, @"Failed to find picker view value with title \"%@\"", title);
         return KIFTestStepResultFailure;
     }];
}

- (void) setOn:(BOOL)switchIsOn forSwitchWithAccessibilityLabel:(NSString*)label
{
    UIView* view = nil;
    UIAccessibilityElement* element = nil;

    [self waitForAccessibilityElement:&element view:&view withLabel:label value:nil traits:UIAccessibilityTraitNone tappable:YES];

    if (![view isKindOfClass:[UISwitch class]])
    {
        [self failWithError:[NSError KIFErrorWithFormat:@"View with accessibility label \"%@\" is a %@, not a UISwitch", label, NSStringFromClass([view class])] stopTest:YES];
    }

    UISwitch* switchView = (UISwitch*)view;

    // No need to switch it if it's already in the correct position
    if (switchView.isOn == switchIsOn)
    {
        return;
    }

    [self tapAccessibilityElement:element inView:view];

    // If we succeeded, stop the test.
    if (switchView.isOn == switchIsOn)
    {
        return;
    }

    NSLog(@"Faking turning switch %@ with accessibility label %@", switchIsOn ? @"ON" : @"OFF", label);
    [switchView setOn:switchIsOn animated:YES];
    [switchView sendActionsForControlEvents:UIControlEventValueChanged];
    [self waitForTimeInterval:0.5];

    // We gave it our best shot.  Fail the test.
    if (switchView.isOn != switchIsOn)
    {
        [self failWithError:[NSError KIFErrorWithFormat:@"Failed to toggle switch to \"%@\"; instead, it was \"%@\"", switchIsOn ? @"ON" : @"OFF", switchView.on ? @"ON" : @"OFF"] stopTest:YES];
    }
}

- (void) setValue:(float)value forSliderWithAccessibilityLabel:(NSString*)label
{
    UISlider* slider = nil;
    UIAccessibilityElement* element = nil;

    [self waitForAccessibilityElement:&element view:&slider withLabel:label value:nil traits:UIAccessibilityTraitNone tappable:YES];

    if (![slider isKindOfClass:[UISlider class]])
    {
        [self failWithError:[NSError KIFErrorWithFormat:@"View with accessibility label \"%@\" is a %@, not a UISlider", label, NSStringFromClass([slider class])] stopTest:YES];
    }

    if (value < slider.minimumValue)
    {
        [self failWithError:[NSError KIFErrorWithFormat:@"Cannot slide past minimum value of %f", slider.minimumValue] stopTest:YES];
    }

    if (value > slider.maximumValue)
    {
        [self failWithError:[NSError KIFErrorWithFormat:@"Cannot slide past maximum value of %f", slider.maximumValue] stopTest:YES];
    }

    CGRect  trackRect       = [slider trackRectForBounds:slider.bounds];
    CGPoint currentPosition = CGPointCenteredInRect([slider thumbRectForBounds:slider.bounds trackRect:trackRect value:slider.value]);
    CGPoint finalPosition   = CGPointCenteredInRect([slider thumbRectForBounds:slider.bounds trackRect:trackRect value:value]);

    [slider dragFromPoint:currentPosition toPoint:finalPosition steps:10];
}

- (void) dismissPopover
{
    const NSTimeInterval tapDelay = 0.05;
    UIWindow* window = [[UIApplication sharedApplication] dimmingViewWindow];

    if (!window)
    {
        [self failWithError:[NSError KIFErrorWithFormat:@"Failed to find any dimming views in the application"] stopTest:YES];
    }
    UIView* dimmingView = [[window subviewsWithClassNamePrefix:@"UIDimmingView"] lastObject];
    [dimmingView tapAtPoint:CGPointMake(50.0f, 50.0f)];
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, tapDelay, false);
}

- (void) choosePhotoInAlbum:(NSString*)albumName atRow:(NSInteger)row column:(NSInteger)column
{
    [self tapViewWithAccessibilityLabel:@"Choose Photo"];

    // This is basically the same as the step to tap with an accessibility label except that the accessibility labels for the albums have the number of photos appended to the end, such as "My Photos (3)." This means that we have to do a prefix match rather than an exact match.
    [self runBlock:^KIFTestStepResult (NSError** error) {
         NSString* labelPrefix = [NSString stringWithFormat:@"%@,   (", albumName];
         UIAccessibilityElement* element = [[UIApplication sharedApplication] accessibilityElementMatchingBlock:^(UIAccessibilityElement* element) {
                                                return [element.accessibilityLabel hasPrefix:labelPrefix];
                                            }];

         KIFTestWaitCondition(element, error, @"Failed to find photo album with name %@", albumName);

         UIView* view = [UIAccessibilityElement viewContainingAccessibilityElement:element];
         KIFTestWaitCondition(view, error, @"Failed to find view for photo album with name %@", albumName);

         if (![view isUserInteractionActuallyEnabled])
         {
             if (error)
             {
                 *error = [NSError KIFErrorWithFormat:@"Album picker is not enabled for interaction"];
             }
             return KIFTestStepResultWait;
         }

         CGRect elementFrame = [view.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:view];
         CGPoint tappablePointInElement = [view tappablePointInRect:elementFrame];

         [view tapAtPoint:tappablePointInElement];

         return KIFTestStepResultSuccess;
     }];

    // Wait for media picker view controller to be pushed.
    [self waitForTimeInterval:0.5];

    // Tap the desired photo in the grid
    // TODO: This currently only works for the first page of photos. It should scroll appropriately at some point.
    const CGFloat headerHeight    = 64.0;
    const CGSize  thumbnailSize   = CGSizeMake(75.0, 75.0);
    const CGFloat thumbnailMargin = 5.0;
    CGPoint       thumbnailCenter;
    thumbnailCenter.x = thumbnailMargin + (MAX(0, column - 1) * (thumbnailSize.width + thumbnailMargin)) + thumbnailSize.width / 2.0;
    thumbnailCenter.y = headerHeight + thumbnailMargin + (MAX(0, row - 1) * (thumbnailSize.height + thumbnailMargin)) + thumbnailSize.height / 2.0;
    [self tapScreenAtPoint:thumbnailCenter];

    // Dismiss the resize UI
    [self tapViewWithAccessibilityLabel:@"Choose"];
}

- (void) tapRowInTableViewWithAccessibilityLabel:(NSString*)tableViewLabel atIndexPath:(NSIndexPath*)indexPath
{
    UITableView* tableView = (UITableView*)[self waitForViewWithAccessibilityLabel:tableViewLabel];

    if (![tableView isKindOfClass:[UITableView class]])
    {
        [self failWithError:[NSError KIFErrorWithFormat:@"View is not a table view"] stopTest:YES];
    }

    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

    // If section < 0, search from the end of the table.
    if (indexPath.section < 0)
    {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:tableView.numberOfSections + indexPath.section];
    }

    // If row < 0, search from the end of the section.
    if (indexPath.row < 0)
    {
        indexPath = [NSIndexPath indexPathForRow:[tableView numberOfRowsInSection:indexPath.section] + indexPath.row inSection:indexPath.section];
    }

    if (!cell)
    {
        if (indexPath.section >= tableView.numberOfSections)
        {
            [self failWithError:[NSError KIFErrorWithFormat:@"Section %d is not found in '%@' table view", indexPath.section, tableViewLabel] stopTest:YES];
        }

        if (indexPath.row >= [tableView numberOfRowsInSection:indexPath.section])
        {
            [self failWithError:[NSError KIFErrorWithFormat:@"Row %d is not found in section %d of '%@' table view", indexPath.row, indexPath.section, tableViewLabel] stopTest:YES];
        }

        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        [self waitForTimeInterval:0.5];
        cell = [tableView cellForRowAtIndexPath:indexPath];
    }

    if (!cell)
    {
        [self failWithError:[NSError KIFErrorWithFormat:@"Table view cell at index path %@ not found", indexPath] stopTest:YES];
    }

    CGRect cellFrame = [cell.contentView convertRect:cell.contentView.frame toView:tableView];
    [tableView tapAtPoint:CGPointCenteredInRect(cellFrame)];
}

- (void) swipeViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier inDirection:(KIFSwipeDirection)direction
{
    UIView* viewToSwipe;
    UIAccessibilityElement* element;

    [self waitForAccessibilityElement:&element view:&viewToSwipe withLabelOrIdentifier:labelOrIdentifier value:nil traits:UIAccessibilityTraitNone tappable:NO];

    KIFDisplacement swipeDisplacement = KIFDisplacementForSwipingInDirection(direction);
    [self swipeView:viewToSwipe element:element inDirection:direction startLocation:KIFViewLocationCenter swipeDisplacement:swipeDisplacement];
}

- (void) swipeViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier inDirection:(KIFSwipeDirection)direction startLocation:(KIFViewLocation)startLocation
{
    UIView* viewToSwipe;
    UIAccessibilityElement* element;

    [self waitForAccessibilityElement:&element view:&viewToSwipe withLabelOrIdentifier:labelOrIdentifier value:nil traits:UIAccessibilityTraitNone tappable:NO];
    KIFDisplacement swipeDisplacement = KIFDisplacementForSwipingInDirection(direction);
    [self swipeView:viewToSwipe element:element inDirection:direction startLocation:startLocation swipeDisplacement:swipeDisplacement];
}

- (void) swipeViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier inDirection:(KIFSwipeDirection)direction startLocation:(KIFViewLocation)startLocation byFractionOfSizeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction
{
    UIView* viewToSwipe;
    UIAccessibilityElement* element;

    [self waitForAccessibilityElement:&element view:&viewToSwipe withLabelOrIdentifier:labelOrIdentifier value:nil traits:UIAccessibilityTraitNone tappable:NO];

    KIFDisplacement swipeDisplacement = KIFDisplacementForSwipingInDirectionByPoints(direction, horizontalFraction*viewToSwipe.frame.size.width, verticalFraction*viewToSwipe.frame.size.height);

    [self swipeView:viewToSwipe element:element inDirection:direction startLocation:startLocation swipeDisplacement:swipeDisplacement];
}

- (void) swipeViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier inDirection:(KIFSwipeDirection)direction startLocation:(KIFViewLocation)startLocation byFractionOfSizeToWindowEdgeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction
{
    UIView* viewToSwipe;
    UIAccessibilityElement* element;

    [self waitForAccessibilityElement:&element view:&viewToSwipe withLabelOrIdentifier:labelOrIdentifier value:nil traits:UIAccessibilityTraitNone tappable:NO];

    CGRect  elementFrame = [viewToSwipe.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:viewToSwipe];
    CGPoint swipeStart   = CGPointFromViewLocationPointAndRect(startLocation, elementFrame);
    CGPoint swipeStartInWindow = [viewToSwipe convertPoint:swipeStart toView:viewToSwipe.windowOrIdentityWindow];
    
    CGPoint edgeLocation = CGPointZero;
    CGRect  windowFrame  = viewToSwipe.windowOrIdentityWindow.frame;
    switch (direction)
    {
        case KIFSwipeDirectionRight:
            edgeLocation = CGPointMake(windowFrame.size.width, swipeStartInWindow.y);
            break;
        case KIFSwipeDirectionUp:
            edgeLocation = CGPointMake(swipeStartInWindow.x, 0);
            break;
        case KIFSwipeDirectionLeft:
            edgeLocation = CGPointMake(0, swipeStartInWindow.y);
            break;
        case KIFSwipeDirectionDown:
            edgeLocation = CGPointMake(swipeStartInWindow.x, windowFrame.size.height);
            break;
        default:
            break;
    }

    KIFDisplacement swipeDisplacement = KIFDisplacementForSwipingInDirectionByPoints(direction, fabs(swipeStartInWindow.x-edgeLocation.x)*horizontalFraction, fabs(swipeStartInWindow.y-edgeLocation.y)*verticalFraction);

    [self swipeView:viewToSwipe element:element inDirection:direction startLocation:startLocation swipeDisplacement:swipeDisplacement];
}

- (void) swipeView:(UIView*)viewToSwipe element:(UIAccessibilityElement*)element inDirection:(KIFSwipeDirection)direction startLocation:(KIFViewLocation)startLocation swipeDisplacement:(KIFDisplacement)swipeDisplacement
{
    const NSUInteger kNumberOfPointsInSwipePath = 20;

    // The original version of this came from http://groups.google.com/group/kif-framework/browse_thread/thread/df3f47eff9f5ac8c

    // Within this method, all geometry is done in the coordinate system of the view to swipe.
    CGRect  elementFrame = [viewToSwipe.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:viewToSwipe];
    CGPoint swipeStart   = CGPointFromViewLocationPointAndRect(startLocation, elementFrame);

    [viewToSwipe dragFromPoint:swipeStart displacement:swipeDisplacement steps:kNumberOfPointsInSwipePath];
}

- (void) scrollViewWithAccessbilityLabelOrIdentifier:(NSString*)identifierToScroll toViewWithAccessibilityLabelOrIdentifier:(NSString*)labelToScrollTo
{
    UIScrollView* scrollView = (id)[self waitForViewWithAccessibilityLabelOrIdentifier:identifierToScroll];
    CGFloat       direction  = -0.5;      //SCROLL DOWN
    BOOL    elementOnScreen  = NO;
    CGPoint lastOffset       = scrollView.contentOffset;
    NSError* error = nil;
    BOOL scrolled = NO;
    
    NSUInteger directionChanges = 0;
    
    while (!elementOnScreen)
    {
        UIAccessibilityElement* elementToScrollTo = (id)[UIAccessibilityElement accessibilityElementWithLabelOrIdentifier:labelToScrollTo error:&error];

        if (elementToScrollTo)
        {
            //access frame doesn't account for device orientation so convert...
            CGRect accessibilityFrame = [scrollView.window convertRect:elementToScrollTo.accessibilityFrame toView:scrollView];
            direction       = (accessibilityFrame.origin.y - scrollView.contentOffset.y > scrollView.frame.size.height - accessibilityFrame.size.height ? -0.5 : 0.5);
            elementOnScreen = (accessibilityFrame.origin.y >= 0.0
                               && accessibilityFrame.origin.y - scrollView.contentOffset.y <= scrollView.frame.size.height - accessibilityFrame.size.height
                               && accessibilityFrame.origin.y - scrollView.contentOffset.y >= 0.0);
        }

        if (!elementToScrollTo || (elementToScrollTo && !elementOnScreen))
        {

            if (directionChanges > 5) //we got stuck
            {
                //wait for the scroll animation to complete...
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);
                directionChanges = 0;
            }
            [self scrollViewWithAccessibilityLabelOrIdentifier:scrollView.accessibilityIdentifier byFractionOfSizeHorizontal:0.0 vertical:direction]; //if try for a 100% then it fails to scroll
            scrolled = YES;
            //if we are not moving, try the other direction.
            if (lastOffset.y == scrollView.contentOffset.y && lastOffset.x == scrollView.contentOffset.x)
            {
                direction = -direction;
                directionChanges++;
            }

            lastOffset = scrollView.contentOffset;
        }
    }

    if (scrolled)
    {
        //wait for the scroll animation to complete...
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);
    }
    [self waitForViewWithAccessibilityLabelOrIdentifier:labelToScrollTo];
}

- (void) scrollViewWithAccessibilityLabelOrIdentifier:(NSString*)labelOrIdentifier byFractionOfSizeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction
{
    const NSUInteger kNumberOfPointsInScrollPath = 5;

    UIView* viewToScroll;
    UIAccessibilityElement* element;

    [self waitForAccessibilityElement:&element view:&viewToScroll withLabelOrIdentifier:labelOrIdentifier value:Nil traits:UIAccessibilityTraitNone tappable:NO];

    // Within this method, all geometry is done in the coordinate system of the view to scroll.

    CGRect elementFrame = [viewToScroll.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:viewToScroll];

    KIFDisplacement scrollDisplacement = CGPointMake(elementFrame.size.width * horizontalFraction, elementFrame.size.height * verticalFraction);

    CGPoint scrollStart = CGPointCenteredInRect(elementFrame);
    scrollStart.x -= scrollDisplacement.x / 2;
    scrollStart.y -= scrollDisplacement.y / 2;

    NSLog (@"SCROLL START: %f,%f", scrollStart.x, scrollStart.y);
    NSLog (@"SCROLL DISTANCE: %f,%f", scrollDisplacement.x, scrollDisplacement.y);

    [viewToScroll dragFromPoint:scrollStart displacement:scrollDisplacement steps:kNumberOfPointsInScrollPath];
}

- (void) waitForFirstResponderWithAccessibilityLabel:(NSString*)label
{
    [self runBlock:^KIFTestStepResult (NSError** error) {
         UIResponder* firstResponder = [[[UIApplication sharedApplication] keyWindow] firstResponder];
         if ([firstResponder isKindOfClass:NSClassFromString(@"UISearchBarTextField")])
         {
             firstResponder = [(UIView*)firstResponder superview];
         }
         KIFTestWaitCondition([[firstResponder accessibilityLabel] isEqualToString:label], error, @"Expected accessibility label for first responder to be '%@', got '%@'", label, [firstResponder accessibilityLabel]);

         return KIFTestStepResultSuccess;
     }];
}

@end

