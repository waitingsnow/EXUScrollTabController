//
//  EXUScrollTabController.m
//  chacha
//
//  Created by 王广威 on 2017/2/28.
//  Copyright © 2017年 EXUTECH. All rights reserved.
//

#import "EXUScrollTabController.h"

#import <objc/runtime.h>

static NSString * const ID = @"CONTENTCELL";

#define EXUScreenW ([[UIScreen mainScreen] bounds].size.width)
#define EXUScreenH ([[UIScreen mainScreen] bounds].size.height)

@interface EXUScrollTabController ()<UICollectionViewDataSource, UICollectionViewDelegate>

/** 内容滚动视图 */
@property (nonatomic, weak) UICollectionView *contentScrollView;

/** 当前选中的控制器 */
@property (nonatomic, weak) UIViewController *currentController;

/** 当前过渡的控制器 */
@property (nonatomic, weak) UIViewController *tempController;

@end

@implementation EXUScrollTabController

#pragma mark - 初始化
- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers {
	if (self = [super init]) {
		[viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[self addChildViewController:obj];
		}];
	}
	return self;
}

#pragma mark - 控制器view生命周期方法
- (void)viewDidLoad {
	[super viewDidLoad];
	self.automaticallyAdjustsScrollViewInsets = NO;
	self.view.backgroundColor = [UIColor whiteColor];
	
	[self.view addSubview:self.contentScrollView];
	self.contentScrollView.frame = self.view.bounds;
	self.contentScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.contentScrollView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
	self.currentController = self.childViewControllers[self.currentIndex];
}

#pragma mark - 懒加载
// 懒加载内容滚动视图
- (UIScrollView *)contentScrollView {
	if (_contentScrollView == nil) {
		// 创建布局
		UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
		layout.minimumInteritemSpacing = 0;
		layout.minimumLineSpacing = 0;
		layout.itemSize = CGSizeMake(EXUScreenW, EXUScreenH);
		layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		
		UICollectionView *contentScrollView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
		contentScrollView.backgroundColor = [UIColor whiteColor];
		// 设置内容滚动视图
		contentScrollView.pagingEnabled = YES;
		contentScrollView.showsHorizontalScrollIndicator = NO;
		contentScrollView.showsVerticalScrollIndicator = NO;
		contentScrollView.delegate = self;
		contentScrollView.dataSource = self;
		// 注册cell
		[contentScrollView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:ID];
		
		_contentScrollView = contentScrollView;
	}
	return _contentScrollView;
}

#pragma mark - 设置当前选中的控制器
- (void)setCurrentIndex:(NSInteger)currentIndex {
	
	if (_currentIndex != currentIndex) {
		_currentIndex = currentIndex;
		if (self.viewLoaded) {
			// 内容滚动视图滚动到对应位置
			[self.contentScrollView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
		}
	}
}

#pragma mark - 刷新界面方法
// 更新界面
- (void)refreshDisplay {
	[self.contentScrollView reloadData];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.childViewControllers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ID forIndexPath:indexPath];
	
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController *vc = self.childViewControllers[indexPath.item];
	[vc beginAppearanceTransition:YES animated:NO];
	[cell.contentView addSubview:vc.view];
	vc.view.frame = cell.contentView.bounds;
	vc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	self.tempController = vc;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController *vc = self.childViewControllers[indexPath.item];
	
	[vc.view removeFromSuperview];
	[vc endAppearanceTransition];
	self.tempController = nil;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[_currentController beginAppearanceTransition:NO animated:NO];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	_currentIndex = scrollView.contentOffset.x / EXUScreenW;
	_currentController = self.childViewControllers[self.currentIndex];
	[_currentController endAppearanceTransition];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
	CGPoint targetOffset = *targetContentOffset;
	NSUInteger targetIndex = targetOffset.x / EXUScreenW;
	UIViewController *targetVC = self.childViewControllers[targetIndex];
	if (targetVC == self.currentController) {
		[_currentController endAppearanceTransition];
		[_currentController beginAppearanceTransition:YES animated:NO];
		
		[_tempController endAppearanceTransition];
		[_tempController beginAppearanceTransition:NO animated:NO];
	}
}

