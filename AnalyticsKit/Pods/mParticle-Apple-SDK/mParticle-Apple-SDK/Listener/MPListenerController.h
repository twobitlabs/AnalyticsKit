#import <Foundation/Foundation.h>
#import "MPListenerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPListenerController : NSObject

/**
 * Returns the shared instance object.
 * @returns the Singleton instance of the MPListener class.
 */
+ (instancetype)sharedInstance;

/**
 * Adds a listener to the SDK to receive any MPListenerProtocol calls from the API to that object
 * @param sdkListener An instance of a class that implements the MPListenerProtocol
 */
- (void)addSdkListener:(id<MPListenerProtocol>)sdkListener;

/**
 * Removes a listener from the SDK to no longer receive any MPListenerProtocol calls from the API to that object
 * If you don't remove the Listener we will retain a zombie reference of your object and it will never be released
 * @param sdkListener An instance of a class that implements the MPListenerProtocol
 */
- (void)removeSdkListener:(id<MPListenerProtocol>)sdkListener;

/**
 * Indicates that an API method was called. This includes invocations both from external sources (your code)
 * and those which originated from within the SDK
 * @param apiName the name of the API method
 * @param parameter1 to parameter4 are the arguments sent to this api, such as the MPEvent in logEvent
 */
- (void)onAPICalled:(SEL)apiName parameter1:(nullable NSObject *)parameter1 parameter2:(nullable NSObject *)parameter2 parameter3:(nullable NSObject *)parameter3 parameter4:(nullable NSObject *)parameter4;
- (void)onAPICalled:(SEL)apiName parameter1:(nullable NSObject *)parameter1 parameter2:(nullable NSObject *)parameter2 parameter3:(nullable NSObject *)parameter3;
- (void)onAPICalled:(SEL)apiName parameter1:(nullable NSObject *)parameter1 parameter2:(nullable NSObject *)parameter2;
- (void)onAPICalled:(SEL)apiName parameter1:(nullable NSObject *)parameter1;
- (void)onAPICalled:(SEL)apiName;

/**
 * Indicates that a new Database entry has been created
 * @param tableName the name of the table
 * @param primaryKey a unique identifier for the database row
 * @param message the database entry in JSON form
 */
- (void)onEntityStored:(MPDatabaseTable)tableName primaryKey:(NSNumber *)primaryKey message:(NSString *)message;

/**
 * Indicates that a Network Request has been started. Network Requests for a given Endpoint are performed
 * synchronously, so the next invocation of onNetworkRequestFinished of the same Endpoint will be linked
 * @param type the type of network request, see Endpoint
 * @param url the URL of the request
 * @param body the response body in JSON form
 */
- (void)onNetworkRequestStarted:(MPEndpoint)type url:(NSString *)url body:(NSObject *)body;

/**
 * Indicates that a Network Request has completed.
 * @param type the type of network request, see Endpoint
 * @param url the URL of the request
 * @param body the response body in JSON form
 * @param responseCode the HTTP response code
 */
- (void)onNetworkRequestFinished:(MPEndpoint)type url:(NSString *)url body:(NSObject *)body responseCode:(NSInteger)responseCode;

/**
 * Indicates that a Kit's API method has been invoked and that the name of the Kit's method is different
 * than the method containing this method's invocation
 * @param methodName the name of the Kit's method being called
 * @param kitId the Id of the kit
 * @param used whether the Kit's method returned ReportingMessages, or null if return type is void
 * @param objects the arguments supplied to the Kit
 */
- (void)onKitApiCalled:(NSString *)methodName kitId:(int)kitId used:(BOOL)used objects:(NSArray *)objects;

/**
 * Indicates that a Kit module, with kitId, has been included in the source files
 * @param kitId the id of the kit, corresponds with a {@see com.mparticle.MParticle.ServiceProviders}
 */
- (void)onKitDetected:(int)kitId;

/**
 * Indicates that a Configuration for a kit with kitId is being applied
 * @param kitId the id of the kit, corresponds with a {@see com.mparticle.MParticle.ServiceProviders}
 * @param configuration the kit
 */
- (void)onKitConfigReceived:(int)kitId configuration:(NSDictionary *)configuration;

/**
 * Indicates that a kit with kitId was successfully started
 * @param kitId the id of the kit, corresponds with a {@see com.mparticle.MParticle.ServiceProviders}
 */
- (void)onKitStarted:(int)kitId;

/**
 * Indicates that either an attempt to start a kit was unsuccessful, or a started kit was stopped.
 * Possibilities for why this may happen include: {@see MParticleUser}'s loggedIn status or
 * {@see com.mparticle.consent.ConsentState} required it to be stopped, the Kit crashed, or a
 * configuration was received that excluded the kit
 * @param kitId the id of the kit, corresponds with a {@see com.mparticle.MParticle.ServiceProviders}
 * @param reason a message containing the reason a kit was stopped
 */
- (void)onKitExcluded:(int)kitId reason:(NSString *)reason;

/**
 * Indicates that state of a Session may have changed
 * @param session the current {@see InternalSession} instance
 */
- (void)onSessionUpdated:(nullable MParticleSession *)session;

/**
 * Indicates that an alias request has completed.
 * @param aliasResponse the alias response object
 */
- (void)onAliasRequestFinished:(nullable MPAliasResponse *)aliasResponse;


@end

NS_ASSUME_NONNULL_END
