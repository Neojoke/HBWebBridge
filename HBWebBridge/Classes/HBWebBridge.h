//
//  HBWebBridge.h
//  CocoaLumberjack
//
//  Created by Neo on 2017/11/16.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface HBWebBridge : NSObject
@property(nonatomic,strong)NSMutableDictionary * handlers;

/**
 对JavaScript开放的接口，详情参照wiki文档说明
 
 @param requestObject 包含{"Method":"","Data":""}标准对象
 @param callBack JavaScript传入的回调函数
 */
-(void)callRouter:(JSValue *)requestObject callBack:(JSValue *)callBack;
/**
 增加处理JavaScript调用的Method方法对应的逻辑，详情参考wiki文档
 
 @param actionHandlerName 对JavaScript开放提供的Method名称
 @param callBack 逻辑执行的block，参数有成功和失败的回调block，在业务完成以后，如果成功，block传入成功结果的字典，如果失败，则使用HBAuthError定义的ErrorCode返回错误
 */
-(void)addActionHandler:(NSString *)actionHandlerName forCallBack:(void(^)(NSDictionary * params,void(^errorCallBack)(NSError * error),void(^successCallBack)(NSDictionary * responseDict)))callBack;
@end
