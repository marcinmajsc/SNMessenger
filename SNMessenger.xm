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
static BOOL hideCallsTab;
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
    disableReadReceipts = [[settings objectForKey:@"disableReadReceipts"] ?: @(NO) boolValue];
    disableLongPressToChangeChatTheme = [[settings objectForKey:@"disableLongPressToChangeTheme"] ?: @(NO) boolValue];
    disableTypingIndicator = [[settings objectForKey:@"disableTypingIndicator"] ?: @[@"NOWHERE"] firstObject];
    hideNotifBadgesInChat = [[settings objectForKey:@"hideNotifBadgesInChat"] ?: @(NO) boolValue];
    keyboardStateAfterEnterChat = [[settings objectForKey:@"keyboardStateAfterEnterChat"] ?: @[@"ADAPTIVE"] firstObject];

    canSaveFriendsStories = [[settings objectForKey:@"canSaveFriendsStories"] ?: @(YES) boolValue];
    disableStoriesPreview = [[settings objectForKey:@"disableStoriesPreview"] ?: @(NO) boolValue];
    disableStorySeenReceipts = [[settings objectForKey:@"disableStorySeenReceipts"] ?: @(YES) boolValue];
    extendStoryVideoUploadLength = [[settings objectForKey:@"extendStoryVideoUploadLength"] ?: @(NO) boolValue];
    hideStatusBarWhenViewingStory = [[settings objectForKey:@"hideStatusBarWhenViewingStory"] ?: @(YES) boolValue];
    neverReplayStoryAfterReacting = [[settings objectForKey:@"neverReplayStoryAfterReacting"] ?: @(NO) boolValue];

    hideCallsTab = [[settings objectForKey:@"hideCallsTab"] ?: @(NO) boolValue];
    hidePeopleTab = [[settings objectForKey:@"hidePeopleTab"] ?: @(NO) boolValue];
    hideStoriesTab = [[settings objectForKey:@"hideStoriesTab"] ?: @(NO) boolValue];
    hideNotesRow = [[settings objectForKey:@"hideNotesRow"] ?: @(NO) boolValue];
    hideSearchBar = [[settings objectForKey:@"hideSearchBar"] ?: @(NO) boolValue];
    hideSuggestedContactsInSearch = [[settings objectForKey:@"hideSuggestedContactsInSearch"] ?: @(NO) boolValue];
}

#pragma mark - Settings page, Quick toggle to disable/enable read receipts

%hook MDSNavigationController
%property (nonatomic, retain) UIBarButtonItem *eyeItem;
%property (nonatomic, retain) UIBarButtonItem *settingsItem;

