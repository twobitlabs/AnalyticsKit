//
//  CSEventType.h
//  comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

typedef enum {
    CSApplicationStart,
    CSApplicationView,
    CSApplicationClose,
    CSApplicationAggregate,
    CSApplicationHidden,
    CSApplicationKeepAlive
} CSApplicationEventType;

extern NSString *const ApplicationEventType_toString[6];