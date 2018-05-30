//
//  HBWebBridge.m
//  CocoaLumberjack
//
//  Created by Neo on 2017/11/16.
//

#import "HBWebBridge.h"
@interface HBWebBridge()
@end
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
        dispatch_block_t callBackBlock = ^(){
           
            [weakSelf callAction:methodName params:params success:^(NSDictionary *responseDict) {
                NSString * result;
                if (responseDict != nil) {
                    result = [self responseStringWith:responseDict];
                }
                else{
                    result = @"null";
                }
                if (callBack.isNull || callBack.isUndefined) {
                    //Do nothing.
                }
                else{
                    [callBack callWithArguments:@[@"null",result]];
                }
            } failure:^(NSError *error) {
                NSString * errorMsg;
                if (error) {
                    errorMsg =[error description];
                }
                else{
                    errorMsg= @"App Inner Error!";
                }
                if (callBack.isNull || callBack.isUndefined) {
                    
                }else{
                    [callBack callWithArguments:@[errorMsg,@"null"]];

                }
            }];
        };
        if ([NSThread isMainThread]) {
            callBackBlock();
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                callBackBlock();
            });
        }
    }
    else{
        if (callBack.isNull || callBack.isUndefined) {
            
        }
        else{
            [callBack callWithArguments:@[@"methodName missing.",@"null"]];
        }
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
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;
{
    id body = message.body;
    if([body isKindOfClass:[NSDictionary class]]){
        NSDictionary * requestDict = (NSDictionary *)body;
        NSString * methodName = [requestDict objectForKey:@"Method"];
        NSString * callBackName = [requestDict objectForKey:@"CB_iOS"];
        if (callBackName == nil || ([callBackName isKindOfClass:[NSString class]] &&callBackName.length==0)) {
            //Do nothing.
            return;
        }
        void (^callWKJSCallBackBlock)(NSString *,NSString * ,NSString *) = ^(NSString * windowCBName,NSString * errorMsg,NSString * reponseData){
            if ([errorMsg isKindOfClass:[NSString class]]) {
                if (errorMsg.length == 0) {
                    errorMsg = @"null";
                }
                else{
                    errorMsg =[NSString stringWithFormat:@"'%@'",errorMsg] ;
                }
            }
            else if (errorMsg ==nil){
                errorMsg = @"null";
            }
            else{
                errorMsg =[NSString stringWithFormat:@"'%@'",[errorMsg description]] ;
            }
            NSString * resultDataString;
            if (errorMsg && ![errorMsg isEqualToString:@"null"]) {
                resultDataString =@"null";
            }
            else{
                resultDataString =[NSString stringWithFormat:@"'%@',",reponseData] ;
            }
            NSString * javaScript;
            javaScript = [NSString stringWithFormat:@"%@(%@,%@);",windowCBName,errorMsg,resultDataString];
            javaScript = [javaScript stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            javaScript = [javaScript stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            javaScript = [javaScript stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            [message.webView evaluateJavaScript:javaScript completionHandler:^(id _Nullable o, NSError * _Nullable error) {
                NSLog(@"HBWebBridge WK Error: \n%@",error);
            }];
        };
        NSString * callBackFuncName = [NSString stringWithFormat:@"window.%@",callBackName];
        if (methodName != nil && methodName.length>0) {
            NSDictionary * params = [requestDict objectForKey:@"Data"];
            __weak HBWebBridge * weakSelf = self;
            dispatch_block_t callNativeBlock = ^(){
                [weakSelf callAction:methodName params:params success:^(NSDictionary *responseDict) {
                    NSString * result;
                    if (responseDict != nil) {
                        result = [self responseStringWith:responseDict];
                    }
                    else{
                        result = @"null";
                    }
                    if ([NSThread isMainThread]) {
                        callWKJSCallBackBlock(callBackFuncName,@"null",result);
                    }
                    else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            callWKJSCallBackBlock(callBackFuncName,@"null",result);
                        });
                    }
                } failure:^(NSError *error) {
                    NSString * errorMsg;
                    if (error) {
                        errorMsg =[error description];
                    }
                    else{
                        errorMsg= @"App Inner Error!";
                    }
                    if ([NSThread isMainThread]) {
                        callWKJSCallBackBlock(callBackFuncName,errorMsg,@"null");
                    }
                    else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            callWKJSCallBackBlock(callBackFuncName,errorMsg,@"null");
                        });
                    }
                }];
            };
            if ([NSThread isMainThread]) {
                callNativeBlock();
            }
            else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    callNativeBlock();
                });
            }
        }
        else{
            callWKJSCallBackBlock(callBackFuncName,@"methodName missing.",@"null");
        }
        
    }
    else{
        NSLog(@"HBWebBridge wk bridge message is null");
    }
}
-(WKUserScript *)getUserScriptForSyncMethodWithBridgeName:(NSString *)bridgeName methodName:(NSString *)methodName result:(id)result injectionTime:(WKUserScriptInjectionTime)injectionTime forMainFrameOnly:(BOOL)forMainFrameOnly{
    NSString * resultString = [HBWebBridge convertToJSONData:result];
    return [self getUserScriptForSyncMethodWithBridgeName:bridgeName methodName:methodName resultString:resultString injectionTime:injectionTime forMainFrameOnly:forMainFrameOnly];
}
-(WKUserScript *)getDefaultScriptWithBridgeName:(NSString *)bridgeName{
    NSString * sourceString = [NSString stringWithFormat:@"try { window['%@'] = {} }catch (error) {}",bridgeName];
    WKUserScript * userScript = [[WKUserScript alloc]initWithSource:sourceString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    return userScript;

}
-(WKUserScript *)getUserScriptForSyncMethodWithBridgeName:(NSString *)bridgeName methodName:(NSString *)methodName resultString:(NSString *)resultString injectionTime:(WKUserScriptInjectionTime)injectionTime forMainFrameOnly:(BOOL)forMainFrameOnly{
    NSString * sourceString = [NSString stringWithFormat:@"try { window['%@']['%@'] = function(requestString){ return '%@' } }catch (error) {};",bridgeName,methodName,resultString];
    WKUserScript * userScript = [[WKUserScript alloc]initWithSource:sourceString injectionTime:injectionTime forMainFrameOnly:forMainFrameOnly];
    return userScript;
}

+ (NSString*)convertToJSONData:(id)infoDict
{
    if ([infoDict isKindOfClass:[NSString class]]) {
        return (NSString *)infoDict;
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    NSString *jsonString = @"";
    
    if (! jsonData)
    {
        NSLog(@"Got an error: %@", error);
    }else
    {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  //去除掉首尾的空白字符和换行字符
    
   jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return jsonString;
}
@end
