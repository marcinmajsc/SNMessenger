#import "Settings/SNSettingsViewController.h"
#import "SNMessenger.h"

#pragma mark - Global variables & functions

static BOOL noAds;
static BOOL showTheEyeButton;
static BOOL alwaysSendHdPhotos;
static BOOL disableLongPressToChangeChatTheme;
static BOOL disableReadReceipts;
static NSString *disableTypingIndicator;
static BOOL hideNotifBadgesInChat;
static NSString *keyboardStateAfterEnterChat;
static BOOL canSaveFriendsStories;
static BOOL disableStoriesPreview;
static BOOL disableStorySeenReceipts;
static BOOL extendStoryVideoUploadLength;
static BOOL hideStatusBarWhenViewingStory;
static BOOL neverReplayStoryAfterReacting;
static BOOL hideStoriesTab;
static BOOL hideNotesRow;
static BOOL hideSearchBar;
static BOOL hideSuggestedContactsInSearch;
static NSMutableDictionary *settings;

BOOL isDarkMode = NO;
NSBundle *tweakBundle = nil;

static NSBundle *SNMessengerBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"SNMessenger" ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/Application Support/SNMessenger.bundle")];
    });

    return bundle;
}

static void reloadPrefs() {
    settings = getCurrentSettings();

    noAds = [[settings objectForKey:@"noAds"] ?: @(YES) boolValue];
    showTheEyeButton = [[settings objectForKey:@"showTheEyeButton"] ?: @(YES) boolValue];

    alwaysSendHdPhotos = [[settings objectForKey:@"alwaysSendHdPhotos"] ?: @(YES) boolValue];
    disableReadReceipts = [[settings objectForKey:@"disableReadReceipts"] ?: @(YES) boolValue];
    disableLongPressToChangeChatTheme = [[settings objectForKey:@"disableLongPressToChangeTheme"] ?: @(NO) boolValue];
    disableTypingIndicator = [settings objectForKey:@"disableTypingIndicator"] ?: @"NOWHERE";
    hideNotifBadgesInChat = [[settings objectForKey:@"hideNotifBadgesInChat"] ?: @(NO) boolValue];
    keyboardStateAfterEnterChat = [settings objectForKey:@"keyboardStateAfterEnterChat"] ?: @"ADAPTIVE";

    canSaveFriendsStories = [[settings objectForKey:@"canSaveFriendsStories"] ?: @(YES) boolValue];
    disableStoriesPreview = [[settings objectForKey:@"disableStoriesPreview"] ?: @(NO) boolValue];
    disableStorySeenReceipts = [[settings objectForKey:@"disableStorySeenReceipts"] ?: @(YES) boolValue];
    extendStoryVideoUploadLength = [[settings objectForKey:@"extendStoryVideoUploadLength"] ?: @(YES) boolValue];
    hideStatusBarWhenViewingStory = [[settings objectForKey:@"hideStatusBarWhenViewingStory"] ?: @(YES) boolValue];
    neverReplayStoryAfterReacting = [[settings objectForKey:@"neverReplayStoryAfterReacting"] ?: @(NO) boolValue];

    hideStoriesTab = [[settings objectForKey:@"hideStoriesTab"] ?: @(NO) boolValue];
    hideNotesRow = [[settings objectForKey:@"hideNotesRow"] ?: @(NO) boolValue];
    hideSearchBar = [[settings objectForKey:@"hideSearchBar"] ?: @(NO) boolValue];
    hideSuggestedContactsInSearch = [[settings objectForKey:@"hideSuggestedContactsInSearch"] ?: @(NO) boolValue];
}

#pragma mark - Settings page | Quick toggle to disable/enable read receipts

%hook MDSNavigationController
%property (nonatomic, retain) UIBarButtonItem *eyeItem;
%property (nonatomic, retain) UIBarButtonItem *settingsItem;

