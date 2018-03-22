# QWWebViewFullScreenPopGesture
An WKWebView's category to enable fullscreen pop gesture in an iOS8+ system style with AOP.

OverView
== 
![overview gif](https://github.com/PandexLee/QWWebViewFullScreenPopGesture/blob/master/QWWebViewFullScreenPopGesture.gif)   

项目中同时用了 forkingdog/FDFullscreenPopGesture 和 WKWebView。  
WKWebView是自带屏幕边缘滑动返回手势的，所有为了统一交互体验，   
我仿照 FDFullscreenPopGesture 为 WKWebView 写一个支持全屏滑动返回上一个页面的分类。 

Usage
==
使用时只需要把文件分类加入工程即可，不需要做其他任何操作    

想禁止个别 WKWebView 的手势可直接调用    
```
webView.allowsBackForwardNavigationGestures;
```

配合 FDFullscreenPopGesture 使用时要依赖手势  
```
UIGestureRecognizer * navGesture = self.navigationController.fd_fullscreenPopGestureRecognizer;  
[navGesture requireGestureRecognizerToFail:self.webView.qw_fullscreenPopGestureRecognizer];
```
    
支持 iOS 8+
