//
//  ViewController.m
//  MFSpringViewDemo
//
//  Created by Lyman Li on 2018/11/25.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import "MFSpringView.h"

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet MFSpringView *springView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topLineSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLineSpace;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupButtons];
    
    self.topLineSpace.constant = 200;
    self.bottomLineSpace.constant = 300;
}

#pragma mark - Private

- (void)setupButtons {
    self.topButton.layer.borderWidth = 1;
    self.topButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.topButton addGestureRecognizer:[[UIPanGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(actionPanTop:)]];
    
    self.bottomButton.layer.borderWidth = 1;
    self.bottomButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.bottomButton addGestureRecognizer:[[UIPanGestureRecognizer alloc]
                                             initWithTarget:self
                                             action:@selector(actionPanBottom:)]];
}

#pragma mark - Action

- (void)actionPanTop:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.view];
    self.topLineSpace.constant += translation.y;
    [pan setTranslation:CGPointZero inView:self.view];
}

- (void)actionPanBottom:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.view];
    self.bottomLineSpace.constant += translation.y;
    [pan setTranslation:CGPointZero inView:self.view];
}

#pragma mark - IBAction

- (IBAction)sliderValueDidChanged:(UISlider *)sender {
    [self.springView stretchingFromStartY:0.3
                                   toEndY:0.7
                            withNewHeight:0.4 * ((sender.value) + 0.5)];
}

@end
