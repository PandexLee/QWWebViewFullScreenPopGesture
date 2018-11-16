# QWWebViewFullScreenPopGesture
A WKWebView's category to enable fullscreen back/forward gesture in an iOS8+ system style with AOP.         
0代码实现 WKWebView 滑动手势全屏返回和前进

OverView
== 
![overview gif](https://s19.aconvert.com/convert/p3r68-cdx67/pg1p6-jwsh6.gif)   

项目中同时用了 [forkingdog/FDFullscreenPopGesture](https://github.com/forkingdog/FDFullscreenPopGesture) 和 WKWebView。  
WKWebView是自带屏幕边缘滑动返回/前进手势的，为了统一交互体验，   
我仿照 FDFullscreenPopGesture 为 WKWebView 写一个支持全屏滑动返回上一个页面的分类。     
目前默认支持全屏右滑返回和全屏左滑前进
    
    
    
Usage
==
使用时只需要把文件分类加入工程即可，不需要做其他任何操作    

想禁止个别 WKWebView 的手势可直接调用，不需要导入头文件    
```
webView.allowsBackForwardNavigationGestures = NO;
```

配合 FDFullscreenPopGesture 使用时要依赖手势  
```
MYViewController.m  
    
- (void)viewDidLoad {   
    [super viewDidLoad];    
    UIGestureRecognizer * navGesture = self.navigationController.fd_fullscreenPopGestureRecognizer;  
    [navGesture requireGestureRecognizerToFail:self.webView.qw_fullscreenPopGestureRecognizer]; 
}
```
    
支持 iOS 8+
