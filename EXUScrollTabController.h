//
//  EXUScrollTabController.h
//  chacha
//
//  Created by 王广威 on 2017/2/28.
//  Copyright © 2017年 EXUTECH. All rights reserved.
//

#import <UIKit/UIKit.h>

//typedef enum : NSUInteger {
//	EXU,
//	<#MyEnumValueB#>,
//	<#MyEnumValueC#>,
//} <#MyEnum#>;

@interface EXUScrollTabController : UIViewController

/**
 当前选中控制器的位置
 */
@property (nonatomic, assign) NSInteger currentIndex;

/**
 根据传入的控制器数组初始化
 */

- (instancetype)initWithViewControllers:(NSArray<UIViewController*>*)viewControllers;

/**
 刷新标题和整个界面(如果需要)，必须先确定所有的子控制器。
 */
- (void)refreshDisplay;

@end

@interface UIViewController (EXUScrollTabController)

- (EXUScrollTabController *)scrollTabController;

@end
