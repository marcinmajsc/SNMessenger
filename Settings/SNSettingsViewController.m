#import "SNOptionsListViewController.h"
#import "SNSettingsViewController.h"

@implementation SNSettingsViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:localizedStringForKey(@"APPLY") style:UIBarButtonItemStyleDone target:self action:@selector(close)];

        self.navigationItem.titleView = [[UIView alloc] init];
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:17.5f weight:UIFontWeightBold];
        _titleLabel.text = @"Advanced Settings";
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.navigationItem.titleView addSubview:_titleLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.topAnchor constraintEqualToAnchor:self.navigationItem.titleView.topAnchor],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.navigationItem.titleView.leadingAnchor],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.navigationItem.titleView.trailingAnchor],
            [_titleLabel.bottomAnchor constraintEqualToAnchor:self.navigationItem.titleView.bottomAnchor],
        ]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set original settings so we can deal with changes later
    _originalSettings = getCurrentSettings();

    // Init table view
    _tableView = [[TOInsetGroupedTableView alloc] initWithFrame:[self.view frame]];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];

    // Setup table rows
    [self initTableData];
}

- (void)initTableData {
    //======================== GENERAL OPTIONS =========================//

    SNCellModel *noAdsCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"NO_ADS"];
    noAdsCell.subtitleKey = @"NO_ADS_DESCRIPTION";
    noAdsCell.prefKey = @"noAds";
    noAdsCell.defaultValue = YES;

    SNCellModel *showTheEyeCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"SHOW_THE_EYE_BUTTON"];
    showTheEyeCell.subtitleKey = @"QUICK_ENABLE_DISABLE_READ_RECEIPT";
    showTheEyeCell.prefKey = @"showTheEyeButton";
    showTheEyeCell.defaultValue = YES;

    //========================== CHAT OPTIONS ==========================//

    SNCellModel *alwaysSendHdPhotosCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"ALWAYS_SEND_HD_PHOTOS"];
    alwaysSendHdPhotosCell.subtitleKey = @"ALWAYS_SEND_HD_PHOTOS_DESCRIPTION";
    alwaysSendHdPhotosCell.prefKey = @"alwaysSendHdPhotos";
    alwaysSendHdPhotosCell.defaultValue = YES;

    SNCellModel *disableLongPressToChangeThemeCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"DISABLE_LONG_PRESS_TO_CHANGE_THEME"];
    disableLongPressToChangeThemeCell.prefKey = @"disableLongPressToChangeTheme";

    SNCellModel *disableReadReceiptsCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"DISABLE_READ_RECEIPTS"];
    disableReadReceiptsCell.prefKey = @"disableReadReceipts";

    SNCellModel *disableTypingIndicatorCell = [[SNCellModel alloc] initWithType:OptionsList labelKey:@"DISABLE_TYPING_INDICATOR"];
    disableTypingIndicatorCell.prefKey = @"disableTypingIndicator";
    disableTypingIndicatorCell.titleKey = @"DISABLE_TYPING_INDICATOR_TITLE";
    disableTypingIndicatorCell.listOptions = @[@"NOWHERE", @"INBOX_ONLY", @"CHAT_SECTIONS_ONLY", @"BOTH"];
    disableTypingIndicatorCell.defaultValues = [@[@"NOWHERE"] mutableCopy];

    SNCellModel *hideNotifBadgesInChatCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"HIDE_NOTIF_BADGES_IN_CHAT"];
    hideNotifBadgesInChatCell.subtitleKey = @"HIDE_NOTIF_BADGES_IN_CHAT_DESCRIPTION";
    hideNotifBadgesInChatCell.prefKey = @"hideNotifBadgesInChat";

    SNCellModel *keyboardStateAfterEnterChatCell = [[SNCellModel alloc] initWithType:OptionsList labelKey:@"KEYBOARD_STATE_AFTER_ENTER_CHAT"];
    keyboardStateAfterEnterChatCell.prefKey = @"keyboardStateAfterEnterChat";
    keyboardStateAfterEnterChatCell.titleKey = @"KEYBOARD_STATE_AFTER_ENTER_CHAT_TITLE";
    keyboardStateAfterEnterChatCell.listOptions = @[@"ADAPTIVE", @"ALWAYS_EXPANDED", @"ALWAYS_COLLAPSED"];
    keyboardStateAfterEnterChatCell.defaultValues = [@[@"ADAPTIVE"] mutableCopy];

    //========================= STORY OPTIONS ==========================//

    SNCellModel *canSaveFriendsStoriesCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"CAN_SAVE_FRIENDS_STORIES"];
    canSaveFriendsStoriesCell.prefKey = @"canSaveFriendsStories";
    canSaveFriendsStoriesCell.defaultValue = YES;

    SNCellModel *disableStoriesPreviewCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"DISABLE_STORIES_PREVIEW"];
    disableStoriesPreviewCell.prefKey = @"disableStoriesPreview";

    SNCellModel *disableStorySeenReceiptsCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"DISABLE_STORY_SEEN_RECEIPTS"];
    disableStorySeenReceiptsCell.prefKey = @"disableStorySeenReceipts";
    disableStorySeenReceiptsCell.defaultValue = YES;

    SNCellModel *extendStoryVideoUploadLengthCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"EXTEND_STORY_VIDEO_UPLOAD_LENGTH"];
    extendStoryVideoUploadLengthCell.subtitleKey = @"EXTEND_STORY_VIDEO_UPLOAD_LENGTH_DESCRIPTION";
    extendStoryVideoUploadLengthCell.prefKey = @"extendStoryVideoUploadLength";

    SNCellModel *hideStatusBarWhenViewingStoryCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"HIDE_STATUS_BAR_WHEN_VIEWING_STORY"];
    hideStatusBarWhenViewingStoryCell.subtitleKey = @"HIDE_STATUS_BAR_WHEN_VIEWING_STORY_DESCRIPTION";
    hideStatusBarWhenViewingStoryCell.prefKey = @"hideStatusBarWhenViewingStory";
    hideStatusBarWhenViewingStoryCell.disabled = isNotch();

    SNCellModel *neverReplayStoryAfterReactingCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"NEVER_REPLAY_STORY_AFTER_REACTING"];
    neverReplayStoryAfterReactingCell.prefKey = @"neverReplayStoryAfterReacting";

    //=========================== UI OPTIONS ===========================//

    SNCellModel *hideCallsTabCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"HIDE_CALLS_TAB"];
    hideCallsTabCell.prefKey = @"hideCallsTab";
    hideCallsTabCell.isRestartRequired = YES;

    SNCellModel *hidePeopleTabCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"HIDE_PEOPLE_TAB"];
    hidePeopleTabCell.prefKey = @"hidePeopleTab";
    hidePeopleTabCell.isRestartRequired = YES;

    SNCellModel *hideStoriesTabCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"HIDE_STORIES_TAB"];
    hideStoriesTabCell.prefKey = @"hideStoriesTab";
    hideStoriesTabCell.isRestartRequired = YES;

    SNCellModel *hideNotesRowCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"HIDE_NOTES_ROW"];
    hideNotesRowCell.prefKey = @"hideNotesRow";

    SNCellModel *hideSearchBarCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"HIDE_SEARCH_BAR"];
    hideSearchBarCell.prefKey = @"hideSearchBar";
    hideSearchBarCell.isRestartRequired = YES;

    SNCellModel *hideSuggestedContactsInSearchCell = [[SNCellModel alloc] initWithType:Switch labelKey:@"HIDE_SUGGESTED_CONTACTS_IN_SEARCH"];
    hideSuggestedContactsInSearchCell.prefKey = @"hideSuggestedContactsInSearch";

    //=========================== SUPPORT ME ===========================//

    SNCellModel *sangNguyenCell = [[SNCellModel alloc] initWithType:Link labelKey:@"Nguyễn Anh Sáng 👨🏻‍💻"];
    sangNguyenCell.url = @"https://github.com/NguyenASang";
    sangNguyenCell.subtitleKey = @"NguyenASang";

    //TODO: Create report template
    SNCellModel *donationCell = [[SNCellModel alloc] initWithType:Link labelKey:@"DONATION"];
    donationCell.url = @"";
    donationCell.subtitleKey = @"BUY_ME_A_COFFEE";

    SNCellModel *foundABugCell = [[SNCellModel alloc] initWithType:Link labelKey:@"FOUND_A_BUG"];
    foundABugCell.url = @"";
    foundABugCell.subtitleKey = @"LEAVE_A_BUG_REPORT_ON_GITHUB";

    SNCellModel *featureRequestCell = [[SNCellModel alloc] initWithType:Link labelKey:@"FEATURE_REQUEST"];
    featureRequestCell.url = @"";
    featureRequestCell.subtitleKey = @"SUBMIT_YOUR_REQUEST_ON_GITHUB";

    SNCellModel *sourceCodeCell = [[SNCellModel alloc] initWithType:Link labelKey:@"SOURCE_CODE"];
    sourceCodeCell.url = @"https://github.com/NguyenASang/SNMessenger";
    sourceCodeCell.subtitleKey = @"Github";

    _tableData = @{
        @"0": @[
                noAdsCell,
                showTheEyeCell
            ],

        @"1": @[
                alwaysSendHdPhotosCell,
                disableLongPressToChangeThemeCell,
                disableReadReceiptsCell,
                disableTypingIndicatorCell,
                hideNotifBadgesInChatCell,
                keyboardStateAfterEnterChatCell
            ],

        @"2": @[
                canSaveFriendsStoriesCell,
                disableStoriesPreviewCell,
                disableStorySeenReceiptsCell,
                extendStoryVideoUploadLengthCell,
                hideStatusBarWhenViewingStoryCell,
                neverReplayStoryAfterReactingCell
            ],

        @"3": @[
                hideCallsTabCell,
                hidePeopleTabCell,
                hideStoriesTabCell,
                hideNotesRowCell,
                hideSearchBarCell,
                hideSuggestedContactsInSearchCell
            ],

        @"4": @[
                sangNguyenCell,
                donationCell,
                foundABugCell,
                featureRequestCell,
                sourceCodeCell
            ]
    };
}

