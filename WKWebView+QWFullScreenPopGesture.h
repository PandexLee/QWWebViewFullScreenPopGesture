//
//  WKWebView+QWFullScreenPopGesture.h
//  ProCalendar
//
//  Created by 505 on 2018/3/21.
//  Copyright © 2018年 Quickwis. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKWebView (QWFullScreenPopGesture)

@property (nonatomic, strong, readonly) UIPanGestureRecognizer *qw_fullscreenPopGestureRecognizer;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *qw_fullscreenRightPopGestureRecognizer;


@end
