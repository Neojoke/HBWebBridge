# HBWebBridge

[![CI Status](http://img.shields.io/travis/394570610@qq.com/HBWebBridge.svg?style=flat)](https://travis-ci.org/394570610@qq.com/HBWebBridge)
[![Version](https://img.shields.io/cocoapods/v/HBWebBridge.svg?style=flat)](http://cocoapods.org/pods/HBWebBridge)
[![License](https://img.shields.io/cocoapods/l/HBWebBridge.svg?style=flat)](http://cocoapods.org/pods/HBWebBridge)
[![Platform](https://img.shields.io/cocoapods/p/HBWebBridge.svg?style=flat)](http://cocoapods.org/pods/HBWebBridge)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
JavaScriptCore

## Installation

HBWebBridge is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'HBWebBridge'
```

## Author

394570610@qq.com, wupeng@touker.com

## License

HBWebBridge is available under the MIT license. See the LICENSE file for more info.


## Useage

1. 继承HBWebBridge

```
@interface HBTestWebViewBridge:HBWebBridge
@end
@implementation HBTestWebViewBridge
@end
```

2. 定义一个对外开放的JSExport协议
```
@protocol HBTestWebViewBridgeExport<JSExport>
/**
以下两个方法必须存在
*/
JSExportAs(callRouter, -(void)callRouter:(JSValue *)requestObject callBack:(JSValue *)callBack);
JSExportAs(callRouterSync,-(JSValue *)callRouterSync:(JSValue*)requestObject);
@end
```

3. 遵守协议

```
@interface HBTestWebViewBridge:HBWebBridge<HBTestWebViewBridgeExport>
```

4. 在捕获WebView的JSContext对象的时候，实例化bridge

```
self.context = [self.webview valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
self.bridge = [[HBTestWebViewBridge alloc]init];
[self.bridge addActionHandler:@"helloworld" forCallBack:^(NSDictionary *params, HBWebBridgeErrorCallBack errorCallBack, HBWebBridgeSuccessCallBack successCallBack) {
successCallBack(@{@"back":@"hi,you!"});
}];
[self.bridge addSyncActionHandler:@"sync" forCallBack:^NSDictionary *(NSDictionary *params) {
return @{@"result":@{}};
}];
self.context[@"bridge"] = self.bridge;
```

5. 添加异步方法

```

//异步方法，保证最后调用successCallBack或者errorCallBack
[self.bridge addActionHandler:@"helloworld" forCallBack:^(NSDictionary *params, HBWebBridgeErrorCallBack errorCallBack, HBWebBridgeSuccessCallBack successCallBack) {
successCallBack(@{@"back":@"hi,you!"});
}];
```

6. 添加同步方法

```
//返回一个字典
[self.bridge addSyncActionHandler:@"sync" forCallBack:^NSDictionary *(NSDictionary *params) {
return @{@"result":@{}};
}];
```
