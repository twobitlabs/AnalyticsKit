NS_ASSUME_NONNULL_BEGIN

@class MParticleSession;
@class MPAliasResponse;

typedef NS_ENUM(NSInteger, MPEndpoint) {
    MPEndpointIdentityLogin = 0,
    MPEndpointIdentityLogout,
    MPEndpointIdentityIdentify,
    MPEndpointIdentityModify,
    MPEndpointEvents,
    MPEndpointConfig,
    MPEndpointAlias
};

typedef NS_ENUM(NSInteger, MPDatabaseTable) {
    MPDatabaseTableAttributes = 0,
    MPDatabaseTableBreadcrumbs,
    MPDatabaseTableMessages,
    MPDatabaseTableReporting,
    MPDatabaseTableSessions,
    MPDatabaseTableUploads,
    MPDatabaseTableUnknown
};

@protocol MPListenerProtocol <NSObject>
#pragma mark - Required methods

#pragma mark - Optional methods
@optional

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;

/**
 * Indicates that an API method was called. This includes invocations both from external sources (your code)
 * and those which originated from within the SDK
 * @param apiName the name of the API method
 * @param stackTrace is the current stackTrace as an array of NSStrings
 * @param isExternal true, if the call originated from outside of the SDK
 * @param objects is the arguments sent to this api, such as the MPEvent in logEvent
 */
- (void)onAPICalled:(nonnull NSString *)apiName stackTrace:(nonnull NSArray *)stackTrace isExternal:(BOOL)isExternal objects:(nullable NSArray *)objects;

/**
 * Indicates that a new Database entry has been created
 * @param tableName the name of the table
 * @param primaryKey a unique identifier for the database row
 * @param message the database entry in NSString form
 */
- (void)onEntityStored:(MPDatabaseTable)tableName primaryKey:(nonnull NSNumber *)primaryKey message:(nonnull NSString *)message;

/**
 * Indicates that a Network Request has been started.
 * @param type the type of network request, see Endpoint
 * @param url the URL of the request
 * @param body the response body in JSON form
 */
- (void)onNetworkRequestStarted:(MPEndpoint)type url:(nonnull NSString *)url body:(nonnull NSObject *)body;

/**
 * Indicates that a Network Request has completed.
 * @param type the type of network request, see Endpoint
 * @param url the URL of the request
 * @param body the response body in JSON form
 * @param responseCode the HTTP response code
 */
- (void)onNetworkRequestFinished:(MPEndpoint)type url:(nonnull NSString *)url body:(nonnull NSObject *)body responseCode:(NSInteger)responseCode;

/**
 * Indicates that a Kit's API method has been invoked and that the name of the Kit's method is different
 * than the method containing this method's invocation
 * @param methodName the name of the Kit's method being called
 * @param kitId the Id of the kit
 * @param used whether the Kit's method returned ReportingMessages, or null if return type is void
 * @param objects the arguments supplied to the Kit
 */
- (void)onKitApiCalled:(nonnull NSString *)methodName kitId:(int)kitId used:(BOOL)used objects:(nonnull NSArray *)objects;

/**
 * Indicates that a Kit module, with kitId, has been included in the source files
 * @param kitId the id of the kit, corresponds with a {@see MPKitInstance}
 */
- (void)onKitDetected:(int)kitId;

/**
 * Indicates that a Configuration for a kit with kitId is being applied
 * @param kitId the id of the kit, corresponds with a {@see MPKitInstance}
 * @param configuration the kit
 */
- (void)onKitConfigReceived:(int)kitId configuration:(nonnull NSDictionary *)configuration;

/**
 * Indicates that a kit with kitId was successfully started
 * @param kitId the id of the kit, corresponds with a {@see MPKitInstance}
 */
- (void)onKitStarted:(int)kitId;

/**
 * Indicates that either an attempt to start a kit was unsuccessful, or a started kit was stopped.
 * Possibilities for why this may happen include: {@see MParticleUser}'s loggedIn status or
 * {@see MPConsentState} required it to be stopped, the Kit crashed, or a
 * configuration was received that excluded the kit
 * @param kitId the id of the kit, corresponds with a {@see MPKitInstance}
 * @param reason a message containing the reason a kit was stopped
 */
- (void)onKitExcluded:(int)kitId reason:(nonnull NSString *)reason;

/**
 * Indicates that state of a Session may have changed
 * @param session the current {@see MParticleSession} instance
 */
- (void)onSessionUpdated:(nullable MParticleSession *)session;

/**
 * Indicates that an alias request has completed
 * @param aliasResponse the alias response object
 */
- (void)onAliasRequestFinished:(nullable MPAliasResponse *)aliasResponse;

@end

NS_ASSUME_NONNULL_END
