/*
 Copyright 2012 baocai zhang. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 THIS SOFTWARE IS PROVIDED BY THE FREEBSD PROJECT ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE FREEBSD PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those of the authors and should not be interpreted as representing official policies, either expressed or implied, of the FreeBSD Project.
 */

/*
 @author baocai zhang
 website:www.giser.net
 email:zhangbaocaicug@gmail.com
 */
#import "OSSOperation.h"

#import "ServiceCredentials.h"
#import "IRequestSigner.h"
#import "OSSUtils.h"
#import "DateUtil.h"
#import "ExecutionContext.h"
#import "OSSErrorResponseHandler.h"
#import "IResultParser.h"
#import "OSSRequestSigner.h"
//#import "HoomicSource.h"

@interface OSSOperation(Private)

@end
@implementation OSSOperation

-(id) initWithEndPoint:(NSString * ) endpoint credentials:(ServiceCredentials *)credentials client:(DefaultServiceClient *)client
{
    if (self = [super init]) {
        _endpoint = endpoint;
        _credentials = credentials;
        _client = client;
        _client.delegate = self;
    }
    return self;
}
-(void)request:(HttpMethod) httpMethod buckName:(NSString*) buckName objectName:(NSString*) objectName headers:(NSMutableDictionary*) headers   params:(OrderedDictionary*) params  content:(NSData *) content  contentLength:(long) contentLength userInfo:(NSDictionary*)userInfo
{
  RequestMessage *localRequestMessage = [self generateRequest:httpMethod
                                                     buckName:buckName
                                                   objectName:objectName
                                                      headers:headers
                                                       params:params
                                                      content:content
                                                contentLength:contentLength
                                                     userInfo:userInfo];
  ExecutionContext *localExecutionContext = [self generateContext:httpMethod
                                                         buckName:buckName
                                                       objectName:objectName];

    [_client sendRequest:localRequestMessage executionContext: localExecutionContext ];
    
}

- (void)request:(HttpMethod)httpMethod
       buckName:(NSString*)buckName
     objectName:(NSString*)objectName
        headers:(NSMutableDictionary*)headers
         params:(OrderedDictionary*)params
        content:(NSData *)content
  contentLength:(long)contentLength
       userInfo:(NSDictionary*)userInfo
      successed:(void(^)(ResponseMessage *))successedBlock
         failed:(void(^)(ResponseMessage *))failedBlock {
  RequestMessage *localRequestMessage = [self generateRequest:httpMethod
                                                     buckName:buckName
                                                   objectName:objectName
                                                      headers:headers
                                                       params:params
                                                      content:content
                                                contentLength:contentLength
                                                     userInfo:userInfo];
  ExecutionContext *localExecutionContext = [self generateContext:httpMethod
                                                         buckName:buckName
                                                       objectName:objectName];
  [_client sendRequest:localRequestMessage executionContext:localExecutionContext successed:successedBlock failed:failedBlock];
}

- (RequestMessage *)generateRequest:(HttpMethod) httpMethod buckName:(NSString*) buckName objectName:(NSString*) objectName headers:(NSMutableDictionary*) headers   params:(OrderedDictionary*) params  content:(NSData *) content  contentLength:(long) contentLength userInfo:(NSDictionary*)userInfo {
  NSString* str = [OSSUtils  makeResourcePath:buckName objectName:objectName];
  if (headers == nil)
    {
    headers = [NSMutableDictionary dictionaryWithCapacity:10 ];
    }
  if (params == nil) {
    params = [OrderedDictionary dictionaryWithCapacity:10 ];
  }
  //此处应该用rfc时间。而客户端的时间是可以客户自己改的。要保证时间的正确性
      [headers setObject:[DateUtil formatRfc822Date:[NSDate date]] forKey:@"Date"];
//  [headers setObject:[DateUtil formatRfc822Date:[NSDate dateWithTimeIntervalSince1970:[HoomicSource timeNowServer]]] forKey:@"Date"];
  if ([headers objectForKey:@"Content-Type"] == nil) {
    [headers setObject:@"" forKey:@"Content-Type"];
  }
  
  
  RequestMessage *localRequestMessage = [[RequestMessage alloc] init];
  localRequestMessage.endpoint = _endpoint;
  localRequestMessage.resourcePath=str;
  localRequestMessage.headers = headers;
  localRequestMessage.parameters = params;
  localRequestMessage.method = httpMethod;
  localRequestMessage.content = content;
  localRequestMessage.contentLength = contentLength;
  localRequestMessage.userInfo = userInfo;
  
  return localRequestMessage;
}

- (ExecutionContext *)generateContext:(HttpMethod) httpMethod buckName:(NSString*) buckName objectName:(NSString*) objectName {
  ExecutionContext *localExecutionContext =[[ExecutionContext alloc] init];
  localExecutionContext.charset = NSUTF8StringEncoding;
  
  localExecutionContext.signer = [OSSOperation createSigner:httpMethod buckName:buckName objectName:objectName serviceCredentials:_credentials];
  
  OSSErrorResponseHandler * errorResponseHandler = [[OSSErrorResponseHandler alloc] init];
  [localExecutionContext.responseHandlers addObject:errorResponseHandler];
  return localExecutionContext;
}

+(id<IRequestSigner>) createSigner:(HttpMethod) httpMethod  buckName:(NSString*) buckName  objectName:(NSString*) objectName  serviceCredentials:(ServiceCredentials*) serviceCredentials
{
    NSMutableString * str = [[NSMutableString alloc] initWithCapacity:100];
    [str appendString:@"/"];
    if (buckName != nil) {
        [str appendString:buckName];
    }
    else {
        [str appendString:@""];
    }
    if (objectName != nil) {
        [str appendString:@"/"];
        [str appendString:objectName];
    }
    else {
        [str appendString:@""];
    }
    OSSRequestSigner * ossRequestSigner = [[OSSRequestSigner alloc] initWithHttpMethod:httpMethod resourcePath:str credentials:serviceCredentials];
    return  ossRequestSigner;
}
-(void)serviceClientRequestFinished:(DefaultServiceClient*)defaultServiceClient result:(id) result
{
    
}
-(void)serviceClientRequestFailed:(DefaultServiceClient*)defaultServiceClient error:(id) error
{
    
}
@end