- (void)viewWillAppear:(BOOL)arg1 {
    if ([[self childViewControllerForUserInterfaceStyle] isKindOfClass:%c(MSGSettingsViewController)]) {
        UIButton *settingsButton = [[UIButton alloc] init];
        UIImage *settingsIcon = getTemplateImage(@"Gear@3x");
        [settingsButton setImage:settingsIcon forState:UIControlStateNormal];
        [settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
        self.settingsItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
        self.settingsItem.style = UIBarButtonItemStyleDone;

        @try {
            self.navigationBar.topItem.leftBarButtonItems = @[self.navigationBar.topItem.leftBarButtonItem, self.settingsItem];
        } @catch (id ex) {
            self.navigationBar.topItem.leftBarButtonItem = self.settingsItem;
        }
    }

    if (showTheEyeButton && [[self childViewControllerForUserInterfaceStyle] isKindOfClass:%c(MSGInboxViewController)]) {
        UIButton *eyeButton = [[UIButton alloc] init];
        UIImage *eyeIcon = getTemplateImage(disableReadReceipts ? @"No-Receipt@3x" : @"Receipt@3x");
        [eyeButton setImage:eyeIcon forState:UIControlStateNormal];
        [eyeButton addTarget:self action:@selector(handleEyeTap:) forControlEvents:UIControlEventTouchUpInside];
        self.eyeItem = [[UIBarButtonItem alloc] initWithCustomView:eyeButton];
        self.eyeItem.style = UIBarButtonItemStyleDone;

        self.navigationBar.topItem.rightBarButtonItems = @[self.navigationBar.topItem.rightBarButtonItem, self.eyeItem];
    }

    %orig;
}

%new(v@:)
- (void)openSettings {
    isDarkMode = MSHookIvar<NSInteger>(self, "_statusBarStyleFromTheme") == 1;
    SNSettingsViewController *settingsController = [[SNSettingsViewController alloc] init];
    [self pushViewController:settingsController animated:YES];
}

%new(v@:@)
- (void)handleEyeTap:(UIButton *)eyeButton {
    UIImage *eyeIcon = getTemplateImage(!disableReadReceipts ? @"No-Receipt@3x" : @"Receipt@3x");
    [eyeButton setImage:eyeIcon forState:UIControlStateNormal];

    [settings setObject:[NSNumber numberWithBool:!disableReadReceipts] forKey:@"disableReadReceipts"];
    [settings writeToFile:getSettingsPlistPath() atomically:YES];
    notify_post(PREF_CHANGED_NOTIF);
}

%end

#pragma mark - Necessary hooks

Class actionStandardClass;
MSGModelInfo actionStandardInfo;
MSGModelADTInfo actionStandardADTInfo = { "MSGStoryOverlayProfileViewAction", 0 };

Class actionTypeSaveClass;
MSGModelInfo actionTypeSaveInfo = { "MSGStoryViewerOverflowMenuActionTypeSave", 0, nil, nil, YES, nil};
MSGModelADTInfo actionTypeSaveADTInfo = { "MSGStoryViewerOverflowMenuActionType", 2 };

Class (* MSGModelDefineClass)(MSGModelInfo *);
%hookf(Class, MSGModelDefineClass, MSGModelInfo *info) {
    Class modelClass = %orig;

    SwitchStr (info->name) {
        CaseEqual ("MSGStoryOverlayProfileViewActionStandard") {
            actionStandardClass = modelClass;
            actionStandardInfo = *info;
            break;
        }

        CaseEqual ("MSGStoryViewerOverflowMenuActionTypeSave") {
            return objc_lookUpClass("MSGStoryViewerOverflowMenuActionTypeSave") ?: modelClass;
        }

        Default {
            break;
        }
    }

    return modelClass;
}

%hook MSGModel

%new(v@:@)
- (void)setValueForField:(NSString *)name, /* value: */ ... {
    MSGModelInfo *info = MSHookIvar<MSGModelInfo *>(self, "_modelInfo");
    NSInteger index = 0, type = -1, offset = 0x0;
    const char *encoding = "";

    while (index < info->numberOfFields) {
        if ([name isEqual:*(&info->fieldInfo->field_0 + offset)]) {
            encoding = *(&info->fieldInfo->encoding_0 + offset);
            type = *(&info->fieldInfo->type_0 + offset) % 256;
            break;
        }

        offset += 0x4;
        index++;
    };

    va_list args;
    va_start(args, name);

    switch (type) {
        case 0: {
            [self setBoolValue:(BOOL)va_arg(args, int) forFieldIndex:index];
            break;
        }

        case 2: {
            [self setInt64Value:va_arg(args, NSInteger) forFieldIndex:index];
            break;
        }

        case 5 ... 8: {
            switch (type - !IS_IOS_OR_NEWER(iOS_15_1)) {
                case 5: [self setObjectValue:va_arg(args, id) forFieldIndex:index];
                default: break;
            }

            break;
        }

        default: {
            RLog(@"model: %@ | field: %@ | type: %lu | encoding: %s", self, name, type, encoding);
            break;
        }
    }

    va_end(args);
}

%new(@@:Q)
- (id)valueAtFieldIndex:(NSUInteger)index {
    MSGModelInfo *modelInfo = MSHookIvar<MSGModelInfo *>(self, "_modelInfo");
    NSUInteger type = (*(&modelInfo->fieldInfo->type_0 + 0x4 * index)) % 256;
    const char *encoding = *(&modelInfo->fieldInfo->encoding_0 + 0x4 * index);

    if (index >= modelInfo->numberOfFields) return @"Out of fields.";
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@ValueAtFieldIndex:", typeLookup(encoding, type, YES)]);
    IMP imp = [self methodForSelector:selector];

    switch (type) {
        case  0: return @(getValue<BOOL>(self, imp, selector, index));
        case  1: return @(getValue<int>(self, imp, selector, index));
        case  2: return @(getValue<NSInteger>(self, imp, selector, index));
        case  3: return @(getValue<CGFloat>(self, imp, selector, index));
        case  4: return @(getValue<float>(self, imp, selector, index));

        case  5 ... 8: {
            switch (type - !IS_IOS_OR_NEWER(iOS_15_1)) {
                case 4: return [NSValue valueWithPointer:getValue<void *>(self, imp, selector, index)];
                case 5 ... 7: return getValue<id>(self, imp, selector, index);
                case 8: return NSStringFromSelector(getValue<SEL>(self, imp, selector, index));
                default: break;
            }
        }

        case  9: return [NSValue valueWithCGRect:getValue<CGRect>(self, imp, selector, index)];
        case 10: return [NSValue valueWithCGSize:getValue<CGSize>(self, imp, selector, index)];
        case 11: return [NSValue valueWithCGPoint:getValue<CGPoint>(self, imp, selector, index)];
        case 12: return [NSValue valueWithRange:getValue<NSRange>(self, imp, selector, index)];
        case 13: return [NSValue valueWithUIEdgeInsets:getValue<UIEdgeInsets>(self, imp, selector, index)];
        default: break;
    }

    return nil;
}

%new(@@:)
- (NSMutableDictionary *)debugModel {
    MSGModelInfo *modelInfo = MSHookIvar<MSGModelInfo *>(self, "_modelInfo");
    NSMutableDictionary *debugInfo = [@{} mutableCopy];
    NSInteger index = 0, offset = 0x0;

    while (index < modelInfo->numberOfFields) {
        NSString *name = *(&modelInfo->fieldInfo->field_0 + offset);
        NSUInteger size = *(&modelInfo->fieldInfo->sizeof_0 + offset);
        NSUInteger type = *(&modelInfo->fieldInfo->type_0 + offset) % 256;
        const char *encoding = *(&modelInfo->fieldInfo->encoding_0 + offset);

        NSDictionary *info = @{
            @"index": @(index),
            @"name" : name,
            @"size" : @(size),
            @"type" : [NSString stringWithFormat:@"type: %lu - %@ (%s)", type, typeLookup(encoding, type, NO), encoding],
            @"value": [self valueAtFieldIndex:index] ?: [NSNull null]
        };
        [debugInfo setValue:info forKey:[NSString stringWithFormat:@"%lu - %@", index, name]];

        offset += 0x4;
        index++;
    };

    return debugInfo;
}

%end

#pragma mark - Always send HD photos

%hook LSMediaPickerViewController

- (void)_stopHDAnimationAndToggleHD {
    if (alwaysSendHdPhotos && [MSHookIvar<NSMutableArray *>(self, "_selectedAssets") count]) return;
    %orig;
}

- (BOOL)collectionView:(id)arg1 shouldSelectItemAtIndexPath:(id)arg2 {
    if (alwaysSendHdPhotos) [self _stopHDAnimationAndToggleHD];
    return %orig;
}

%end

#pragma mark - Disable read receipts

void *(* MCINotificationCenterPostStrictNotification)(NSUInteger, id, NSString *, NSString *, NSMutableDictionary *);
%hookf(void *, MCINotificationCenterPostStrictNotification, NSUInteger type, id notifCenter, NSString *event, NSString *uniqueID, NSMutableDictionary *content) {
    if (disableReadReceipts && [[content valueForKey:@"MCDNotificationTaskLabelsListKey"] isEqual:@[@"tam_thread_mark_read"]]) {
        return nil;
    }

    return %orig;
}

#pragma mark - Disable stories preview

%hook MSGCQLResultSetList

+ (instancetype)newWithIdentifier:(NSString *)identifier context:(MSGStoryCardToolbox *)context resultSet:(id)arg3 resultSetCount:(NSInteger)arg4 options:(void *)arg5 actionHandlers:(void *)arg6 impressionTrackingContext:(id)arg7 {
    if ([identifier isEqual:@"stories"]) {
        [context setValueForField:@"isVideoAutoplayEnabled", !disableStoriesPreview];
    }

    return %orig;
}

%end

#pragma mark - Disable story seen receipt | Disable story replay after reacting

%hook LSStoryBucketViewController
%property (nonatomic, assign) BOOL isSelfStory;
%property (nonatomic, assign) CGFloat duration;

- (void)startTimer {
    self.isSelfStory = [self.ownerId isEqual:[[%c(FBAnalytics) sharedAnalytics] userFBID]];
    if (!disableStorySeenReceipts || self.isSelfStory) {
        return %orig;
    }

    LSVideoPlayerView *playerView = MSHookIvar<LSVideoPlayerView *>(self, "_videoPlayerView");
    self.duration = [self getDurationFromPlayerView:playerView];

    [MSHookIvar<NSTimer *>(self, "_storyTimer") invalidate]; // Stop last timer
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(_updateProgressIndicator) userInfo:nil repeats:YES];
    [self setValue:timer forKey:@"_storyTimer"]; // Set new timer
}

