#import "SNTableViewCell.h"

@implementation SNTableViewCell

- (instancetype)initWithData:(SNCellModel *)cellData reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        _cellData = cellData;
        _plistPath = getSettingsPlistPath();

        self.textLabel.text = localizedStringForKey(cellData.labelKey);
        self.textLabel.textColor = colorWithHexString(isDarkMode ? @"#F2F2F2" : @"#333333");
        self.detailTextLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        self.detailTextLabel.text = localizedStringForKey(_cellData.subtitleKey);
        self.detailTextLabel.textColor = colorWithHexString(isDarkMode ? @"#888888" : @"#828282");
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        if (cellData.disabled) {
            self.userInteractionEnabled = NO;
            self.textLabel.enabled = NO;
        }

        switch (cellData.type) {
            case Switch: {
                [self loadSwitcher];
                break;
            }

            case Button:
            case Link: {
                self.selectionStyle = UITableViewCellSelectionStyleDefault;
                self.accessoryType = UITableViewCellAccessoryNone;
                break;
            }

            case OptionsList: {
                self.selectionStyle = UITableViewCellSelectionStyleDefault;
                UIImageView *indicatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 24)];
                indicatorView.tintColor = colorWithHexString(isDarkMode ? @"#ffffff30" : @"#00000033");
                indicatorView.image = getTemplateImage(@"arrow@3x");
                self.accessoryView = indicatorView;

                _cellData.buttonAction = @selector(pushViewControllerWithOptionsList);
                _cellData.defaultValues = [self readPreferenceValueForKey:_cellData.prefKey] ?: _cellData.defaultValues;
                break;
            }

            case Option: {
                self.selectionStyle = UITableViewCellSelectionStyleDefault;
                [self loadOption];
                break;
            }

            default:
                break;
        }
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    switch (_cellData.type) {
        case Switch: {
            [self loadSwitcher];
            break;
        }

        case Option: {
            [self loadOption];
            break;
        }

        default:
            break;
    }
}

- (void)setSeparatorColor:(UIColor *)separatorColor {
    [super setSeparatorColor:colorWithHexString(isDarkMode ? @"#FFFFFF30" : @"#0000001E")];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        self.contentView.superview.backgroundColor = colorWithHexString(isDarkMode ? @"#FFFFFF23" : @"#0000000F");
    } else {
        self.contentView.superview.backgroundColor = colorWithHexString(isDarkMode ? @"#FFFFFF14" : @"#FFFFFF");
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (_cellData.type == Option && selected) {
        if (!_cellData.isMultipleChoices) {
            _cellData.defaultValues = [@[] mutableCopy];
        }

        NSString *newValue = _cellData.labelKey;
        if (![_cellData.defaultValues containsObject:newValue]) {
            [_cellData.defaultValues addObject:newValue];
        }

        [self setPreferenceValue:_cellData.defaultValues];
    }
}

- (void)loadOption {
    id savedValue = [self readPreferenceValueForKey:_cellData.prefKey];
    NSMutableArray *value = savedValue ?: _cellData.defaultValues;

    UIImageView *indicatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    indicatorView.tintColor = colorWithHexString(isDarkMode ? @"#429AFF" : @"#0A7CFF");
    indicatorView.image = getTemplateImage(@"tick@3x");

    self.accessoryView = [value containsObject:_cellData.labelKey] ? indicatorView : nil;
}

- (void)switchChanged:(UISwitch *)switchControl {
    [self setPreferenceValue:@([switchControl isOn])];
}

- (void)loadSwitcher {
    id savedValue = [self readPreferenceValueForKey:_cellData.prefKey];
    BOOL value = savedValue ? [savedValue boolValue] : _cellData.defaultValue;

    UISwitch *switchView = [[UISwitch alloc] init];
    [switchView setOn:value animated:NO];
    [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    if (_cellData.disabled) switchView.enabled = NO;
    self.accessoryView = switchView;
}

- (void)setPreferenceValue:(id)value {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:_plistPath] ?: [@{} mutableCopy];
    [settings setObject:value forKey:_cellData.prefKey];
    [settings writeToFile:_plistPath atomically:YES];
    notify_post(PREF_CHANGED_NOTIF);
}

- (id)readPreferenceValueForKey:(NSString *)prefKey {
    NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:_plistPath] ?: [@{} mutableCopy];
    return settings[prefKey];
}

@end
