//
//  MFGLKView.h
//  MFSpringViewDemo
//
//  Created by Lyman Li on 2019/2/3.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@class EAGLContext;
@protocol MFGLKViewDelegate;

typedef NS_ENUM(NSUInteger, MFGLKViewDrawableDepthFormat) {
    MFGLKViewDrawableDepthFormatNone = 0,
    MFGLKViewDrawableDepthFormat16,
};

@interface MFGLKView : UIView {
    EAGLContext   *context;
    GLuint        defaultFrameBuffer;
    GLuint        colorRenderBuffer;
    GLuint        depthRenderBuffer;
    GLint         drawableWidth;
    GLint         drawableHeight;
}

@property (nonatomic, weak) id <MFGLKViewDelegate> delegate;
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, readonly) NSInteger drawableWidth;
@property (nonatomic, readonly) NSInteger drawableHeight;
@property (nonatomic) MFGLKViewDrawableDepthFormat drawableDepthFormat;

- (void)display;

@end


#pragma mark - MFGLKViewDelegate

@protocol MFGLKViewDelegate <NSObject>

@required
- (void)glkView:(MFGLKView *)view drawInRect:(CGRect)rect;

@end
