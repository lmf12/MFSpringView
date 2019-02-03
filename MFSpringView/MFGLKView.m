//
//  MFGLKView.m
//  MFSpringViewDemo
//
//  Created by Lyman Li on 2019/2/3.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "MFGLKView.h"
#import <QuartzCore/QuartzCore.h>


@implementation MFGLKView

- (void)dealloc {
    // Make sure the receiver's OpenGL ES Context is not current
    if ([EAGLContext currentContext] == context)
    {
        [EAGLContext setCurrentContext:nil];
    }
    
    // Deletes the receiver's OpenGL ES Context
    context = nil;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)aContext {
    self = [super initWithFrame:frame];
    if (self) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.drawableProperties = @{
                                         kEAGLDrawablePropertyRetainedBacking : @(NO),
                                         kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
                                         };
        self.context = aContext;
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.drawableProperties = @{
                                         kEAGLDrawablePropertyRetainedBacking : @(NO),
                                         kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
                                         };
    }
    return self;
}

- (void)setContext:(EAGLContext *)aContext {
    if(context != aContext) {
        // Delete any buffers previously created in old Context
        [EAGLContext setCurrentContext:context];
        
        if (0 != defaultFrameBuffer) {
            glDeleteFramebuffers(1, &defaultFrameBuffer); // Step 7
            defaultFrameBuffer = 0;
        }
        
        if (0 != colorRenderBuffer) {
            glDeleteRenderbuffers(1, &colorRenderBuffer); // Step 7
            colorRenderBuffer = 0;
        }
        
        if (0 != depthRenderBuffer) {
            glDeleteRenderbuffers(1, &depthRenderBuffer); // Step 7
            depthRenderBuffer = 0;
        }
        
        context = aContext;
        
        if(nil != context) {  // Configure the new Context with required buffers
            context = aContext;
            [EAGLContext setCurrentContext:context];
            
            glGenFramebuffers(1, &defaultFrameBuffer);    // Step 1
            glBindFramebuffer(GL_FRAMEBUFFER, defaultFrameBuffer);
            
            glGenRenderbuffers(1, &colorRenderBuffer);    // Step 1
            glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
            
            // Attach color render buffer to bound Frame Buffer
            glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                                      GL_COLOR_ATTACHMENT0,
                                      GL_RENDERBUFFER,
                                      colorRenderBuffer);
            
            // Create any additional render buffers based on the
            // drawable size of defaultFrameBuffer
            [self layoutSubviews];
        }
    }
}

- (EAGLContext *)context {
    return context;
}

- (void)display {
    [EAGLContext setCurrentContext:self.context];
    glViewport(0, 0, (int)self.drawableWidth, (int)self.drawableHeight);
    
    [self drawRect:[self bounds]];
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawRect:(CGRect)rect {
    if(self.delegate) {
        [self.delegate glkView:self drawInRect:[self bounds]];
    }
}

- (void)layoutSubviews {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    // Make sure our context is current
    [EAGLContext setCurrentContext:self.context];
    
    // Initialize the current Frame Buffer’s pixel color buffer
    // so that it shares the corresponding Core Animation Layer’s
    // pixel color storage.
    [self.context renderbufferStorage:GL_RENDERBUFFER
                         fromDrawable:eaglLayer];
    
    
    if (0 != depthRenderBuffer) {
        glDeleteRenderbuffers(1, &depthRenderBuffer); // Step 7
        depthRenderBuffer = 0;
    }
    
    GLint currentDrawableWidth = (int)self.drawableWidth;
    GLint currentDrawableHeight = (int)self.drawableHeight;
    
    if(self.drawableDepthFormat !=
       MFGLKViewDrawableDepthFormatNone &&
       0 < currentDrawableWidth &&
       0 < currentDrawableHeight) {
        glGenRenderbuffers(1, &depthRenderBuffer); // Step 1
        glBindRenderbuffer(GL_RENDERBUFFER,        // Step 2
                           depthRenderBuffer);
        glRenderbufferStorage(GL_RENDERBUFFER,     // Step 3
                              GL_DEPTH_COMPONENT16,
                              currentDrawableWidth,
                              currentDrawableHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER,  // Step 4
                                  GL_DEPTH_ATTACHMENT,
                                  GL_RENDERBUFFER,
                                  depthRenderBuffer);
    }
    
    // Check for any errors configuring the render buffer
    GLenum status = glCheckFramebufferStatus(
                                             GL_FRAMEBUFFER) ;
    
    if(status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete frame buffer object %x", status);
    }
    
    // Make the Color Render Buffer the current buffer for display
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    
    [self display];
}

- (NSInteger)drawableWidth {
    GLint backingWidth;
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER,
                                 GL_RENDERBUFFER_WIDTH,
                                 &backingWidth);
    
    return (NSInteger)backingWidth;
}

- (NSInteger)drawableHeight {
    GLint backingHeight;
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER,
                                 GL_RENDERBUFFER_HEIGHT,
                                 &backingHeight);
    
    return (NSInteger)backingHeight;
}

@end
