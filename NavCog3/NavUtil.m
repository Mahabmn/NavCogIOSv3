/*******************************************************************************
 * Copyright (c) 2014, 2015  IBM Corporation, Carnegie Mellon University and others
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *******************************************************************************/

#import "NavUtil.h"

@implementation UIMessageView

@end

@implementation NavUtil

static NSMutableDictionary<NSString*, UIView*>* waitingViewMap;
static NSMutableDictionary<NSString*, UIView*>* messageViewMap;

+(void)showModalWaitingWithMessage:(NSString *)message
{
    UIView *view = [[[[UIApplication sharedApplication] delegate] window] subviews][0];
    [NavUtil showWaitingForView:view withMessage:message];
}

+(void)hideModalWaiting
{
    UIView *view = [[[[UIApplication sharedApplication] delegate] window] subviews][0];
    [NavUtil hideWaitingForView:view];
}

+(void)showWaitingForView:(UIView*)view withMessage:(NSString *)message
{
    NSString *address = [NSString stringWithFormat:@"%ld", (long) view];
    if (waitingViewMap && waitingViewMap[address]) {
        [waitingViewMap[address].subviews[1] setText:message];
        return;
    }
    
    UIView *overlay = [[UIView alloc]initWithFrame:view.frame];
    
    CGFloat w = view.frame.size.width;
    CGFloat h = view.frame.size.height;
    CGFloat size = 30;
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((w-size)/2, (h-size)/2, size, size)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, (h+size)/2+size, w, size*5)];
    label.text = message;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    label.numberOfLines = 0;
    
    [overlay setBackgroundColor:
     [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    [overlay addSubview:indicator];
    [overlay addSubview:label];
    [indicator startAnimating];

    //TODO change view for purpose
    //[[[[[UIApplication sharedApplication] delegate] window] subviews][0] addSubview:overlay];
    
    [view addSubview:overlay];
    
    [overlay setIsAccessibilityElement:YES];
    [overlay setAccessibilityLabel:message];
    
    if (!waitingViewMap) {
        waitingViewMap = [@{} mutableCopy];
    }
    [waitingViewMap setObject:overlay forKey:address];
}

+(void)hideWaitingForView:(UIView*)view
{
    NSString *address = [NSString stringWithFormat:@"%ld", (long) view];
    UIView *overlay = waitingViewMap[address];
    if (overlay) {
        [overlay removeFromSuperview];
        [waitingViewMap removeObjectForKey:address];
    }
}

+(UIMessageView*)showMessageView:(UIView *)view
{
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    CGFloat w = view.frame.size.width;
    CGFloat y = statusBarHeight + 44;
    CGFloat size = 60;
    
    UIMessageView *overlay = [[UIMessageView alloc]initWithFrame:CGRectMake(0, y, w, size)];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, w-size, size)];
    label.text = @"Log Replaying";
    label.font = [UIFont fontWithName:@"Courier" size:14];
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(w-size, 0, size, size)];
    [btn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    
    [overlay setBackgroundColor:
     [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
    [overlay addSubview:label];
    [overlay addSubview:btn];
    
    [view addSubview:overlay];
    
    if (!messageViewMap) {
        messageViewMap = [@{} mutableCopy];
    }

    [messageViewMap setObject:overlay forKey:[NSString stringWithFormat:@"%ld", (long) view]];
    
    overlay.message = label;
    overlay.action = btn;
    return overlay;
}
+(void)hideMessageView:(UIView *)view
{
    NSString *address = [NSString stringWithFormat:@"%ld", (long) view];
    id overlay = messageViewMap[address];
    [overlay removeFromSuperview];
}

@end