- (void)viewWillAppear:(BOOL)arg1 {
    if ([[self childViewControllerForUserInterfaceStyle] isKindOfClass:%c(MSGSettingsViewController)]) {
        UIButton *settingsButton = [[UIButton alloc] init];
        UIImage *settingsIcon = getTemplateImage(@"gear@3x");
        [settingsButton setImage:settingsIcon forState:UIControlStateNormal];
        [settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
        self.settingsItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
        self.settingsItem.style = UIBarButtonItemStyleDone;

        @try {
            self.navigationBar.topItem.leftBarButtonItems = @[self.navigationBar.topItem.customLeftItem, self.settingsItem];
        } @catch (id ex) {
            self.navigationBar.topItem.leftBarButtonItem = self.settingsItem;
        }
    }

    if (showTheEyeButton && [[self childViewControllerForUserInterfaceStyle] isKindOfClass:%c(MSGInboxViewController)]) {
        UIButton *eyeButton = [[UIButton alloc] init];
        UIImage *eyeIcon = getTemplateImage(disableReadReceipts ? @"no-see@3x" : @"see@3x");
        [eyeButton setImage:eyeIcon forState:UIControlStateNormal];
        [eyeButton addTarget:self action:@selector(handleEyeTap:) forControlEvents:UIControlEventTouchUpInside];
        self.eyeItem = [[UIBarButtonItem alloc] initWithCustomView:eyeButton];
        self.eyeItem.style = UIBarButtonItemStyleDone;

        self.navigationBar.topItem.rightBarButtonItems = @[self.navigationBar.topItem.customRightItem, self.eyeItem];
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
    UIImage *eyeIcon = getTemplateImage(!disableReadReceipts ? @"no-see@3x" : @"see@3x");
    [eyeButton setImage:eyeIcon forState:UIControlStateNormal];

    [settings setObject:[NSNumber numberWithBool:!disableReadReceipts] forKey:@"disableReadReceipts"];
    [settings writeToFile:getSettingsPlistPath() atomically:YES];
    notify_post(PREF_CHANGED_NOTIF);
}

%end

#pragma mark - Necessary hooks

Class actionStandardClass;
MSGModelInfo actionStandardInfo;

Class actionTypeSaveClass;
MSGModelInfo actionTypeSaveInfo = { "MSGStoryViewerOverflowMenuActionTypeSave", 0, nil, nil, YES };

Class (*MSGModelDefineClass)(MSGModelInfo *);
%hookf(Class, MSGModelDefineClass, MSGModelInfo *info) {
    Class modelClass = %orig;
    SWITCH (info->name) {
        CASE ("MSGStoryOverlayProfileViewActionStandard") { // adtValueSubtype = 0
            actionStandardClass = modelClass;
            actionStandardInfo = *info;
            break;
        }

        DEFAULT {
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

    while (index < info->numberOfFields) {
        if ([name isEqualToString:*(&info->fieldInfo->field_0 + offset)]) {
            type = (NSInteger)*(&info->fieldInfo->field_0 + offset + 0x3) % 256;
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

        case 6: {
            [self setObjectValue:va_arg(args, id) forFieldIndex:index];
            break;
        }

        default: {
            //RLog(@"type: %lu", type);
            break;
        }
    }

    va_end(args);
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

NSArray *(* MCFArrayCreateCopy)(NSMutableArray *);
%hookf(NSArray *, MCFArrayCreateCopy, NSMutableArray *array) {
    if ([array containsObject:@"tam_thread_mark_read"] && disableReadReceipts) {
        [array replaceObjectAtIndex:0 withObject:@""];
    }

    return %orig;
}

#pragma mark - Disable stories preview

%hook MSGCQLResultSetList

+ (instancetype)newWithIdentifier:(NSString *)identifier context:(MSGStoryCardToolbox *)context resultSet:(id)arg3 resultSetCount:(NSInteger)arg4 options:(void *)arg5 actionHandlers:(void *)arg6 impressionTrackingContext:(id)arg7 {
    if ([identifier isEqualToString:@"stories"]) {
        [context setValueForField:@"isVideoAutoplayEnabled", !disableStoriesPreview];
    }

    return %orig;
}

%end

#pragma mark - Disable story seen receipt, Disable story replay after reacting

%hook LSStoryBucketViewController
%property (nonatomic, assign) BOOL isSelfStory;
%property (nonatomic, assign) CGFloat duration;

- (void)startTimer {
    self.isSelfStory = [self.ownerId isEqualToString:[[%c(FBAnalytics) sharedAnalytics] userFBID]];
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

- (void)didLoadThreadModel:(id)arg1 threadViewModelMap:(id)arg2 threadSessionIdentifier:(id)arg3 messageModels:(NSMutableArray <MSGTempMessageListItemModel *> *)models threadParticipants:(id)arg5 attributionIDV2:(id)arg6 loadMoreStateOlder:(int)arg7 loadMoreStateNewer:(int)arg8 didLoadNewIsland:(BOOL)arg9 completion:(id)arg10 {
    if ([@[@"INBOX_ONLY", @"BOTH"] containsObject:disableTypingIndicator] && [[[models lastObject] messageId] isEqualToString:@"typing_indicator"]) {
        [models removeLastObject];
    }

    %orig;
}

%end

#pragma mark - Extend story video upload duration

%hook UIVideoEditorController

- (void)setVideoMaximumDuration:(CGFloat)arg1 {
    return extendStoryVideoUploadLength ? %orig(600.0f) : %orig;
}

%end

%hook PLUIEditVideoViewController

- (void)viewDidAppear:(BOOL)arg1 {
    %orig;
    if (extendStoryVideoUploadLength) {
        [self _trimVideo:nil];
    }
}

%end

#pragma mark - Hide notification badges in chat top bar, State of keyboard after entering chat, Disable long press to change theme

%hook MSGThreadViewController

- (instancetype)initWithMailbox:(id)arg1 threadQueryKey:(id)arg2 threadSessionLifecycle:(id)arg3 threadNavigationData:(id)arg4 navigationEntryPoint:(int)arg5 options:(MSGThreadViewControllerOptions *)options metricContextsContainer:(id)arg7 datasource:(id)arg8 {
    MSGThreadViewOptions *viewOptions = [options viewOptions];

    [viewOptions setValueForField:@"shouldHideBadgeInBackButton", hideNotifBadgesInChat];

    if (![keyboardStateAfterEnterChat isEqualToString:@"ADAPTIVE"]) {
        [viewOptions setValueForField:@"onOpenKeyboardState", [keyboardStateAfterEnterChat isEqualToString:@"ALWAYS_EXPANDED"] ? 2 : 1];
    }

    return %orig;
}

- (void)messageListViewControllerDidLongPressBackground:(id)arg1 {
    if (!disableLongPressToChangeChatTheme) %orig;
}

%end

#pragma mark - Hide search bar

%hook UINavigationController

- (void)_createAndAttachSearchPaletteForTransitionToTopViewControllerIfNecesssary:(id)viewController {
    if (hideSearchBar && [viewController isKindOfClass:%c(MSGInboxViewController)]) {
        return;
    }

    %orig;
}

%end

%hook MDSNavigationController

- (void)viewDidLoad {
    %orig;
    if (hideSearchBar) {
        [self setNavigationBarHidden:YES animated:NO];
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
        if ([featureIdentifier isEqualToString:@"universal_search_null_state"]) {
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
    NSArray *removedItems = @[hideCallsTab ? @"tabbar-calls" : @"", hidePeopleTab ? @"tabbar-people" : @"", hideStoriesTab ? @"tabbar-stories" : @""];

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

#pragma mark - Remove ads, Hide notes row

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
    if (canSaveFriendsStories && ![storyAuthorId isEqualToString:[[%c(FBAnalytics) sharedAnalytics] userFBID]] && [actions count] == 3) {
        actionTypeSaveClass = objc_lookUpClass("MSGStoryViewerOverflowMenuActionTypeSave") ?: MSGModelDefineClass(&actionTypeSaveInfo);
        MSGStoryViewerOverflowMenuActionTypeSave *actionTypeSave = [actionTypeSaveClass newADTModelWithInfo:&actionTypeSaveInfo adtValueSubtype:2];

        MSGStoryOverlayProfileViewActionStandard *actionStandard = [actionStandardClass newADTModelWithInfo:&actionStandardInfo adtValueSubtype:0];
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

    // Thanks PoomSmart
    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Frameworks/LightSpeedCore.framework/LightSpeedCore", [[NSBundle mainBundle] bundlePath]];
    NSBundle *bundle = [NSBundle bundleWithPath:frameworkPath];
    if (!bundle.loaded) [bundle load];
    MSImageRef ref = MSGetImageByName([frameworkPath UTF8String]);
    MCFArrayCreateCopy = (NSArray *(*)(NSMutableArray *))MSFindSymbol(ref, "_MCFArrayCreateCopy");
    MSGModelDefineClass = (Class (*)(MSGModelInfo *))MSFindSymbol(ref, "_MSGModelDefineClass");

    %init;
}
