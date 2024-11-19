#import <variant>
#import <vector>
#import <AVKit/AVKit.h>
#import "Utilities.h"

using namespace std;

@interface NSThread (Debug)
+ (NSString *)ams_symbolicatedCallStackSymbols;
@end

// A trick to use "case/switch" with string
#define SwitchStr(s) for (const char *__s__ = (s) ; ; )
#define CaseEqual(str) if (strcmp(str, __s__) == 0)
#define CaseStart(str) if (strncmp(str, __s__, strlen(str)) == 0)
#define Default

//==========  TYPE LOOKUP TABLE (NEW)  ==========||==========  TYPE LOOKUP TABLE (OLD)  ==========//
//                                               ||                                               //
//   0: Bool                   7: MCFTypeRef     ||   0: Bool                   7: Weak Object    //
//   1: (Unsigned) Int32       8: SEL            ||   1: (Unsigned) Int32       8: MCFTypeRef     //
//   2: (Unsigned) Int64       9: CGRect         ||   2: (Unsigned) Int64       9: CGRect         //
//   3: Double                10: CGSize         ||   3: Double                10: CGSize         //
//   4: Float                 11: CGPoint        ||   4: Float                 11: CGPoint        //
//   5: Strong Object         12: NSRange        ||   5: Struct                12: NSRange        //
//   6: Weak Object           13: UIEdgeInsets   ||   6: Strong Object         13: UIEdgeInsets   //
//                                               ||                                               //
//===============================================||===============================================//

NSString *(^typeLookup)(const char *, NSUInteger) = ^NSString *(const char *encoding, NSUInteger type) {
    SwitchStr (encoding) {
        CaseEqual ("B") { return @"Bool"; }
        CaseEqual ("i") { return @"Int"; }
        CaseEqual ("I") { return @"Unsigned Int32"; }
        CaseEqual ("q") { return @"Int64"; }
        CaseEqual ("Q") { return @"Unsigned Int64"; }
        CaseEqual ("d") { return @"Double"; }
        CaseEqual ("f") { return @"Float"; }
        CaseEqual (":") { return @"Selector"; }

        CaseEqual ("@") {
            if (type < 8) {
                switch (type - !IS_IOS_OR_NEWER(iOS_15_1)) {
                    case 5: return @"Strong Object";
                    case 6: return @"Weak Object";
                }
            }

            switch (type) {
                case  9: return @"CGRect";
                case 10: return @"CGSize";
                case 11: return @"CGPoint";
                case 12: return @"NSRange";
                case 13: return @"UIEdgeInsets";
                default: break;
            }
        }

        CaseStart ("^{") {
            switch (type) {
                case 5: return @"Struct"; // v458.0.0

                case 7:
                case 8: {
                    return @"MCFTypeRef";
                }

                default: break;
            }
        }

        Default {
            RLog(@"encoding: %s | type: %lu", encoding, type);
            return @"";
        }
    }
};

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
//  ...
} MSGModelFieldInfo;

typedef struct {
    const char *name;
    NSUInteger numberOfFields;
    MSGModelFieldInfo *fieldInfo;
    struct MSGCQLResultSetInfo *resultSet;
    BOOL var4;
    void *var5;
} MSGModelInfo;

typedef struct {
    const char *name;
    NSInteger subtype;
} MSGModelADTInfo;

@interface MSGModel : NSObject
+ (instancetype)newADTModelWithInfo:(MSGModelInfo *)info adtInfo:(MSGModelADTInfo *)adtInfo;
+ (instancetype)newADTModelWithInfo:(MSGModelInfo *)info adtValueSubtype:(NSInteger)adtValueSubtype; // v458.0.0
+ (instancetype)newWithModelInfo:(MSGModelInfo *)info; // adtValueSubtype = -1
- (void)setBoolValue:(BOOL)value forFieldIndex:(NSUInteger)index;
- (void)setInt64Value:(NSInteger)value forFieldIndex:(NSUInteger)index;
- (void)setObjectValue:(id)value forFieldIndex:(NSUInteger)index;
- (void)setValueForField:(NSString *)name, /* value: */ ...;
- (id)valueAtFieldIndex:(NSUInteger)index;
- (NSMutableDictionary *)debugMSGModel;
@end

