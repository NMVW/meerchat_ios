//
//  UIImage+Color.h
//  Tize
//
//  Created by Joseph Pecoraro on 8/28/14.
//  Copyright (c) 2014 GrayWolfTechnologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Color)

+(UIImage*)imageWithColor: (UIColor *)color;
+(UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color;

@end
