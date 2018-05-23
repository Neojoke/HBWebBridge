//
//  HBWKWebViewController.m
//  HBWebBridge_Example
//
//  Created by Neo on 2018/5/22.
//  Copyright © 2018年 394570610@qq.com. All rights reserved.
//

#import "HBWKWebViewController.h"
#import <WebKit/WebKit.h>
#import <HBWebBridge/HBWebBridge.h>
@interface HBWKWebViewController ()<WKScriptMessageHandler,WKNavigationDelegate>
@property(nonatomic)WKWebView * webView;
@end

@implementation HBWKWebViewController
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;{
    id body = message.body;
    if([body isKindOfClass:[NSDictionary class]]){
        NSDictionary * requestDict = (NSDictionary *)body;
        NSString * method = [requestDict objectForKey:@"Method"];
        id params = [requestDict objectForKey:@"Data"];
        NSString * callBackName = [requestDict objectForKey:@"CB_iOS"];
        NSString * callBackFuncName = [NSString stringWithFormat:@"window.%@",callBackName];
        NSString * errorMsg = @"";
        if ([errorMsg isKindOfClass:[NSString class]]) {
            if (errorMsg.length == 0) {
                errorMsg = @"null";
            }
        }
        else if (errorMsg ==nil){
            errorMsg = @"null";
        }
        else{
            errorMsg = [errorMsg description];
        }
        NSDictionary *resultData = @{@"result":@"success"};
        resultData = @{@"result":resultData};
        NSString * resultDataString = [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:resultData options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
        NSString * javaScript = [NSString stringWithFormat:@"%@(%@,'%@');",callBackFuncName,errorMsg,resultDataString];
//        javaScript = [javaScript stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
        javaScript = [javaScript stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        javaScript = [javaScript stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
        javaScript = [javaScript stringByReplacingOccurrencesOfString:@"\r" withString:@""];

        [message.webView evaluateJavaScript:javaScript completionHandler:^(id _Nullable o, NSError * _Nullable error) {
            NSLog(@"%@",error);
        }];
    }
    else{
        
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc]init];
    WKUserContentController * user_controller = [[WKUserContentController alloc]init];
    configuration.userContentController = user_controller;
    CGRect react = [UIScreen mainScreen].bounds;
    self.webView = [[WKWebView alloc]initWithFrame:react configuration:configuration];
    [self.view addSubview:self.webView];
    HBWebBridge * bridge = [[HBWebBridge alloc]init];
    [bridge addActionHandler:@"Hello" forCallBack:^(NSDictionary *params, HBWebBridgeErrorCallBack errorCallBack, HBWebBridgeSuccessCallBack successCallBack) {
        NSLog(@"%@",params);
        successCallBack(@{@"123":@"3123"});
    }];
    [bridge addActionHandler:@"Error" forCallBack:^(NSDictionary *params, HBWebBridgeErrorCallBack errorCallBack, HBWebBridgeSuccessCallBack successCallBack) {
        errorCallBack([NSError errorWithDomain:@"1123" code:255555 userInfo:nil]);
    }];
    [user_controller addScriptMessageHandler:bridge name:@"hb_mb_bridge"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8000/#/"]]];
    self.webView.navigationDelegate = self;
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://10.0.31.133:8000/#/"]]];

    // Do any additional setup after loading the view.
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation;
{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