- (CGFloat)storyDuration {
    return disableStorySeenReceipts && !self.isSelfStory ? self.duration : %orig;
}

%new(d@:@)
- (CGFloat)getDurationFromPlayerView:(LSVideoPlayerView *)playerView {
    if (playerView) {
        CMTime timeStruct = [playerView duration];
        return (CGFloat)timeStruct.value / (CGFloat)timeStruct.timescale;
    }
    return 5.0f; // Default value for non-video stories
}

- (void)replyBarWillPlayStoryFromBeginning:(id)arg1 {
    if (!neverReplayStoryAfterReacting) {
        %orig;
    }
}

%end

#pragma mark - Disable typing indicator

%hook MSGThreadRowCell

- (BOOL)_isTypingWithModel:(id)arg1 mailbox:(id)arg2 {
    return [@[@"CHAT_SECTIONS_ONLY", @"BOTH"] containsObject:disableTypingIndicator] ? NO : %orig;
}

%end

%hook MSGMessageListViewModelGenerator

// v458.0.0
- (void)didLoadThreadModel:(id)arg1 threadViewModelMap:(id)arg2 threadSessionIdentifier:(id)arg3 messageModels:(NSMutableArray <MSGTempMessageListItemModel *> *)models threadParticipants:(id)arg5 attributionIDV2:(id)arg6 loadMoreStateOlder:(int)arg7 loadMoreStateNewer:(int)arg8 didLoadNewIsland:(BOOL)arg9 completion:(id)arg10 {
    if ([@[@"INBOX_ONLY", @"BOTH"] containsObject:disableTypingIndicator] && [[[models lastObject] messageId] isEqual:@"typing_indicator"]) {
        [models removeLastObject];
    }

    %orig;
}

