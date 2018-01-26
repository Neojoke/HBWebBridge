//
//  HBViewController.m
//  HBWebBridge
//
//  Created by 394570610@qq.com on 11/16/2017.
//  Copyright (c) 2017 394570610@qq.com. All rights reserved.
//

#import "HBViewController.h"
#import <HBWebBridge/HBWebBridge.h>
@protocol HBTestWebViewBridgeExport<JSExport>
/**
 对JavaScript开放的接口，详情参照wiki文档说明
 
 @param requestObject 包含{"Method":"","Data":""}标准对象
 @param callBack JavaScript传入的回调函数
 */
JSExportAs(callRouter, -(void)callRouter:(JSValue *)requestObject callBack:(JSValue *)callBack);
JSExportAs(callRouterSync,-(JSValue *)callRouterSync:(JSValue*)requestObject);
@end
@interface HBTestWebViewBridge:HBWebBridge<HBTestWebViewBridgeExport>
@end
@implementation HBTestWebViewBridge
@end
@interface HBViewController ()<UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webview;
@property(nonatomic,strong)JSContext * context;
@property(nonatomic,strong)HBTestWebViewBridge * bridge;
@end

@implementation HBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureJSContext) name:@"DidCreateContextNotification" object:nil];
    self.webview.delegate = self;
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://10.0.31.133:8000/#/"]]];

	// Do any additional setup after loading the view, typically from a nib.
}
-(void)captureJSContext{
    self.context = [self.webview valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.bridge = [[HBTestWebViewBridge alloc]init];
    [self.bridge addActionHandler:@"helloworld" forCallBack:^(NSDictionary *params, HBWebBridgeErrorCallBack errorCallBack, HBWebBridgeSuccessCallBack successCallBack) {
        successCallBack(@{@"back":@"hi,you!"});
    }];
    [self.bridge addSyncActionHandler:@"sync" forCallBack:^NSDictionary *(NSDictionary *params) {
        return @{@"result":@{}};
    }];
    self.context[@"hb_mb_bridge"] = self.bridge;
}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
    
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
@implementation NSObject (hb_uiwebViewDelegator)

- (void)webView:(id)unuse didCreateJavaScriptContext:(JSContext *)ctx forFrame:(id)frame {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DidCreateContextNotification" object:ctx];
}

@end

