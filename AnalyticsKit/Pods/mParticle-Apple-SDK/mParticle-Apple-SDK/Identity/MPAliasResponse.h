//
//  MPAliasResponse.h
//

#import <Foundation/Foundation.h>
#import "MPAliasRequest.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A response object representing the result of an alias request.
 */
@interface MPAliasResponse : NSObject

/**
 The HTTP response code returned by the server.
 */
@property (nonatomic, assign) NSInteger responseCode;

/**
 A human-readable error message returned by the server.
 */
@property (nonatomic, assign) NSString *errorResponse;

/**
 The corresponding alias request for this response.
 */
@property (nonatomic, strong) MPAliasRequest *request;

/**
 A random GUID associated with each alias request.
 */
@property (nonatomic, strong) NSString *requestID;

/**
 Whether the SDK will automatically try to re-send the alias request.
 */
@property (nonatomic, assign) BOOL willRetry;

/**
 Whether the alias request was successfully accepted by the server.
 */
@property (nonatomic, assign) BOOL isSuccessful;

@end

NS_ASSUME_NONNULL_END
