//
//  BFTLeftRightSegue.m
//  Bafit
//
//  Created by Joseph Pecoraro on 10/3/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTLeftRightSegue.h"

@implementation BFTLeftRightSegue

-(void)perform {
    UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
    UIViewController *destinationController = (UIViewController*)[self destinationViewController];
    
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:sourceViewController.navigationController.viewControllers];
    [viewControllers removeObjectAtIndex:viewControllers.count -1];
    
    [viewControllers addObject:destinationController];
    [viewControllers addObject:sourceViewController];
    [sourceViewController.navigationController setViewControllers:viewControllers animated:NO];
    [sourceViewController.navigationController popViewControllerAnimated:YES];
    
    //[sourceViewController.navigationController pushViewController:destinationController animated:NO];
}


@end