- (void)didLoadThreadModel:(id)arg1 threadViewModelMap:(id)arg2 threadSessionIdentifier:(id)arg3 messageModels:(NSMutableArray <MSGTempMessageListItemModel *> *)models threadParticipants:(id)arg5 attributionIDV2:(id)arg6 loadMoreStateOlder:(int)arg7 loadMoreStateNewer:(int)arg8 didLoadNewIsland:(BOOL)arg9 modelFetchedTimeInSeconds:(CGFloat)arg10 completion:(id)arg11 {
    if ([@[@"INBOX_ONLY", @"BOTH"] containsObject:disableTypingIndicator] && [[[models lastObject] messageId] isEqual:@"typing_indicator"]) {
        [models removeLastObject];
    }

    %orig;
}

%end

#pragma mark - Extend story video upload duration

BOOL (* MSGCSessionedMobileConfigGetBoolean)(MBIAuthDataContext *, MSGCSessionedMobileConfig *, void *, void *);
%hookf(BOOL, MSGCSessionedMobileConfigGetBoolean, MBIAuthDataContext *context, MSGCSessionedMobileConfig *config, void *arg3, void *arg4) {
    if (strcmp(config->subKey, "replace_system_trimmer") == 0) {
        return YES;
    }

    return %orig;
}

