//
//  WKWebView+QWFullScreenPopGesture.m
//  ProCalendar
//
//  Created by Pandex on 2018/3/21.
//  Copyright © 2018年 Quickwis. All rights reserved.
//

#import "WKWebView+QWFullScreenPopGesture.h"
#import <objc/runtime.h>

@interface _QWFullScreenPopGestureDelegate : NSObject <UIGestureRecognizerDelegate>

// 弱引用控件，避免循环引用
@property (weak,nonatomic) WKWebView * webView;
@property (weak,nonatomic) UIPanGestureRecognizer * leftGes;
@property (weak,nonatomic) UIPanGestureRecognizer * rightGes;

@end

@implementation _QWFullScreenPopGestureDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer{
    //不可返回时忽略左侧手势
    if (![self.webView canGoBack] && [gestureRecognizer isEqual:self.leftGes]) {
        return NO;
    }else if (![self.webView canGoForward] && [gestureRecognizer isEqual:self.rightGes]){
        //不可前进时忽略右侧手势
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
        if (translation.x < 0 && [gestureRecognizer isEqual:self.leftGes]) {
            //禁止左侧手势向左滑动
            return NO;
        }else if (translation.x > 0 && [gestureRecognizer isEqual:self.rightGes]){
            //禁止右侧手势向右滑动
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
        
        if (DEVICE_iOS_9) {
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
    //self.gestureRecognizers一共两个手势
    //firstObject是向右滑动返回的手势(UIScreenEdgePanGesture)，lastObject是向左滑动前进的手势
    //避免后面添加了自定义手势造成顺序问题，先引用自带的两个手势
    UIPanGestureRecognizer * originEdgeRecognizer = self.gestureRecognizers.firstObject;
    UIPanGestureRecognizer * originRightEdgeRecognizer = self.gestureRecognizers.lastObject;
    if (![self.gestureRecognizers containsObject:self.qw_fullscreenPopGestureRecognizer] &&
        ![self.gestureRecognizers containsObject:self.qw_fullscreenRightPopGestureRecognizer]) {
        //添加左侧手势
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
        
        //添加右侧手势
        [originRightEdgeRecognizer.view addGestureRecognizer:self.qw_fullscreenRightPopGestureRecognizer];
        
        // Forward the gesture events to the private handler of the onboard gesture recognizer.
        NSArray *internalRightTargets = [originRightEdgeRecognizer valueForKey:@"_targets"];
        id internalRightTarget = [internalRightTargets.firstObject valueForKey:@"target"];
        SEL internalRightAction = NSSelectorFromString(@"handleNavigationTransition:");
        if (originRightEdgeRecognizer.delegate) {
            self.qw_fullscreenRightPopGestureRecognizer.delegate = self.qw_popGestureRecognizerDelegate;
        }
        [self.qw_fullscreenRightPopGestureRecognizer addTarget:internalRightTarget action:internalRightAction];
        
        // Disable the onboard gesture recognizer.
        originRightEdgeRecognizer.enabled = NO;

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

- (UIPanGestureRecognizer *)qw_fullscreenRightPopGestureRecognizer{
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
        delegate.leftGes = self.qw_fullscreenPopGestureRecognizer;
        delegate.rightGes = self.qw_fullscreenRightPopGestureRecognizer;
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}


@end
