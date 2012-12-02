//
//  WMLabel.h
//  Wheelmap
//
//  Created by npng on 11/27/12.
//  Copyright (c) 2012 Sozialhelden e.V. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kWMLabelFontTypeRegular,
    kWMLabelFontTypeItalic,
    kWMLabelFontTypeBold
} WMLabelFontType;

@interface WMLabel : UILabel

@property (nonatomic) WMLabelFontType fontType;
@property (nonatomic) CGFloat fontSize;

@end