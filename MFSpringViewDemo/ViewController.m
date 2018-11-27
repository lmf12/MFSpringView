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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - IBAction

- (IBAction)sliderValueDidChanged:(UISlider *)sender {
    [self.springView stretchingFromStartY:0.3
                                   toEndY:0.7
                            withNewHeight:0.4 * ((sender.value) + 0.5)];
}

@end
