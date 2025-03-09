#import "Headers/LSMediaPickerViewController.h"
#import "Headers/LSStoryOverlayProfileView.h"
#import "Headers/LSTabBarDataSource.h"
#import "Headers/LSVideoPlayerView.h"
#import "Headers/MDSNavigationController.h"
#import "Headers/MSGCommunityListViewController.h"
#import "Headers/MSGInboxViewController.h"
#import "Headers/MSGModel.h"
#import "Headers/MSGModelClasses.h"
#import "Headers/MSGModelWeakObjectContainer.h"
#import "Headers/MSGNavigationCoordinator_LSNavigationCoordinatorProxy.h"
#import "Headers/MSGTempMessageListItemModel.h"
#import "Utilities.h"
#import <variant>
#import <vector>

using namespace std;

@interface NSThread (Debug)
+ (NSString *)ams_symbolicatedCallStackSymbols;
@end

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

NSString *(^ typeLookup)(const char *, NSUInteger) = ^NSString *(const char *encoding, NSUInteger type) {
    SwitchCStr (encoding) {
        CaseCEqual ("B") { return @"Bool"; }
        CaseCEqual ("i") { return @"Int"; }
        CaseCEqual ("I") { return @"Unsigned Int32"; }
        CaseCEqual ("q") { return @"Int64"; }
        CaseCEqual ("Q") { return @"Unsigned Int64"; }
        CaseCEqual ("d") { return @"Double"; }
        CaseCEqual ("f") { return @"Float"; }
        CaseCEqual (":") { return @"Selector"; }

        CaseCEqual ("@") {
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

        CaseCStart ("^{") {
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

@interface MSGModel (SNMessenger)
- (NSMutableDictionary *)debugMSGModel;
- (id)valueAtFieldIndex:(NSUInteger)fieldIndex;
- (void)setValueForField:(NSString *)name, /* value: */ ...;
@end

using MSGModelTypes = vector<variant<bool, int, long long, double, float, id, MSGModelWeakObjectContainer *, void *, SEL *>, allocator<variant<bool, int, long long, double, float, id, MSGModelWeakObjectContainer *, void *, SEL *>>>;

@interface FBAnalytics : NSObject
+ (instancetype)sharedAnalytics;
- (NSString *)userFBID;
@end

@interface MSGThreadListDataSource : NSObject
- (BOOL)isInitializationComplete;
@end

typedef struct {
    const char *key;
    const char *subKey;
} MSGCSessionedMobileConfig;

@interface MSGCommunityListViewController (SNMessenger)
- (void)showTweakSettings;
@end

@interface MDSNavigationController (SNMessenger)
@property (nonatomic, retain) UIBarButtonItem *eyeItem;
@property (nonatomic, retain) UIBarButtonItem *settingsItem;
@end

@interface MSGNavigationCoordinator_LSNavigationCoordinatorProxy (SNMessenger)
- (void)presentAlertWithCompletion:(void (^)(BOOL))completion;
@end