CGFloat (* MSGCSessionedMobileConfigGetDouble)(MBIAuthDataContext *, MSGCSessionedMobileConfig *, BOOL, BOOL);
%hookf(CGFloat, MSGCSessionedMobileConfigGetDouble, MBIAuthDataContext *context, MSGCSessionedMobileConfig *config, BOOL arg3, BOOL arg4) {
    if (strcmp(config->subKey, "max_story_duration") == 0) {
        return 600.0f; // 10 mins
    }

    return %orig;
}

#pragma mark - Hide notification badges in chat top bar | Keyboard state after entering chat | Disable long press to change theme

%hook MSGThreadViewController

- (instancetype)initWithMailbox:(id)arg1 threadQueryKey:(id)arg2 threadSessionLifecycle:(id)arg3 threadNavigationData:(id)arg4 navigationEntryPoint:(int)arg5 options:(MSGThreadViewControllerOptions *)options metricContextsContainer:(id)arg7 datasource:(id)arg8 {
    MSGThreadViewOptions *viewOptions = [options viewOptions];

    [viewOptions setValueForField:@"shouldHideBadgeInBackButton", hideNotifBadgesInChat];

    if (![keyboardStateAfterEnterChat isEqual:@"ADAPTIVE"]) {
        if (IS_IOS_OR_NEWER(iOS_15_1)) {
            [viewOptions setValueForField:@"onOpenKeyboardState", [keyboardStateAfterEnterChat isEqual:@"ALWAYS_EXPANDED"] ? 2 : 3];
        } else { // v458.0.0
            [viewOptions setValueForField:@"onOpenKeyboardState", [keyboardStateAfterEnterChat isEqual:@"ALWAYS_EXPANDED"] ? 2 : 1];
        }
    }

    return %orig;
}

- (void)messageListViewControllerDidLongPressBackground:(id)arg1 {
    if (!disableLongPressToChangeChatTheme) %orig;
}

%end

#pragma mark - Hide search bar

%hook MSGInboxViewController

- (void)viewDidLoad {
    %orig;
    if (hideSearchBar) {
        self.navigationItem.searchController = nil;
    }
}

%end

#pragma mark - Hide status bar when viewing story (iOS 12 devices only)

%hook LSMediaViewerViewController

- (BOOL)prefersStatusBarHidden {
    BOOL isCorrectController = [MSHookIvar<id>(self, "_contentController") isKindOfClass:%c(LSStoryViewerContentController)];
    return hideStatusBarWhenViewingStory && isCorrectController ? YES : %orig;
}

%end

#pragma mark - Hide suggested contacts in search

%hook LSContactListViewController

- (void)didLoadContactList:(NSArray *)list contactExtrasById:(NSDictionary *)extras {
    if (hideSuggestedContactsInSearch) {
        NSString *featureIdentifier = MSHookIvar<NSString *>(self, "_featureIdentifier");
        if ([featureIdentifier isEqual:@"universal_search_null_state"]) {
            return %orig(nil, nil);
        }
    }

    %orig;
}

%end

#pragma mark - Hide stories tab

%hook MDSTabBarController

- (void)_prepareTabBar {
    if (hideStoriesTab) self.tabBar.hidden = YES;
    %orig;
}

%end

#pragma mark - Remove ads | Hide notes row

%hook MSGThreadListDataSource

- (NSArray *)inboxRows {
    NSMutableArray *currentRows = [%orig mutableCopy];
    if ([self isInitializationComplete] && (noAds || hideNotesRow) && [currentRows count] > 0) {
        MSGThreadListUnitsSate *unitsState = MSHookIvar<MSGThreadListUnitsSate *>(self, "_unitsState");
        NSMutableDictionary *units = [unitsState unitKeyToUnit];
        MSGInboxUnit *adUnit = [units objectForKey:@"ads_renderer"];
        NSUInteger adUnitIndex = [[adUnit positionInThreadList] belowThreadIndex] + 2;
        BOOL isOffline = [units objectForKey:@"qp"];

        if (noAds && adUnitIndex < [currentRows count]) [currentRows removeObjectAtIndex:adUnitIndex + isOffline];
        if (hideNotesRow) [currentRows removeObjectAtIndex:isOffline];
    }

    return currentRows;
}

