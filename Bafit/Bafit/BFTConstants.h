//
//  BFTConstants.h
//  Bafit
//
//  Created by Joseph Pecoraro on 10/23/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "ExtendedNSLog.h"
#import <Crashlytics/Crashlytics.h>

#ifndef Bafit_BFTConstants_h
#define Bafit_BFTConstants_h

#define kOrangeColor [UIColor colorWithRed:255/255.0 green:161/255.0 blue:0/255.0 alpha:1]
#define kFuturaFont @"Futura-Medium"

#ifdef DEBUG
#define NSLog(args...) ExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);
#else
#define NSLog(...) CLS_LOG(__VA_ARGS__)
#endif

#endif
