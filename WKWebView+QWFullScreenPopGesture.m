//
//  WKWebView+QWFullScreenPopGesture.m
//  ProCalendar
//
//  Created by 505 on 2018/3/21.
//  Copyright © 2018年 Quickwis. All rights reserved.
//

#import "WKWebView+QWFullScreenPopGesture.h"
#import <objc/runtime.h>
//#import "NSObject+SXRuntime.h"


@interface _QWFullScreenPopGestureDelegate : NSObject <UIGestureRecognizerDelegate>

@property (weak,nonatomic) WKWebView * webView;

@end

@implementation _QWFullScreenPopGestureDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer{
    //不可返回时忽略
    if (![self.webView canGoBack]) {
        return NO;
    }
    
    //禁止滑动手势时禁用
    if (!self.webView.allowsBackForwardNavigationGestures) {
        return NO;
    }
    
    //禁止水平向右以外的滑动
    CGPoint translation = [gestureRecognizer translationInView:self.webView];
    CGFloat absX = fabs(translation.x);
    CGFloat absY = fabs(translation.y);
    
    if (absX > absY ) { //水平滑动
        if (translation.x<0) {
            //向左滑动
            return NO;
        }
    } else if (absX < absY ){//纵向滑动
        return NO;
    }
    return YES;
}

@end



@implementation WKWebView (QWFullScreenPopGesture)


+ (void)load{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        [self swizzleInstanceMethodWithOriginSel:@selector(loadRequest:)
                                     swizzledSel:@selector(qw_loadRequest:)];
        
        [self swizzleInstanceMethodWithOriginSel:@selector(loadHTMLString:baseURL:)
                                     swizzledSel:@selector(qw_loadHTMLString:baseURL:)];
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
            [self swizzleInstanceMethodWithOriginSel:@selector(loadFileURL:allowingReadAccessToURL:)
                                         swizzledSel:@selector(qw_loadFileURL:allowingReadAccessToURL:)];
            
            [self swizzleInstanceMethodWithOriginSel:@selector(loadData:MIMEType:characterEncodingName:baseURL:)
                                         swizzledSel:@selector(qw_loadData:MIMEType:characterEncodingName:baseURL:)];
        }
        
    });
}

+ (void)swizzleInstanceMethodWithOriginSel:(SEL)originalSelector swizzledSel:(SEL)swizzledSelector{
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (WKNavigation *)qw_loadRequest:(NSURLRequest *)request{
    [self checkGestureIsAdded];
    return [self qw_loadRequest:request];
}

- (WKNavigation *)qw_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL{
    [self checkGestureIsAdded];
    return [self qw_loadHTMLString:string baseURL:baseURL];
}

- (WKNavigation *)qw_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL{
    [self checkGestureIsAdded];
    return [self qw_loadFileURL:URL allowingReadAccessToURL:readAccessURL];
}

- (WKNavigation *)qw_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL{
    [self checkGestureIsAdded];
    return [self qw_loadData:data MIMEType:MIMEType characterEncodingName:characterEncodingName baseURL:baseURL];
}



- (void)checkGestureIsAdded{
    if (![self.gestureRecognizers containsObject:self.qw_fullscreenPopGestureRecognizer]) {
        
        //self.gestureRecognizers一共两个手势
        //firstObject是向右滑动返回的手势(UIScreenEdgePanGesture)，lastObject是向左滑动前进的手势
        UIPanGestureRecognizer * originEdgeRecognizer = self.gestureRecognizers.firstObject;
        
        // Add our own gesture recognizer to where the onboard screen edge pan gesture recognizer is attached to.
        [originEdgeRecognizer.view addGestureRecognizer:self.qw_fullscreenPopGestureRecognizer];
        
        // Forward the gesture events to the private handler of the onboard gesture recognizer.
        NSArray *internalTargets = [originEdgeRecognizer valueForKey:@"_targets"];
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
        if (originEdgeRecognizer.delegate) {
            self.qw_fullscreenPopGestureRecognizer.delegate = self.qw_popGestureRecognizerDelegate;
        }
        [self.qw_fullscreenPopGestureRecognizer addTarget:internalTarget action:internalAction];
        
        // Disable the onboard gesture recognizer.
        originEdgeRecognizer.enabled = NO;
    }
}

- (UIPanGestureRecognizer *)qw_fullscreenPopGestureRecognizer{
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);
    if (!panGestureRecognizer) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}

- (_QWFullScreenPopGestureDelegate *)qw_popGestureRecognizerDelegate{
    _QWFullScreenPopGestureDelegate *delegate = objc_getAssociatedObject(self, _cmd);
    
    if (!delegate) {
        delegate = [[_QWFullScreenPopGestureDelegate alloc] init];
        delegate.webView = self;
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}


@end
