//
//  PTPusherChannelAuthorizationOperation.m
//  libPusher
//
//  Created by Luke Redpath on 14/08/2011.
//  Copyright 2011 LJR Software Limited. All rights reserved.
//

#import "PTPusherChannelAuthorizationOperation.h"
#import "NSDictionary+QueryString.h"
#import "PTJSON.h"
#import "PTPusher+Testing.h"

@interface PTPusherChannelAuthorizationBypassOperation : NSOperation
@end

@interface PTPusherChannelAuthorizationOperation ()
@property (nonatomic, strong, readwrite) NSDictionary *authorizationData;
@end

@implementation PTPusherChannelAuthorizationOperation

@synthesize authorized;
@synthesize authorizationData;
@synthesize completionHandler;

- (NSMutableURLRequest *)mutableURLRequest
{
  // we can be sure this is always mutable
  return (NSMutableURLRequest *)URLRequest;
}

+ (id)operationWithAuthorizationURL:(NSURL *)URL channelName:(NSString *)channelName socketID:(NSString *)socketID
{
  NSAssert(URL, @"URL is required for authorization! (Did you set PTPusher.authorizationURL?)");
  
  // a short-circuit for testing, using a special URL
  if ([[URL absoluteString] isEqualToString:PTPusherAuthorizationBypassURL]) {
    return [[PTPusherChannelAuthorizationBypassOperation alloc] init];
  }
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
  [request setHTTPMethod:@"POST"];
  [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
  
  NSMutableDictionary *requestData = [NSMutableDictionary dictionary];
  [requestData setObject:socketID forKey:@"socket_id"];
  [requestData setObject:channelName forKey:@"channel_name"];
  
  [request setHTTPBody:[[requestData sortedQueryString] dataUsingEncoding:NSUTF8StringEncoding]];
  
  return [[self alloc] initWithURLRequest:request];
}

- (void)finish
{
  if (!self.isCancelled) { // don't do anything if cancelled
    authorized = ([(NSHTTPURLResponse *)URLResponse statusCode] == 200 || [(NSHTTPURLResponse *)URLResponse statusCode] == 201);
    
    if (authorized) {
      authorizationData = [[PTJSON JSONParser] objectFromJSONData:responseData];
      
      NSAssert2([authorizationData isKindOfClass:[NSDictionary class]], 
                @"Expected server to return authorization response as a dictionary, but received %@: %@", 
                NSStringFromClass([authorizationData class]), authorizationData);
    }
    
    if (self.completionHandler) {
      self.completionHandler(self);
    }
  }; 
  
  [super finish];
}

@end

@implementation PTPusherChannelAuthorizationBypassOperation {
  void (^_completionHandler)(id);
}

- (void)setCompletionHandler:(void (^)(id))completionHandler
{
  _completionHandler = completionHandler;
}

- (void)main
{
  _completionHandler(self);
}

- (BOOL)isAuthorized
{
  return YES;
}

- (NSDictionary *)authorizationData
{
  return [NSDictionary dictionary];
}

- (NSMutableURLRequest *)mutableURLRequest
{
  return [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:PTPusherAuthorizationBypassURL]];
}

- (NSError *)connectionError
{
  return nil;
}

@end
