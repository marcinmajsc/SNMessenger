#import "SNOptionsListViewController.h"

@implementation SNOptionsListViewController

- (instancetype)initWithOptionsListData:(SNCellModel *)optionsListData {
    if (self = [super init]) {
        _optionsListData = optionsListData;

        self.navigationItem.titleView = [[UIView alloc] init];
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        titleLabel.text = localizedStringForKey(_optionsListData.titleKey);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.navigationItem.titleView addSubview:titleLabel];

        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.topAnchor constraintEqualToAnchor:self.navigationItem.titleView.topAnchor],
            [titleLabel.leadingAnchor constraintEqualToAnchor:self.navigationItem.titleView.leadingAnchor],
            [titleLabel.trailingAnchor constraintEqualToAnchor:self.navigationItem.titleView.trailingAnchor],
            [titleLabel.bottomAnchor constraintEqualToAnchor:self.navigationItem.titleView.bottomAnchor],
        ]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Init table view
    _tableView = [[TOInsetGroupedTableView alloc] initWithFrame:[self.view frame]];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];

    // Setup table rows
    [self initTableData];
}

- (void)initTableData {
    _tableData = [@[] mutableCopy];

    for (NSString *labelKey in _optionsListData.listOptions) {
        SNCellModel *model = [[SNCellModel alloc] initWithType:Option labelKey:labelKey];
        model.prefKey = _optionsListData.prefKey;
        [_tableData addObject:model];
    }
}

- (NSInteger)numberOfSectionsInTableView:(TOInsetGroupedTableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(TOInsetGroupedTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tableData count];
}

- (SNTableViewCell *)tableView:(TOInsetGroupedTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SNCellModel *optionData = [_tableData objectAtIndex:indexPath.row];

    NSString *cellIdentifier = [NSString stringWithFormat:@"SNTableViewCell - type: %lu - labelKey: %@ - subtitleKey: %@", optionData.type, optionData.labelKey, optionData.subtitleKey];
    SNTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[SNTableViewCell alloc] initWithData:optionData reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (CGFloat)tableView:(TOInsetGroupedTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SNCellModel *cellData = [_tableData objectAtIndex:indexPath.row];
    return cellData.subtitleKey ? 173.0f / 3.0f : 52.0f;
}

- (NSString *)tableView:(TOInsetGroupedTableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"SNMessenger, made with 💖";
}

- (void)tableView:(TOInsetGroupedTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView reloadData];
}

@end