- (void)pushViewControllerWithOptionsList {
    NSIndexPath *indexPath = _tableView.indexPathForSelectedRow;
    NSArray *dataRow = [_tableData valueForKey:[@(indexPath.section) stringValue]];
    SNCellModel *optionsListData = [dataRow objectAtIndex:indexPath.row];
    SNOptionsListViewController *viewController = [[SNOptionsListViewController alloc] initWithOptionsListData:optionsListData];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(TOInsetGroupedTableView *)tableView {
    return [_tableData count];
}

- (NSInteger)tableView:(TOInsetGroupedTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_tableData valueForKey:[@(section) stringValue]] count];
}

- (NSString *)tableView:(TOInsetGroupedTableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return localizedStringForKey(@"GENERAL_OPTIONS");
        case 1:
            return localizedStringForKey(@"CHAT_OPTIONS");
        case 2:
            return localizedStringForKey(@"STORY_OPTIONS");
        case 3:
            return localizedStringForKey(@"UI_OPTIONS");
        case 4:
            return localizedStringForKey(@"SUPPORT_ME");
        default:
            return nil;
    }
}

- (void)tableView:(TOInsetGroupedTableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.text = [self tableView:tableView titleForHeaderInSection:section];
        headerView.textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    }
}

- (SNTableViewCell *)tableView:(TOInsetGroupedTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *dataRow = [_tableData valueForKey:[@(indexPath.section) stringValue]];
    SNCellModel *cellData = [dataRow objectAtIndex:indexPath.row];

    NSString *cellIdentifier = [NSString stringWithFormat:@"SNTableViewCell - type: %lu - labelKey: %@ - subtitleKey: %@", cellData.type, cellData.labelKey, cellData.subtitleKey];
    SNTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[SNTableViewCell alloc] initWithData:cellData reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (CGFloat)tableView:(TOInsetGroupedTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *dataRow = [_tableData valueForKey:[@(indexPath.section) stringValue]];
    SNCellModel *cellData = [dataRow objectAtIndex:indexPath.row];
    return cellData.subtitleKey ? 173.0f / 3.0f : 52.0f;
}

- (NSString *)tableView:(TOInsetGroupedTableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == [_tableData count] - 1 ? @"SNMessenger, made with 💖" : nil;
}

- (void)tableView:(TOInsetGroupedTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *dataRow = [_tableData valueForKey:[@(indexPath.section) stringValue]];
    SNCellModel *cellData = [dataRow objectAtIndex:indexPath.row];
    if (cellData.type == Link) {
        UIApplication *app = [UIApplication sharedApplication];
        [app openURL:[NSURL URLWithString:cellData.url] options:@{} completionHandler:nil];
    }

    if (cellData.type == Button || cellData.type == OptionsList) {
        SEL selector = cellData.buttonAction;
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, selector);
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

- (void)close {
    NSDictionary *diffs = compareDictionaries(_originalSettings, getCurrentSettings());
    NSArray *diffKeys = [diffs allKeys];
    NSArray *tableValues = [_tableData allValues];

    for (NSArray *modelsArray in tableValues) {
        for (SNCellModel *model in modelsArray) {
            if ([diffKeys containsObject:model.prefKey] && model.isRestartRequired) {
                showRequireRestartAlert(self);
                return;
            }
        }
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
