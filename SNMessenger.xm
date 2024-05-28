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

static void reloadPrefs() {
    settings = getCurrentSettings();

    noAds = [[settings objectForKey:@"noAds"] ?: @(YES) boolValue];
    showTheEyeButton = [[settings objectForKey:@"showTheEyeButton"] ?: @(YES) boolValue];

    alwaysSendHdPhotos = [[settings objectForKey:@"alwaysSendHdPhotos"] ?: @(YES) boolValue];
    disableReadReceipts = [[settings objectForKey:@"disableReadReceipts"] ?: @(NO) boolValue];
    disableLongPressToChangeChatTheme = [[settings objectForKey:@"disableLongPressToChangeChatTheme"] ?: @(NO) boolValue];
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

#pragma mark - Settings page, button to quickly disable/enable read receipts

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
MSGModelInfo actionTypeSaveInfo = {"MSGStoryViewerOverflowMenuActionTypeSave", 0, nil, nil, YES};

Class (*MSGModelDefineClass)(MSGModelInfo *);
%hookf(Class, MSGModelDefineClass, MSGModelInfo *info) {
    Class modelClass = %orig;
    SWITCH (info->name) {
        CASE ("MSGStoryOverlayProfileViewActionStandard") { // adtValueSubtype = 0
            actionStandardClass = modelClass;
            actionStandardInfo = *info;
            break;
        }

        CASE ("MSGStoryViewerOverflowMenuActionTypeSave") { // adtValueSubtype = 2
            actionTypeSaveClass = actionTypeSaveClass ?: modelClass;
            break;
        }

        DEFAULT {
            break;
        }
    }

    return modelClass;
}

%hook MSGModel

%new(Q@:@)
- (NSUInteger)indexOfField:(NSString *)name {
    MSGModelInfo *info = MSHookIvar<MSGModelInfo *>(self, "_modelInfo");
    NSUInteger count = 0, offset = 0x0uLL;

    while (count < info->numberOfFields) {
        if ([name isEqual:*(&info->fieldInfo->field_0 + offset)]) return count;
        offset += 0x4uLL;
        count++;
    };

    return 0;
}

%new(v@:B@)
- (void)setBoolValue:(BOOL)value forField:(NSString *)name {
    [self setBoolValue:value forFieldIndex:[self indexOfField:name]];
}

%new(v@:q@)
- (void)setInt64Value:(NSInteger)value forField:(NSString *)name {
    [self setInt64Value:value forFieldIndex:[self indexOfField:name]];
}

%new(v@:@@)
- (void)setObjectValue:(id)value forField:(NSString *)name {
    [self setObjectValue:value forFieldIndex:[self indexOfField:name]];
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

#pragma mark - Disable read receipts, hide notifications badge in back button in chat

%hook MSGThreadViewController

- (instancetype)initWithMailbox:(id)arg1 threadQueryKey:(id)arg2 threadSessionLifecycle:(id)arg3 threadNavigationData:(id)arg4 navigationEntryPoint:(int)arg5 options:(MSGThreadViewControllerOptions *)options metricContextsContainer:(id)arg7 datasource:(id)arg8 {
    MSGThreadViewOptions *viewOptions = [options viewOptions];

    //TODO: fake seen receipt
    [viewOptions setBoolValue:disableReadReceipts forField:@"disableReadReceipts"];
    [viewOptions setBoolValue:hideNotifBadgesInChat forField:@"shouldHideBadgeInBackButton"];

    if (![keyboardStateAfterEnterChat isEqual:@"ADAPTIVE"]) {
        [viewOptions setInt64Value:[keyboardStateAfterEnterChat isEqual:@"ALWAYS_EXPANDED"] ? 2 : 1 forField:@"onOpenKeyboardState"];
    }

    return %orig;
}

- (void)messageListViewControllerDidLongPressBackground:(id)arg1 {
    if (!disableLongPressToChangeChatTheme) %orig;
}

%end

#pragma mark - Disable stories preview

%hook MSGStoryCardVideoAutoPlayDelegate

- (void)mediaViewController:(LSMediaViewController *)mediaController loadedWithContentView:(id)arg2 actualContentSize:(CGSize *)arg3 {
    return disableStoriesPreview ? [mediaController reset] : %orig;
}

%end

#pragma mark - Disable story seen receipt, disable story replay after reacting

%hook LSStoryBucketViewController
%property (nonatomic, assign) BOOL isMyStory;
%property (nonatomic, assign) CGFloat duration;

- (void)startTimer {
    self.isMyStory = [self.ownerId isEqual:[[%c(FBAnalytics) sharedAnalytics] userFBID]];
    if (!disableStorySeenReceipts || self.isMyStory) {
        return %orig;
    }

    LSVideoPlayerView *playerView = MSHookIvar<LSVideoPlayerView *>(self, "_videoPlayerView");
    self.duration = [self getDurationFromPlayerView:playerView];

    [MSHookIvar<NSTimer *>(self, "_storyTimer") invalidate]; // Stop last timer
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(_updateProgressIndicator) userInfo:nil repeats:YES];
    [self setValue:timer forKey:@"_storyTimer"]; // Set new timer
}

- (CGFloat)storyDuration {
    return disableStorySeenReceipts && !self.isMyStory ? self.duration : %orig;
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
    if ([@[@"INBOX_ONLY", @"BOTH"] containsObject:disableTypingIndicator] && [[[models lastObject] messageId] isEqual:@"typing_indicator"]) {
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

#pragma mark - Hide search bar

%hook UINavigationController

- (void)_createAndAttachSearchPaletteForTransitionToTopViewControllerIfNecesssary:(id)viewController {
    if (hideSearchBar && [viewController isKindOfClass:%c(MSGInboxViewController)]) {
        return;
    }
    %orig;
}

%end

#pragma mark - Hide status bar when viewing story (notch-less only)

%hook LSMediaViewerViewController

- (BOOL)prefersStatusBarHidden {
    BOOL isCorrectController = [MSHookIvar<id>(self, "_contentController") isKindOfClass:%c(LSStoryViewerContentController)];
    return hideStatusBarWhenViewingStory && isCorrectController && !isNotch() ? YES : %orig;
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

#pragma mark - Remove ads, hide notes row

%hook MSGThreadListDataSource

//TODO: Find a better way
- (NSArray *)inboxRows {
    NSMutableArray *currentRows = [%orig mutableCopy];
    if ((noAds || hideNotesRow) && [currentRows count] > 0) {
        MSGThreadListUnitsSate *unitsState = MSHookIvar<MSGThreadListUnitsSate *>(self, "_unitsState");
        NSMutableDictionary *units = [unitsState unitKeyToUnit];
        MSGInboxUnit *adUnit = [units objectForKey:@"ads_renderer"];
        NSUInteger adUnitIndex = [[adUnit positionInThreadList] belowThreadIndex];

        if (noAds && adUnitIndex + 2 < [currentRows count]) [currentRows removeObjectAtIndex:adUnitIndex + 2];
        if (hideNotesRow) [currentRows removeObjectAtIndex:0];

        [[unitsState unitKeyToViewControllerMap] removeObjectForKey:@"ads_renderer"];
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
        actionTypeSaveClass = actionTypeSaveClass ?: MSGModelDefineClass(&actionTypeSaveInfo);
        MSGStoryViewerOverflowMenuActionTypeSave *actionTypeSave = [actionTypeSaveClass newADTModelWithInfo:&actionTypeSaveInfo adtValueSubtype:2];

        MSGStoryOverlayProfileViewActionStandard *actionStandard = [actionStandardClass newADTModelWithInfo:&actionStandardInfo adtValueSubtype:0];
        [actionStandard setObjectValue:actionTypeSave forField:@"type"];

        [actions insertObject:actionStandard atIndex:2];
        [self setValue:actions forKey:@"_overflowActions"];
    }

    %orig;
}

%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    reloadPrefs();

    // Thanks PoomSmart
    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Frameworks/LightSpeedCore.framework/LightSpeedCore", [NSBundle mainBundle].bundlePath];
    NSBundle *bundle = [NSBundle bundleWithPath:frameworkPath];
    if (!bundle.loaded) [bundle load];
    MSImageRef ref = MSGetImageByName([frameworkPath UTF8String]);
    MSGModelDefineClass = (Class (*)(MSGModelInfo *))MSFindSymbol(ref, "_MSGModelDefineClass");

    %init;
}