%end

%hook LSStoryViewerContentController

- (void)_updateStoriesWithBucketStoryModels:(NSMutableArray *)models deletedIndexPaths:(id)arg2 addedIndexPaths:(NSArray *)addedIndexPaths newIndexPath:(id)arg4 {
    // Bucket types: 0 = unread | 1 = advertisement | 2 = read
    for (MSGStoryViewerBucketModel *model in [models reverseObjectEnumerator]) {
        if ([model bucketType] == 1) {
            [models removeObject:model];
            addedIndexPaths = @[];
        }
    }

    %orig;
}

%end

#pragma mark - Save friends' stories

%hook LSStoryOverlayProfileView

- (void)_handleOverflowMenuButton:(UIButton *)button {
    NSMutableArray *actions = [MSHookIvar<NSArray *>(self, "_overflowActions") mutableCopy];
    NSString *storyAuthorId = MSHookIvar<NSString *>(self, "_storyAuthorId");
    if (canSaveFriendsStories && ![storyAuthorId isEqual:[[%c(FBAnalytics) sharedAnalytics] userFBID]] && [actions count] == 3) {
        actionTypeSaveClass = MSGModelDefineClass(&actionTypeSaveInfo);
        MSGStoryViewerOverflowMenuActionTypeSave *actionTypeSave = nil;
        MSGStoryOverlayProfileViewActionStandard *actionStandard = nil;

        if (IS_IOS_OR_NEWER(iOS_15_1)) {
            actionTypeSave = [actionTypeSaveClass newADTModelWithInfo:&actionTypeSaveInfo adtInfo:&actionTypeSaveADTInfo];
            actionStandard = [actionStandardClass newADTModelWithInfo:&actionStandardInfo adtInfo:&actionStandardADTInfo];
        } else { // v458.0.0
            actionTypeSave = [actionTypeSaveClass newADTModelWithInfo:&actionTypeSaveInfo adtValueSubtype:actionTypeSaveADTInfo.subtype];
            actionStandard = [actionStandardClass newADTModelWithInfo:&actionStandardInfo adtValueSubtype:actionStandardADTInfo.subtype];
        }

        [actionStandard setValueForField:@"type", actionTypeSave];
        [actions insertObject:actionStandard atIndex:2];
        [self setValue:actions forKey:@"_overflowActions"];
    }

    %orig;
}

%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    reloadPrefs();

    // Get the tweak bundle
    tweakBundle = SNMessengerBundle();

    NSString *framework = IS_IOS_OR_NEWER(iOS_15_1) ? @"LightSpeedEngine.framework/LightSpeedEngine" : @"LightSpeedCore.framework/LightSpeedCore";
    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Frameworks/%@", [[NSBundle mainBundle] bundlePath], framework];
    NSBundle *bundle = [NSBundle bundleWithPath:frameworkPath];
    if (!bundle.loaded) [bundle load];
    MSImageRef ref = MSGetImageByName([frameworkPath UTF8String]);

    MSGModelDefineClass = (Class (*)(MSGModelInfo *))MSFindSymbol(ref, "_MSGModelDefineClass");
    MCINotificationCenterPostStrictNotification = (void *(*)(NSUInteger, id, NSString *, NSString *, NSMutableDictionary *))MSFindSymbol(ref, "_MCINotificationCenterPostStrictNotification");
    MSGCSessionedMobileConfigGetBoolean = (BOOL (*)(MBIAuthDataContext *, MSGCSessionedMobileConfig *, void *, void *))MSFindSymbol(ref, "_MSGCSessionedMobileConfigGetBoolean");
    MSGCSessionedMobileConfigGetDouble = (CGFloat (*)(MBIAuthDataContext *, MSGCSessionedMobileConfig *, BOOL, BOOL))MSFindSymbol(ref, "_MSGCSessionedMobileConfigGetDouble");

    %init;
}
