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
@end
