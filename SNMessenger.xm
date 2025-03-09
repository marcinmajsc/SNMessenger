#import "Settings/SNSettingsViewController.h"
#import "SNMessenger.h"

#pragma mark - Global variables & functions

static BOOL noAds;
static BOOL showTheEyeButton;
static BOOL alwaysSendHdPhotos;
static BOOL callConfirmation;
static BOOL disableLongPressToChangeChatTheme;
static BOOL disableReadReceipts;
static BOOL disableTypingIndicator;
static NSString *hideTypingIndicator;
static BOOL hideNotifBadgesInChat;
static NSString *keyboardStateAfterEnterChat;
static BOOL canSaveFriendsStories;
static BOOL disableStoriesPreview;
static BOOL disableStorySeenReceipts;
static BOOL extendStoryVideoUploadLength;
static BOOL hideStatusBarWhenViewingStory;
static BOOL neverReplayStoryAfterReacting;
static BOOL hidePeopleTab;
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
    callConfirmation = [[settings objectForKey:@"callConfirmation"] ?: @(YES) boolValue];
    disableReadReceipts = [[settings objectForKey:@"disableReadReceipts"] ?: @(YES) boolValue];
    disableLongPressToChangeChatTheme = [[settings objectForKey:@"disableLongPressToChangeTheme"] ?: @(NO) boolValue];
    disableTypingIndicator = [[settings objectForKey:@"disableTypingIndicator"] ?: @(NO) boolValue];
    hideTypingIndicator = [settings objectForKey:@"hideTypingIndicator"] ?: @"NOWHERE";
    hideNotifBadgesInChat = [[settings objectForKey:@"hideNotifBadgesInChat"] ?: @(NO) boolValue];
    keyboardStateAfterEnterChat = [settings objectForKey:@"keyboardStateAfterEnterChat"] ?: @"ADAPTIVE";

    canSaveFriendsStories = [[settings objectForKey:@"canSaveFriendsStories"] ?: @(YES) boolValue];
    disableStoriesPreview = [[settings objectForKey:@"disableStoriesPreview"] ?: @(NO) boolValue];
    disableStorySeenReceipts = [[settings objectForKey:@"disableStorySeenReceipts"] ?: @(YES) boolValue];
    extendStoryVideoUploadLength = [[settings objectForKey:@"extendStoryVideoUploadLength"] ?: @(YES) boolValue];
    hideStatusBarWhenViewingStory = [[settings objectForKey:@"hideStatusBarWhenViewingStory"] ?: @(YES) boolValue];
    neverReplayStoryAfterReacting = [[settings objectForKey:@"neverReplayStoryAfterReacting"] ?: @(NO) boolValue];

    hidePeopleTab = [[settings objectForKey:@"hidePeopleTab"] ?: @(NO) boolValue];
    hideStoriesTab = [[settings objectForKey:@"hideStoriesTab"] ?: @(NO) boolValue];
    hideNotesRow = [[settings objectForKey:@"hideNotesRow"] ?: @(NO) boolValue];
    hideSearchBar = [[settings objectForKey:@"hideSearchBar"] ?: @(NO) boolValue];
    hideSuggestedContactsInSearch = [[settings objectForKey:@"hideSuggestedContactsInSearch"] ?: @(NO) boolValue];
}

#pragma mark - Settings page | Quick toggle to disable/enable read receipts

%hook MSGCommunityListViewController

- (NSMutableArray *)_headerSectionCellConfigs {
    NSMutableArray *cellConfigs = %orig;
    if ([cellConfigs count] == 3) {
        NSArray *folders = MSHookIvar<NSArray *>(self, "_folders");
        MSGInboxFolderListItemInfoFolder *settingsConfig = [[folders firstObject] copy];
        [settingsConfig setValueForField:@"folderName", localizedStringForKey(@"ADVANCED_SETTINGS")];
        [settingsConfig setValueForField:@"dispatchKey", @"advanced_settings_folder"];
        [settingsConfig setValueForField:@"mdsIconName", 119736542]; // Hard-coded in `MDSIconNameString`
        [settingsConfig setValueForField:@"badgeCount", 0];

        LSTableViewCellConfig *settingsCell = [[self getTableViewCellConfigs:@[settingsConfig] shouldRenderCMPresence:NO] firstObject];
        [settingsCell setValueForField:@"actionHandler", ^{ [self showTweakSettings]; }];

        [cellConfigs insertObject:[[cellConfigs lastObject] copy] atIndex:0]; // Space cell
        [cellConfigs insertObject:settingsCell atIndex:0];
    }

    return cellConfigs;
}

