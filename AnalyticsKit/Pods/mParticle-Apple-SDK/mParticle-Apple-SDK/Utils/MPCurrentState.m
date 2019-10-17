#import "MPCurrentState.h"
#import <mach/mach.h>
#import "MPStateMachine.h"
#import "MPApplication.h"
#import "MParticle.h"

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

NSString *const kMPStateInformationKey = @"cs";
NSString *const kMPStateCPUKey = @"cpu";
NSString *const kMPStateSystemMemoryAvailableKey = @"sma";
NSString *const kMPStateSystemMemoryLowKey = @"sml";
NSString *const kMPStateSystemMemoryThresholdKey = @"smt";
NSString *const kMPStateSystemMemoryTotalKey = @"tsm";
NSString *const kMPStateAppMemoryAvailableKey = @"ama";
NSString *const kMPStateAppMemoryMaxKey = @"amm";
NSString *const kMPStateAppMemoryTotalKey = @"amt";
NSString *const kMPStateDeviceOrientationKey = @"so";
NSString *const kMPStateStatusBarOrientationKey = @"sbo";
NSString *const kMPStateTimeSinceStartKey = @"tss";
NSString *const kMPStateBatteryLevelKey = @"bl";
NSString *const kMPStateDataConnectionKey = @"dct";
NSString *const kMPStateGPSKey = @"gps";
NSString *const kMPStateTotalDiskSpaceKey = @"tds";
NSString *const kMPStateFreeDiskSpaceKey = @"fds";

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;

@end

@interface MPCurrentState () {
#if TARGET_OS_IOS == 1
    NSNumber *_statusBarOrientation;
#endif
}
@end

@implementation MPCurrentState

- (instancetype)init
{
    self = [super init];
    if (self) {
#if TARGET_OS_IOS == 1
        _statusBarOrientation = @(UIInterfaceOrientationPortrait);
#endif
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark Accessors
- (NSNumber *)applicationMemory {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    /*kern_return_t kerr = */task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    return @(info.resident_size);
}

- (NSDictionary<NSString *, NSString *> *)cpuUsageInfo {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return @{kMPStateCPUKey:@"0.0"};
    }
    
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    thread_info_data_t thinfo;
    mach_msg_type_number_t thread_info_count;
    thread_basic_info_t basic_info_th;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return @{kMPStateCPUKey:@"0.0"};
    }
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; ++j) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return @{kMPStateCPUKey:@"0.0"};
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
    }
    
    NSString *totalCPUUsage = [NSString stringWithFormat:@"%.0f", tot_cpu * 100];
    NSDictionary<NSString *, NSString *> *cpuUsageInfo = @{kMPStateCPUKey:totalCPUUsage};
    
    return cpuUsageInfo;
}

- (NSString *)dataConnectionStatus {
    NSString *dataConnectionStatus;
    
    switch ([MParticle sharedInstance].stateMachine.networkStatus) {
        case MParticleNetworkStatusReachableViaWAN:
            dataConnectionStatus = kDataConnectionMobile;
            break;
            
        case MParticleNetworkStatusReachableViaWiFi:
            dataConnectionStatus = kDataConnectionWifi;
            break;
            
        case MParticleNetworkStatusNotReachable:
            dataConnectionStatus = kDataConnectionOffline;
            break;
    }

    return dataConnectionStatus;
}

- (NSDictionary<NSString *, id> *)diskSpaceInfo {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileSystemAttributes = [fileManager attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    
    NSDictionary<NSString *, id> *diskSpaceInfo = @{kMPStateTotalDiskSpaceKey:fileSystemAttributes[NSFileSystemSize],
                                                    kMPStateFreeDiskSpaceKey:fileSystemAttributes[NSFileSystemFreeSize]};
    
    return diskSpaceInfo;
}

- (NSDictionary<NSString *, NSNumber *> *)systemMemoryInfo {
    vm_size_t pageSize;
    mach_port_t hostPort = mach_host_self();
    mach_msg_type_number_t hostSize = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(hostPort, &pageSize);
    vm_statistics_data_t vmStat;
    
    host_statistics(hostPort, HOST_VM_INFO, (host_info_t)&vmStat, &hostSize);
    
    int64_t freeMemory = (int64_t)vmStat.free_count * (int64_t)pageSize;
    int64_t totalMemory = ((int64_t)vmStat.free_count + (int64_t)vmStat.active_count + (int64_t)vmStat.inactive_count + (int64_t)vmStat.wire_count) * pageSize;
    
    NSDictionary<NSString *, NSNumber *> *systemMemoryInfo = @{kMPStateSystemMemoryAvailableKey:@(freeMemory),
                                                               kMPStateSystemMemoryTotalKey:@(totalMemory)};
    
    return systemMemoryInfo;
}

- (NSNumber *)timeSinceStart {
    NSDate *now = [NSDate date];
    NSNumber *timeSinceStart = MPMilliseconds([now timeIntervalSinceDate:[MParticle sharedInstance].stateMachine.startTime]);
    return timeSinceStart;
}

#if TARGET_OS_IOS == 1
- (NSNumber *)batteryLevel {
    UIDevice *device = [UIDevice currentDevice];
    if (!device.batteryMonitoringEnabled) {
        device.batteryMonitoringEnabled = YES;
    }
    
    float batteryLevel = device.batteryLevel;
    
    return @(batteryLevel);
}

- (NSNumber *)deviceOrientation {
    return @([[UIDevice currentDevice] orientation]);
}

- (NSNumber *)gpsState {
    BOOL gpsState = [CLLocationManager authorizationStatus] && [CLLocationManager locationServicesEnabled];
    return @(gpsState);
}

- (NSNumber *)statusBarOrientation {
    if (![MPStateMachine isAppExtension]) {
        if ([NSThread isMainThread]) {
            _statusBarOrientation = @([[MPApplication sharedUIApplication] statusBarOrientation]);
        }
    }
    return _statusBarOrientation;
}
#endif

#pragma mark Public instance methods
- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *stateInfo = [@{kMPStateAppMemoryTotalKey:self.applicationMemory,
                                                        kMPStateDataConnectionKey:self.dataConnectionStatus,
                                                        kMPStateFreeDiskSpaceKey:self.diskSpaceInfo[kMPStateFreeDiskSpaceKey],
                                                        kMPStateTimeSinceStartKey:self.timeSinceStart}
                                                      mutableCopy];
    
    NSDictionary<NSString *, NSString *> *cpuUsageInfo = self.cpuUsageInfo;
    if (cpuUsageInfo) {
        [stateInfo addEntriesFromDictionary:cpuUsageInfo];
    }
    
    [stateInfo addEntriesFromDictionary:[self systemMemoryInfo]];
    
#if TARGET_OS_IOS == 1
    stateInfo[kMPStateBatteryLevelKey] = self.batteryLevel;
    stateInfo[kMPStateDeviceOrientationKey] = self.deviceOrientation;
    stateInfo[kMPStateGPSKey] = self.gpsState;
    stateInfo[kMPStateStatusBarOrientationKey] = self.statusBarOrientation;
#endif
    
    return (NSDictionary *)stateInfo;
}

@end
