//
//  MFSpringView.h
//  MFSpringView
//
//  Created by Lyman Li on 2018/11/25.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface MFSpringView : GLKView

/**
 将区域拉伸或压缩为某个高度

 @param startY 开始的纵坐标位置
 @param endY 结束的纵坐标位置
 @param newHeight 新的高度
 */
- (void)stretchingFromStartY:(CGFloat)startY
                      toEndY:(CGFloat)endY
               withNewHeight:(CGFloat)newHeight;

@end