%new(v@:)
- (void)showTweakSettings {
    isDarkMode = MSHookIvar<NSInteger>(self.navigationController, "_statusBarStyleFromTheme") == 1;
    SNSettingsViewController *settingsController = [[SNSettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsController animated:YES];
}

%end

// v458.0.0
%hook MDSNavigationController
%property (nonatomic, retain) UIBarButtonItem *eyeItem;
%property (nonatomic, retain) UIBarButtonItem *settingsItem;

- (void)viewWillAppear:(BOOL)arg1 {
    if (!self.settingsItem && [[self childViewControllerForUserInterfaceStyle] isKindOfClass:%c(MSGSettingsViewController)]) {
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

    if (showTheEyeButton && !self.eyeItem && [[self childViewControllerForUserInterfaceStyle] isKindOfClass:%c(MSGInboxViewController)]) {
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
MSGModelInfo actionStandardInfo = {};
MSGModelADTInfo actionStandardADTInfo = {
    .name = "MSGStoryOverlayProfileViewAction",
    .subtype = 0
};

Class actionTypeSaveClass;
MSGModelInfo actionTypeSaveInfo = {
    .name = "MSGStoryViewerOverflowMenuActionTypeSave",
    .numberOfFields = 0,
    .fieldInfo = nil,
    .resultSet = nil,
    .var4 = YES,
    .var5 = nil
};
MSGModelADTInfo actionTypeSaveADTInfo = {
    .name = "MSGStoryViewerOverflowMenuActionType",
    .subtype = 2
};

Class (* MSGModelDefineClass)(MSGModelInfo *);
%hookf(Class, MSGModelDefineClass, MSGModelInfo *info) {
    Class modelClass = %orig;

    SwitchCStr (info->name) {
        CaseCEqual ("MSGStoryOverlayProfileViewActionStandard") {
            actionStandardClass = modelClass;
            actionStandardInfo = *info;
            break;
        }

        CaseCEqual ("MSGStoryViewerOverflowMenuActionTypeSave") {
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

        case 5 ... 6: {
            switch (type - (MessengerVersion() <= 458.0)) {
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
    NSUInteger type = *(&modelInfo->fieldInfo->type_0 + 0x4 * index) % 256;
    MSGModelTypes values = MSHookIvar<MSGModelTypes>(self, "_fieldValues");

    if (index >= modelInfo->numberOfFields) return @"Out of fields.";

    switch (type) {
        case 0: return @(get<bool>(values[index]));
        case 1: return @(get<int>(values[index]));
        case 2: return @(get<long long>(values[index]));
        case 3: return @(get<double>(values[index]));
        case 4: return @(get<float>(values[index]));

        case 5 ... 8: {
            switch (type - (MessengerVersion() <= 458.0)) {
                case 4: return [NSValue valueWithPointer:get<void *>(values[index])]; // Struct in v458.0.0
                case 5: return get<id>(values[index]);
                case 6: return [get<MSGModelWeakObjectContainer *>(values[index]) value];
                case 7: return (__bridge id)get<void *>(values[index]);
                case 8: return NSStringFromSelector(*get<SEL *>(values[index]));
                default: break;
            }
        }

        case 9 ... 13: return get<id>(values[index]);
        default: break;
    }

    return nil;
}

%new(@@:)
- (NSMutableDictionary *)debugMSGModel {
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
            @"type" : [NSString stringWithFormat:@"type: %lu - %@ (%s)", type, typeLookup(encoding, type), encoding],
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

- (BOOL)collectionView:(id)arg1 shouldSelectItemAtIndexPath:(id)arg2 {
    UIButton *hdToggleButton = MSHookIvar<UIButton *>(self, "_hdToggleButton");
    if (alwaysSendHdPhotos && [hdToggleButton state] == 0) {
        [self _stopHDAnimationAndToggleHD];
    }

    return %orig;
}

%end

#pragma mark - Audio / Video call confirmation

%hook MSGNavigationCoordinator_LSNavigationCoordinatorProxy

%new(v@:@?)
- (void)presentAlertWithCompletion:(void (^)(BOOL confirmed))completion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:localizedStringForKey(@"CALL_CONFIRMATION_TITLE") message:localizedStringForKey(@"CALL_CONFIRMATION_MESSAGE") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:localizedStringForKey(@"CONFIRM") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        completion(YES);
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:localizedStringForKey(@"CANCEL") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completion(NO);
    }]];

    [self presentViewController:alert presentationStyle:UIModalPresentationNone animated:YES completion:nil];
}

%end

id (* LSRTCValidateCallIntentForKey)(NSString *, id, LSRTCCallIntentValidatorParams *);
%hookf(id, LSRTCValidateCallIntentForKey, NSString *key, id context, LSRTCCallIntentValidatorParams *params) {
    MSGNavigationCoordinator_LSNavigationCoordinatorProxy *navigationCoordinator = [[params callIntent] navigationCoordinator];
    if (!callConfirmation || ![key isEqual:@"rtc_integrity_joiner_transparency"]) return %orig;

    [navigationCoordinator presentAlertWithCompletion:^(BOOL confirmed) {
        if (confirmed) %orig;
    }];

    return nil;
}

#pragma mark - Disable read receipts

%group MCINotificationCenterPostNotification

void *(* MCINotificationCenterPostNotification)(id, NSString *, NSString *, NSMutableDictionary *);
%hookf(void *, MCINotificationCenterPostNotification, id notifCenter, NSString *event, NSString *taskID, id content) {
    if (disableReadReceipts && [[content valueForKey:@"MCDNotificationTaskLabelsListKey"] isEqual:@[@"tam_thread_mark_read"]]) {
        return nil;
    }

    return %orig;
}

%end

// v458.0.0
%group MCINotificationCenterPostStrictNotification

void *(* MCINotificationCenterPostStrictNotification)(NSUInteger, id, NSString *, NSString *, NSMutableDictionary *);
%hookf(void *, MCINotificationCenterPostStrictNotification, NSUInteger type, id notifCenter, NSString *event, NSString *taskID, NSMutableDictionary *content) {
    if (disableReadReceipts && [[content valueForKey:@"MCDNotificationTaskLabelsListKey"] isEqual:@[@"tam_thread_mark_read"]]) {
        return nil;
    }

    return %orig;
}

%end

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

- (void)startTimer {
    if (!disableStorySeenReceipts) return %orig;

    // Here we simply invoke [super startTimer] to do the timming job
    struct objc_super superInfo = {
        .receiver = self,
        .super_class = %c(LSStoryBucketViewControllerBase)
    };

    void (* startTimerSuper)(struct objc_super *, SEL) = (void (*)(struct objc_super *, SEL))objc_msgSendSuper;
    startTimerSuper(&superInfo, @selector(startTimer));
}

- (void)replyBarWillPlayStoryFromBeginning:(id)arg1 {
    if (!neverReplayStoryAfterReacting) {
        %orig;
    }
}

%end

#pragma mark - Disable typing indicator

%group MCQTamClientTypingIndicatorStart

void (* MCQTamClientTypingIndicatorStart)();
%hookf(void, MCQTamClientTypingIndicatorStart) {
    if (!disableTypingIndicator) return %orig;
}

%end

#pragma mark - Extend story video upload duration

%group MSGAVFoundationEstimateMaxVideoDurationInputCreate

id (* MSGAVFoundationEstimateMaxVideoDurationInputCreate)(MSGMediaVideoPhasset *, NSUInteger, NSInteger, id, id);
%hookf(id, MSGAVFoundationEstimateMaxVideoDurationInputCreate, MSGMediaVideoPhasset *videoAsset, NSUInteger maxVideoResolution, NSInteger maxFileSizeInBytes, id roundingFactorInSeconds, id completion) {
    if (extendStoryVideoUploadLength) MSHookIvar<CGFloat>([videoAsset asset], "_duration") = 1.0f; // max ≈ 13 mins
    return %orig;
}

%end

// v458.0.0
%group MSGCSessionedMobileConfig

BOOL (* MSGCSessionedMobileConfigGetBoolean)(id, MSGCSessionedMobileConfig *, BOOL, BOOL);
%hookf(BOOL, MSGCSessionedMobileConfigGetBoolean, id context, MSGCSessionedMobileConfig *config, BOOL arg3, BOOL arg4) {
    if (extendStoryVideoUploadLength && strcmp(config->subKey, "replace_system_trimmer") == 0) {
        return YES;
    }

    return %orig;
}

CGFloat (* MSGCSessionedMobileConfigGetDouble)(id, MSGCSessionedMobileConfig *, BOOL, BOOL);
%hookf(CGFloat, MSGCSessionedMobileConfigGetDouble, id context, MSGCSessionedMobileConfig *config, BOOL arg3, BOOL arg4) {
    if (extendStoryVideoUploadLength && strcmp(config->subKey, "max_story_duration") == 0) {
        return 600.0f; // 10 mins
    }

    return %orig;
}

%end

#pragma mark - Hide notes row | Hide search bar

%hook MSGThreadListDataSource

- (instancetype)initWithViewRendererContext:(id)context mailbox:(id)mailbox config:(MSGThreadListConfig *)config {
    [config setValueForField:@"shouldShowSearch", !hideSearchBar];
    [config setValueForField:@"shouldShowInboxUnit", !hideNotesRow];
    return %orig;
}

%end

#pragma mark - Hide notification badges in chat top bar | Keyboard state after entering chat | Disable long press to change theme

%hook MSGThreadViewController

- (instancetype)initWithMailbox:(id)arg1 threadQueryKey:(id)arg2 threadSessionLifecycle:(id)arg3 threadNavigationData:(id)arg4 navigationEntryPoint:(int)arg5 options:(MSGThreadViewControllerOptions *)options metricContextsContainer:(id)arg7 datasource:(id)arg8 {
    MSGThreadViewOptions *viewOptions = [options viewOptions];

    [viewOptions setValueForField:@"shouldHideBadgeInBackButton", hideNotifBadgesInChat];

    if (![keyboardStateAfterEnterChat isEqual:@"ADAPTIVE"]) {
        [viewOptions setValueForField:@"onOpenKeyboardState", [keyboardStateAfterEnterChat isEqual:@"ALWAYS_EXPANDED"] ? 2 : 1];
    }

    return %orig;
}

- (void)messageListViewControllerDidLongPressBackground:(id)arg1 {
    if (!disableLongPressToChangeChatTheme) %orig;
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

#pragma mark - Hide tabs in tab bar

static BOOL hideTabBar = NO;

%hook LSTabBarDataSource

- (instancetype)initWithDependencies:(id)dependencies inboxLoadedCompletion:(id)completion {
    LSTabBarDataSource *data = %orig;
    NSMutableArray *items = [MSHookIvar<NSArray *>(data, "_tabBarItems") mutableCopy];
    NSMutableArray *itemsInfo = [MSHookIvar<NSArray <MSGTabBarItemInfo *> *>(data, "_tabBarItemInfos") mutableCopy];
    NSArray *removedItems = @[hidePeopleTab ? @"tabbar-people" : @"", hideStoriesTab ? @"tabbar-stories" : @""];

    for (MSGTabBarItemInfo *info in [itemsInfo reverseObjectEnumerator]) {
        if ([removedItems containsObject:[[info props] accessibilityIdentifierText]]) {
            if ([itemsInfo count] > 2) {
                [itemsInfo removeObject:info];
                [items removeObject:info];
            } else {
                hideTabBar = YES;
                break;
            }
        }
    }

    [data setValue:itemsInfo forKey:@"_tabBarItemInfos"];
    [data setValue:items forKey:@"_tabBarItems"];
    return data;
}

%end

%hook MDSTabBarController

- (void)_prepareTabBar {
    if (!hideTabBar) %orig;
}

%end

#pragma mark - Hide typing indicator

%hook MSGThreadRowCell

- (BOOL)_isTypingWithModel:(id)arg1 {
    return [@[@"IN_THREAD_LIST_ONLY", @"BOTH"] containsObject:hideTypingIndicator] ? NO : %orig;
}

// v458.0.0
- (BOOL)_isTypingWithModel:(id)arg1 mailbox:(id)arg2 {
    return [@[@"IN_THREAD_LIST_ONLY", @"BOTH"] containsObject:hideTypingIndicator] ? NO : %orig;
}

%end

%hook MSGMessageListViewModelGenerator

- (void)didLoadThreadModel:(id)arg1 threadViewModelMap:(id)arg2 threadSessionIdentifier:(id)arg3 messageModels:(NSMutableArray <MSGTempMessageListItemModel *> *)models threadParticipants:(id)arg6 attributionIDV2:(id)arg7 loadMoreStateOlder:(int)arg8 loadMoreStateNewer:(int)arg9 didLoadNewIsland:(BOOL)arg10 modelFetchedTimeInSeconds:(CGFloat)arg11 completion:(id)arg12 {
    if ([@[@"IN_CHAT_ONLY", @"BOTH"] containsObject:hideTypingIndicator] && [[[models lastObject] messageId] isEqual:@"typing_indicator"]) {
        [models removeLastObject];
    }

    %orig;
}

// v458.0.0
- (void)didLoadThreadModel:(id)arg1 threadViewModelMap:(id)arg2 threadSessionIdentifier:(id)arg3 messageModels:(NSMutableArray <MSGTempMessageListItemModel *> *)models threadParticipants:(id)arg5 attributionIDV2:(id)arg6 loadMoreStateOlder:(int)arg7 loadMoreStateNewer:(int)arg8 didLoadNewIsland:(BOOL)arg9 completion:(id)arg10 {
    if ([@[@"IN_CHAT_ONLY", @"BOTH"] containsObject:hideTypingIndicator] && [[[models lastObject] messageId] isEqual:@"typing_indicator"]) {
        [models removeLastObject];
    }

    %orig;
}

%end

#pragma mark - Remove ads

%hook MSGInboxAdsUserScopedPlugin

- (id)MSGInboxAdsUnitFetcher_MSGFetchInboxUnit:(id)arg1 {
    return noAds ? nil : %orig;
}

%end

// v458.0.0
%hook MSGThreadListDataSource

- (NSArray *)inboxRows {
    NSMutableArray *currentRows = [%orig mutableCopy];
    if ([self isInitializationComplete] && noAds && [currentRows count] > 0) {
        MSGThreadListUnitsSate *unitsState = MSHookIvar<MSGThreadListUnitsSate *>(self, "_unitsState");
        NSMutableDictionary *units = [unitsState unitKeyToUnit];
        MSGInboxUnit *adUnit = [units objectForKey:@"ads_renderer"];
        NSUInteger adUnitIndex = [[adUnit positionInThreadList] belowThreadIndex] + 2;
        BOOL isOffline = [units objectForKey:@"qp"];

        if (adUnit && adUnitIndex + isOffline < [currentRows count]) {
            [currentRows removeObjectAtIndex:adUnitIndex + isOffline];
        }
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

        if (MessengerVersion() > 458.0) {
            actionTypeSave = [actionTypeSaveClass newADTModelWithInfo:&actionTypeSaveInfo adtInfo:&actionTypeSaveADTInfo];
            actionStandard = [actionStandardClass newADTModelWithInfo:&actionStandardInfo adtInfo:&actionStandardADTInfo];
        } else {
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

    MSImageRef LSEngineRef = getImageRef(@"LightSpeedEngine.framework/LightSpeedEngine");
    MSImageRef LSCoreRef = getImageRef(@"LightSpeedCore.framework/LightSpeedCore");

    if (MessengerVersion() > 458.0) {
        MCQTamClientTypingIndicatorStart = (void (*)())MSFindSymbol(LSEngineRef, "_MCQTamClientTypingIndicatorStart");
        %init(MCQTamClientTypingIndicatorStart);

        LSRTCValidateCallIntentForKey = (id (*)(NSString *, id, LSRTCCallIntentValidatorParams *))MSFindSymbol(LSCoreRef, "_LSRTCValidateCallIntentForKey");
        MSGModelDefineClass = (Class (*)(MSGModelInfo *))MSFindSymbol(LSEngineRef, "_MSGModelDefineClass");

        MCINotificationCenterPostNotification = (void *(*)(id, NSString *, NSString *, NSMutableDictionary *))MSFindSymbol(LSEngineRef, "_MCINotificationCenterPostNotification");
        %init(MCINotificationCenterPostNotification);

        MSGAVFoundationEstimateMaxVideoDurationInputCreate = (id (*)(MSGMediaVideoPhasset *, NSUInteger, NSInteger, id, id))MSFindSymbol(LSEngineRef, "_MSGAVFoundationEstimateMaxVideoDurationInputCreate");
        %init(MSGAVFoundationEstimateMaxVideoDurationInputCreate);
    } else {
        LSRTCValidateCallIntentForKey = (id (*)(NSString *, id, LSRTCCallIntentValidatorParams *))MSFindSymbol(LSCoreRef, "_LSRTCValidateCallIntentForKey");
        MSGModelDefineClass = (Class (*)(MSGModelInfo *))MSFindSymbol(LSCoreRef, "_MSGModelDefineClass");

        MCINotificationCenterPostStrictNotification = (void *(*)(NSUInteger, id, NSString *, NSString *, NSMutableDictionary *))MSFindSymbol(LSCoreRef, "_MCINotificationCenterPostStrictNotification");
        %init(MCINotificationCenterPostStrictNotification);

        MSGCSessionedMobileConfigGetBoolean = (BOOL (*)(id, MSGCSessionedMobileConfig *, BOOL, BOOL))MSFindSymbol(LSCoreRef, "_MSGCSessionedMobileConfigGetBoolean");
        MSGCSessionedMobileConfigGetDouble = (CGFloat (*)(id, MSGCSessionedMobileConfig *, BOOL, BOOL))MSFindSymbol(LSCoreRef, "_MSGCSessionedMobileConfigGetDouble");
        %init(MSGCSessionedMobileConfig);
    }

    %init;
}