@interface MSGModelWeakObjectContainer : NSObject
- (id)value;
@end

using MSGModelTypes = vector<variant<bool, int, long long, double, float, id, MSGModelWeakObjectContainer *, void *, SEL *>, allocator<variant<bool, int, long long, double, float, id, MSGModelWeakObjectContainer *, void *, SEL *>>>;

@interface MSGInboxViewController : UIViewController
@end

@interface MDSNavigationController : UINavigationController
@property (nonatomic, retain) UIBarButtonItem *eyeItem;
@property (nonatomic, retain) UIBarButtonItem *settingsItem;
@end

@interface LSVideoPlayerView : UIView
- (CMTime)duration;
@end

@interface LSContactListViewController : UIViewController
@end

@interface LSTabBarDataSource : NSObject
@end

@interface FBAnalytics : NSObject
+ (instancetype)sharedAnalytics;
- (NSString *)userFBID;
@end

@interface LSMediaPickerViewController : UIViewController
- (void)_stopHDAnimationAndToggleHD;
@end

@interface MSGStoryOverlayProfileViewActionStandard : MSGModel
@end

@interface MSGStoryViewerOverflowMenuActionTypeSave : MSGModel
@end

@interface LSStoryOverlayProfileView : UIView
@end

@interface LSStoryBucketViewControllerBase : UIViewController
@property (nonatomic, copy, readwrite) NSString *ownerId;
- (CGFloat)getDurationFromPlayerView:(LSVideoPlayerView *)playerView;
- (CGFloat)storyDuration;
- (void)_updateProgressIndicator;
@end

@interface LSStoryBucketViewController : LSStoryBucketViewControllerBase
@property (nonatomic, assign) BOOL isSelfStory;
@property (nonatomic, assign) CGFloat duration;
@end

@interface MSGStoryViewerBucketModel : MSGModel
- (int)bucketType;
@end

@interface MSGTempMessageListItemModel : NSObject
- (NSString *)messageId;
@end

@interface MSGThreadListDataSource : NSObject
- (BOOL)isInitializationComplete;
@end

@interface MSGThreadViewOptions : MSGModel
@end

@interface MSGThreadViewControllerOptions : MSGModel
- (MSGThreadViewOptions *)viewOptions;
@end

@interface PLUIEditVideoViewController : UIViewController
- (void)_trimVideo:(UIBarButtonItem *)arg1;
@end

@interface PHObject : NSObject
@end

@interface PHAsset : PHObject
@property (nonatomic, readonly, assign) CGFloat duration;
@end

@interface MSGMessageListViewModelGenerator : NSObject
@end

@interface MSGThreadListUnitsSate : MSGModel
- (NSMutableDictionary *)unitKeyToUnit;
@end

@interface MSGInboxUnitPositionInThreadList : MSGModel
- (NSInteger)belowThreadIndex;
@end

@interface MSGInboxUnit : MSGModel
- (MSGInboxUnitPositionInThreadList *)positionInThreadList;
@end

@interface MSGStoryCardToolbox : MSGModel
@end

typedef struct {
    const char *key;
    const char *subKey;
} MSGCSessionedMobileConfig;

@interface MDSTabBarController : UITabBarController
@end

@interface MDSTabBarItemProps : MSGModel
- (NSString *)accessibilityIdentifierText;
@end
@interface MSGTabBarItemInfo : MSGModel
- (MDSTabBarItemProps *)props;
@end

@interface MSGNavigationCoordinator_LSNavigationCoordinatorProxy : NSObject
- (void)dismissViewControllerAnimated:(BOOL)arg1 completion:(id)arg2;
- (void)presentAlertWithCompletion:(void (^)(BOOL))completion;
- (void)presentViewController:(id)arg1 presentationStyle:(NSInteger)arg2 animated:(BOOL)arg3 completion:(id)arg4;
@end

@interface LSRTCCallIntent : MSGModel
- (MSGNavigationCoordinator_LSNavigationCoordinatorProxy *)navigationCoordinator;
@end

@interface LSRTCCallIntentValidatorParams : MSGModel
- (LSRTCCallIntent *)callIntent;
@end

@interface MSGMediaVideoPhasset : MSGModel
- (id)asset;
@end
