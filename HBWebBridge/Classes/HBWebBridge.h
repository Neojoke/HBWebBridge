//
//  HBWebBridge.h
//  CocoaLumberjack
//
//  Created by Neo on 2017/11/16.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>
#define HBWebBridgeDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)
typedef void(^HBWebBridgeErrorCallBack)(NSError * error);
typedef void(^HBWebBridgeSuccessCallBack)(NSDictionary * responseDict);
typedef NSDictionary *(^HBWebBridgeHandlerSyncCallBack)(NSDictionary *);
typedef void(^HBWebBridgeHandlerCallBack)(NSDictionary * params,HBWebBridgeErrorCallBack errorCallBack,HBWebBridgeSuccessCallBack successCallBack);
@interface HBWebBridge : NSObject<WKScriptMessageHandler>
@property(nonatomic,strong)NSMutableDictionary * handlers;
@property(nonatomic,strong)NSMutableDictionary * syncHandlers;

/**
 对JavaScript开放的接口，详情参照wiki文档说明
 
 @param requestObject 包含{"Method":"","Data":""}标准对象
 @param callBack JavaScript传入的回调函数
 */
-(void)callRouter:(JSValue *)requestObject callBack:(JSValue *)callBack HBWebBridgeDeprecated("该方法仅使用于UIWebView");


-(JSValue *)callRouterSync:(JSValue*)requestObject HBWebBridgeDeprecated("该方法仅使用于UIWebView");
/**
 增加处理JavaScript调用的Method方法对应的逻辑，详情参考wiki文档
 
 @param actionHandlerName 对JavaScript开放提供的Method名称
 @param callBack 逻辑执行的block，参数有成功和失败的回调block，在业务完成以后，如果成功，block传入成功结果的字典，如果失败，则使用HBAuthError定义的ErrorCode返回错误
 */
-(void)addActionHandler:(NSString *)actionHandlerName forCallBack:(HBWebBridgeHandlerCallBack)callBack;
-(void)addSyncActionHandler:(NSString *)actionHandlerName forCallBack:(HBWebBridgeHandlerSyncCallBack)callBack;
@end
