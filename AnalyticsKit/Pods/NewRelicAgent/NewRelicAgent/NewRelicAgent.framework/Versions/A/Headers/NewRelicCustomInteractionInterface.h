//
//  NewRelicCustomInteractionInterace.h
//  NewRelicAgent
//
//  See:
//    https://docs.newrelic.com/docs/mobile-apps for information
//    https://docs.newrelic.com/docs/releases/ios for release notes
//
//  Copyright (c) 2014 New Relic. All rights reserved.
//  See https://docs.newrelic.com/docs/licenses/ios-agent-licenses for license details
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif


    /*
     * @protocol NewRelicCustomInteractionInterface
     *
     * Discussion:
     *      Use this protocol with your UIViewControllers to preemptively rename
     *      the New Relic initiated Interaction Traces by implementing the method
     *      -customInteractionName.
     */
@protocol NewRelicCustomInteractionInterface
@required

    /*
     *  - (NSString*) customNewRelicInteractionName;
     *
     *  Discussion:
     *      If you implement this method in your UIViewController, New Relic 
     *      will call this method before starting an interaction (started from
     *      -viewDidLoad, or -viewDidAppear:) and rename the interaction with 
     *      the string returned. (Instead of the default name of
     *      "display <ViewControllerName>")
     */
    - (NSString*)customNewRelicInteractionName;
@end
#ifdef __cplusplus
}
#endif
