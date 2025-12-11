#import <Foundation/Foundation.h>

static BOOL YTMU(NSString *key) {
    NSDictionary *YTMUltimateDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"YTMUltimate"];
    return [YTMUltimateDict[key] boolValue];
}

static BOOL bypassRegion() {
    return YTMU(@"YTMUltimateIsEnabled") && YTMU(@"bypassRegion");
}

// Main playability status hooks - bypass region restrictions
%hook YTIPlayabilityStatus

- (BOOL)isPlayable {
    return bypassRegion() ? YES : %orig;
}

- (void)setIsPlayable:(BOOL)playable {
    bypassRegion() ? %orig(YES) : %orig;
}

- (BOOL)hasPlayableInEmbed {
    return bypassRegion() ? YES : %orig;
}

// Override playability reason to clear restrictions
- (id)reason {
    return bypassRegion() ? nil : %orig;
}

- (id)reasonTitle {
    return bypassRegion() ? nil : %orig;
}

- (id)reasonDescription {
    return bypassRegion() ? nil : %orig;
}

// Skip any error screens
- (id)errorScreen {
    return bypassRegion() ? nil : %orig;
}

// Allow all content
- (BOOL)hasLiveStreamability {
    return bypassRegion() ? NO : %orig;
}

%end

// Override content availability checks
%hook YTPlayerResponse

- (BOOL)isPlayable {
    return bypassRegion() ? YES : %orig;
}

%end

// Bypass geo-restriction checks in cold config
%hook YTColdConfig

- (BOOL)isGeoRestrictionsEnabled {
    return bypassRegion() ? NO : %orig;
}

- (BOOL)enableMusicGeoRestrictions {
    return bypassRegion() ? NO : %orig;
}

%end

// Bypass region checks in inner tube context
%hook YTIInnerTubeContext

- (id)clientGeoLocation {
    return bypassRegion() ? nil : %orig;
}

%end

// Override client-side location services
%hook YTLocationService

- (id)countryCode {
    // Return US as a widely available region if bypass is enabled
    return bypassRegion() ? @"US" : %orig;
}

%end

// Bypass content checks
%hook YTMContentAvailabilityChecker

- (BOOL)isContentAvailable {
    return bypassRegion() ? YES : %orig;
}

- (BOOL)isContentRestricted {
    return bypassRegion() ? NO : %orig;
}

%end

// Handle music-specific availability
%hook YTMMusicContentAvailability

- (BOOL)isAvailable {
    return bypassRegion() ? YES : %orig;
}

- (BOOL)isRestricted {
    return bypassRegion() ? NO : %orig;
}

%end

// Override video details restrictions
%hook YTIVideoDetails

- (BOOL)isLiveContent {
    // Let live content through if it was being blocked
    return %orig;
}

%end

// Ensure streaming data is available
%hook YTIStreamingData

- (BOOL)hasAdaptiveFormats {
    return bypassRegion() ? YES : %orig;
}

%end

// Initialize default settings
%ctor {
    NSMutableDictionary *YTMUltimateDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"YTMUltimate"]];
    
    // Enable bypass region by default when YTMUltimate is enabled
    if (!YTMUltimateDict[@"bypassRegion"]) {
        [YTMUltimateDict setObject:@(1) forKey:@"bypassRegion"];
        [[NSUserDefaults standardUserDefaults] setObject:YTMUltimateDict forKey:@"YTMUltimate"];
    }
}
