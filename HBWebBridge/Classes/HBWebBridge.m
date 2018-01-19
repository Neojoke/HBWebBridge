//
//  HBWebBridge.m
//  CocoaLumberjack
//
//  Created by Neo on 2017/11/16.
//

#import "HBWebBridge.h"

@implementation HBWebBridge
//FIXME: 修改回调机制，提供上层业务处理的失败回调方法，call由上层提供，经此层转换
-(NSMutableDictionary *)handlers{
    if (_handlers == nil) {
        _handlers = [NSMutableDictionary dictionary];
    }
    return _handlers;
}
-(NSMutableDictionary *)syncHandlers{
    if (_syncHandlers==nil) {
        _syncHandlers = [NSMutableDictionary dictionary];
    }
    return _syncHandlers;
}
-(void)callRouter:(JSValue *)requestObject callBack:(JSValue *)callBack{
    NSDictionary * dict = [requestObject toDictionary];
    NSString * methodName = [dict objectForKey:@"Method"];
    if (methodName != nil && methodName.length>0) {
        NSDictionary * params = [dict objectForKey:@"Data"];
        __weak HBWebBridge * weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf callAction:methodName params:params success:^(NSDictionary *responseDict) {
                if (responseDict != nil) {
                    NSString * result = [self responseStringWith:responseDict];
                    if (result) {
                        
                    }
                    [callBack callWithArguments:@[@"null",result]];
                }
                else{
                    [callBack callWithArguments:@[@"null",@"null"]];
                }
            } failure:^(NSError *error) {
                if (error) {
                    [callBack callWithArguments:@[[error description],@"null"]];
                }
                else{
                    [callBack callWithArguments:@[@"App Inner Error",@"null"]];
                }
            }];
        });
    }
    else{
        [callBack callWithArguments:@[@"methodName missing.",@"null"]];
    }
    return;
}
- (JSValue *)callRouterSync:(JSValue *)requestObject{
    NSDictionary * reponseDict = [requestObject toDictionary];
    NSString * methodName = [reponseDict objectForKey:@"Method"];
    JSValue * value;
    if (methodName != nil&&[methodName isKindOfClass: [NSString class]] && methodName.length>0) {
        NSDictionary * params = [reponseDict objectForKey:@"Data"];
        NSDictionary * responseDict = [self callSyncAction:methodName params:params];
        if (responseDict != nil) {
            value=[JSValue valueWithObject:@{@"result":responseDict} inContext:requestObject.context];
        }
        else{
            value = [JSValue valueWithObject:@{} inContext:requestObject.context];
        }
    }else{
        value = [JSValue valueWithObject:@{@"errMsg":@"methodName missing."} inContext:requestObject.context];
    }
    return value;
}
-(void)addActionHandler:(NSString *)actionHandlerName forCallBack:(HBWebBridgeHandlerCallBack)callBack{
    if (actionHandlerName.length>0 && callBack != nil) {
        [self.handlers setObject:callBack forKey:actionHandlerName];
    }
}
-(void)addSyncActionHandler:(NSString *)actionHandlerName forCallBack:(HBWebBridgeHandlerSyncCallBack)callBack{
    if (actionHandlerName.length>0 && callBack != nil) {
        [self.syncHandlers setObject:callBack forKey:actionHandlerName];
    }
}
-(NSDictionary *)callSyncAction:(NSString *)actionName params:(NSDictionary *)params{
    HBWebBridgeHandlerSyncCallBack callBack = [self.syncHandlers objectForKey:actionName];
    if (callBack) {
        __block NSDictionary * dict ;
        if ([NSThread isMainThread]) {
            dict = callBack(params);
            return dict;
        }else{
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_main_queue(), ^{
                dict = callBack(params);
                dispatch_semaphore_signal(semaphore);
            });
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            return dict;
        }
    }
    else{
        return @{@"errMsg":[[NSError errorWithDomain:@"iOS bridge Error" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"not fount this method for sync"}] description]};
    }
    
}
-(void)callAction:(NSString *)actionName params:(NSDictionary *)params success:(HBWebBridgeSuccessCallBack)success failure:(HBWebBridgeErrorCallBack)failure{
    HBWebBridgeHandlerCallBack callBack = [self.handlers objectForKey:actionName];
    if (callBack != nil) {
        callBack(params,failure,success);
    }else{
        failure([NSError errorWithDomain:@"iOS bridge Error" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"not fount this method for async"}]);
    }
}
-(NSString *)responseStringWith:(NSDictionary *)responseDict{
    if (responseDict) {
        NSDictionary * dict = @{@"result":responseDict};
        NSData * data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        NSString * result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        return result;
    }
    else{
        return nil;
    }
}
@end