@end

typedef enum : NSUInteger {
	EXUViewStateUnload,
	EXUViewStateLoaded,
	EXUViewStateWillAppear,
	EXUViewStateDidAppear,
	EXUViewStateWillDisappear,
	EXUViewStateDidDisappear,
} EXUViewState;


@interface UIViewController (EXULifeCycle)

@property (nonatomic, assign) EXUViewState exu_viewState;

@end

@implementation UIViewController (EXULifeCycle)

+ (void)exchangeInstanceMethod1:(SEL)method1 method2:(SEL)method2
{
	method_exchangeImplementations(class_getInstanceMethod(self, method1), class_getInstanceMethod(self, method2));
}

+ (void)load {
	[self exchangeInstanceMethod1:@selector(viewDidLoad) method2:@selector(exu_viewDidLoad)];
	[self exchangeInstanceMethod1:@selector(viewWillAppear:) method2:@selector(exu_viewWillAppear:)];
	[self exchangeInstanceMethod1:@selector(viewDidAppear:) method2:@selector(exu_viewDidAppear:)];
	[self exchangeInstanceMethod1:@selector(viewWillDisappear:) method2:@selector(exu_viewWillDisappear:)];
	[self exchangeInstanceMethod1:@selector(viewDidDisappear:) method2:@selector(exu_viewDidDisappear:)];
	
}

- (void)exu_viewDidLoad {
	[self exu_viewDidLoad];
	self.exu_viewState = EXUViewStateLoaded;
}
- (void)exu_viewWillAppear:(BOOL)animated {
	[self exu_viewWillAppear:animated];
	self.exu_viewState = EXUViewStateWillAppear;
}
- (void)exu_viewDidAppear:(BOOL)animated {
	[self exu_viewDidAppear:animated];
	self.exu_viewState = EXUViewStateDidAppear;
}
- (void)exu_viewWillDisappear:(BOOL)animated {
	[self exu_viewWillDisappear:animated];
	self.exu_viewState = EXUViewStateWillDisappear;
}
- (void)exu_viewDidDisappear:(BOOL)animated {
	[self exu_viewDidDisappear:animated];
	self.exu_viewState = EXUViewStateDidDisappear;
}

- (void)setExu_viewState:(EXUViewState)exu_viewState {
	objc_setAssociatedObject(self, @selector(exu_viewState), @(exu_viewState), OBJC_ASSOCIATION_ASSIGN);
}

- (EXUViewState)exu_viewState {
	return [objc_getAssociatedObject(self, _cmd) unsignedIntegerValue];
}

@end

@implementation UIViewController (EXUScrollTabController)

- (EXUScrollTabController *)scrollTabController {
	UIResponder *scrollTabController = self.nextResponder;
	while (scrollTabController) {
		if ([scrollTabController isKindOfClass:[EXUScrollTabController class]]) {
			return (EXUScrollTabController *)scrollTabController;
		}
		scrollTabController = scrollTabController.nextResponder;
	}
	return nil;
}

@end

@interface UINavigationController (EXUScrollEnableSwitch)


@end

@implementation UINavigationController (EXUScrollEnableSwitch)

+ (void)load {
	[self exchangeInstanceMethod1:@selector(pushViewController:animated:) method2:@selector(exu_pushViewController:animated:)];
	[self exchangeInstanceMethod1:@selector(popViewControllerAnimated:) method2:@selector(exu_popViewControllerAnimated:)];
}


- (void)exu_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
	[self exu_pushViewController:viewController animated:animated];
	if (self.parentViewController == self.scrollTabController) {
		self.scrollTabController.contentScrollView.scrollEnabled = NO;
	}
}

- (UIViewController *)exu_popViewControllerAnimated:(BOOL)animated {
	UIViewController *popedVC = [self exu_popViewControllerAnimated:animated];
	if (self.parentViewController == self.scrollTabController && self.childViewControllers.count == 1) {
		self.scrollTabController.contentScrollView.scrollEnabled = YES;
	}
	return popedVC;
}

@end

