#import <AVKit/AVKit.h>
#import <stdarg.h>
#import "Utilities.h"
#import "Settings/SNSettingsViewController.h"

@interface MDSNavigationController : UINavigationController
@property (nonatomic, retain) UIBarButtonItem *eyeItem;
@property (nonatomic, retain) UIBarButtonItem *settingsItem;
@end

@interface LSVideoPlayerView : UIView
- (CMTime)duration;
@end

@interface LSComposerView : UIView
@end

@interface LSContactListViewController : UIViewController
@end

@interface LSTabBarDataSource : NSObject
@end

@interface LSMediaViewerViewController : UIViewController
- (void)updateStatusBarVisibility:(BOOL)visibility;
@end

@interface LSStoryOverlayViewController : UIViewController
@end

@interface FBAnalytics : NSObject
+ (instancetype)sharedAnalytics;
- (NSString *)userFBID;
@end

@interface MDSTabBarController : UITabBarController
@end

@interface LSMediaPickerViewController : UIViewController
- (void)_stopHDAnimationAndToggleHD;
@end

//============   TYPE LOOKUP TABLE   =============//
//                                                //
//   0: Bool                    7: Weak Object    //
//   1: (Unsigned) Int32        8: MCFTypeRef     //
//   2: (Unsigned) Int64        9: CGRect         //
//   3: Double                 10: CGSize         //
//   4: Float                  11: CGPoint        //
//   5: Struct                 12: NSRange        //
//   6: Strong Object          13: UIEdgeInsets   //
//                                                //
//================================================//

typedef struct {
    NSString *field_0;
    const char *encoding_0;
    NSUInteger sizeof_0;
    NSUInteger type_0;
    NSString *field_1;
    const char *encoding_1;
    NSUInteger sizeof_1;
    NSUInteger type_1;
    NSString *field_2;
    const char *encoding_2;
    NSUInteger sizeof_2;
    NSUInteger type_2;
    NSString *field_3;
    const char *encoding_3;
    NSUInteger sizeof_3;
    NSUInteger type_3;
    NSString *field_4;
    const char *encoding_4;
    NSUInteger sizeof_4;
    NSUInteger type_4;
    NSString *field_5;
    const char *encoding_5;
    NSUInteger sizeof_5;
    NSUInteger type_5;
    NSString *field_6;
    const char *encoding_6;
    NSUInteger sizeof_6;
    NSUInteger type_6;
    NSString *field_7;
    const char *encoding_7;
    NSUInteger sizeof_7;
    NSUInteger type_7;
    NSString *field_8;
    const char *encoding_8;
    NSUInteger sizeof_8;
    NSUInteger type_8;
    NSString *field_9;
    const char *encoding_9;
    NSUInteger sizeof_9;
    NSUInteger type_9;
    NSString *field_10;
    const char *encoding_10;
    NSUInteger sizeof_10;
    NSUInteger type_10;
// ... (up to 90 fields)
} MSGModelFieldInfo;

typedef struct {
    const char *name;
    NSUInteger numberOfFields;
    MSGModelFieldInfo *fieldInfo;
    struct MSGCQLResultSetInfo *resultSet;
    BOOL var4;
} MSGModelInfo;

// A trick to use "case/switch" with string
#define CASE(str) if (strcmp(__s__, str) == 0)
#define SWITCH(s) for (const char *__s__ = (s); ; )
#define DEFAULT

@interface MSGModel : NSObject
+ (instancetype)newADTModelWithInfo:(MSGModelInfo *)info adtValueSubtype:(NSInteger)adtValueSubtype;
+ (instancetype)newWithModelInfo:(MSGModelInfo *)info; // adtValueSubtype = -1
- (void)setBoolValue:(BOOL)value forFieldIndex:(NSUInteger)index;
- (void)setInt64Value:(NSInteger)value forFieldIndex:(NSUInteger)index;
- (void)setObjectValue:(id)value forFieldIndex:(NSUInteger)index;
- (void)setValueForField:(NSString *)name, /* value: */ ...;
@end

@interface MSGStoryOverlayProfileViewActionStandard : MSGModel
@end

@interface MSGStoryViewerOverflowMenuActionTypeSave : MSGModel
@end

@interface LSStoryBucketViewControllerBase : UIViewController
@property (nonatomic, copy, readwrite) NSString *ownerId;
- (CGFloat)getDurationFromPlayerView:(LSVideoPlayerView *)playerView;
- (CGFloat)storyDuration;
- (void)_updateProgressIndicator;
@end

@interface LSStoryBucketViewController : LSStoryBucketViewControllerBase
@property (nonatomic, assign) BOOL isMyStory;
@property (nonatomic, assign) CGFloat duration;
- (void)handleOverflowAction:(MSGModel *)arg1 storyId:(NSInteger)arg2 completion:(id)arg3;
@end

@interface MSGStoryViewerBucketModel : MSGModel
- (int)bucketType;
- (NSString *)ownerId;
@end

@interface MSGTempMessageListItemModel : NSObject
- (NSString *)messageId;
- (NSInteger)threadFbId;
@end

@interface LSStoryOverlayProfileView : UIView
@end

@interface MSGThreadListDataSource : NSObject
- (BOOL)isInitializationComplete;
@end

@interface MDSTabBarItemProps : MSGModel
- (NSString *)accessibilityIdentifierText;
@end

@interface MSGTabBarItemInfo : MSGModel
- (MDSTabBarItemProps *)props;
@end

@interface LSViewController : UIViewController
@end

@interface MSGInboxRowUnit : MSGModel
- (LSViewController *)controller;
@end

@interface MSGThreadViewOptions : MSGModel
@end

@interface MSGThreadViewControllerOptions : MSGModel
- (MSGThreadViewOptions *)viewOptions;
@end

@interface MSGThreadViewController : UIViewController
@end

@interface MSGStoryCardVideoAutoPlayDelegate : NSObject
@end

@interface LSStoryViewerContentController : NSObject
@end

@interface PLUIEditVideoViewController : UIViewController
- (void)_trimVideo:(UIBarButtonItem *)arg1;
@end

@interface PHObject : NSObject
@end

@interface PHAsset : PHObject
@property (nonatomic, readonly, assign) CGFloat duration;
@end

@interface MSGThreadRowCell : UITableViewCell
@end

@interface MSGMessageListViewModelGenerator : NSObject
@end

@interface MSGThreadListUnitsSate : MSGModel
- (NSMutableDictionary *)unitKeyToUnit;
- (NSMutableDictionary *)unitKeyToViewControllerMap;
@end

@interface MSGInboxUnitPositionInThreadList : MSGModel
- (NSInteger)belowThreadIndex;
@end

@interface MSGInboxUnit : MSGModel
- (MSGInboxUnitPositionInThreadList *)positionInThreadList;
@end

@interface MSGStoryCardToolbox : MSGModel
@end
