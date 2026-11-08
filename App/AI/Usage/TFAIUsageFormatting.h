#import <Foundation/Foundation.h>
#import "../../DylixI18n.h"
#import <CoreFoundation/CoreFoundation.h>
#import <math.h>

// Display-only decimal SI units. Ledgers, calculations and APIs retain integers.
static inline NSString *TFAITokenCountString(id count) {
    if (![count isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)count)==CFBooleanGetTypeID()) return DXLoc(@"未报告");
    NSDecimalNumber *value=[NSDecimalNumber decimalNumberWithString:[count stringValue]];
    if ([value isEqual:NSDecimalNumber.notANumber] || [value compare:NSDecimalNumber.zero]==NSOrderedAscending || !isfinite([count doubleValue])) return DXLoc(@"未报告");
    NSDecimalNumber *thousand=[NSDecimalNumber decimalNumberWithString:@"1000"];
    NSDecimalNumberHandler *rounding=[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:2 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    NSArray *suffixes=@[@"",@"K",@"M",@"B"];
    NSUInteger unit=0;
    while(unit+1<suffixes.count && [value compare:thousand]!=NSOrderedAscending){value=[value decimalNumberByDividingBy:thousand];unit++;}
    NSDecimalNumber *rounded=[value decimalNumberByRoundingAccordingToBehavior:rounding];
    if(unit && unit+1<suffixes.count && [rounded compare:thousand]!=NSOrderedAscending){value=[value decimalNumberByDividingBy:thousand];unit++;}
    NSNumberFormatter *format=[NSNumberFormatter new];format.locale=[[NSLocale alloc]initWithLocaleIdentifier:@"en_US_POSIX"];format.numberStyle=NSNumberFormatterDecimalStyle;format.usesGroupingSeparator=NO;format.minimumFractionDigits=0;format.maximumFractionDigits=unit?2:0;format.roundingMode=NSNumberFormatterRoundHalfUp;
    return [[format stringFromNumber:value] stringByAppendingString:suffixes[unit]]?:DXLoc(@"未报告");
}
