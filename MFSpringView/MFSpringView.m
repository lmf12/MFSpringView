//
//  MFSpringView.m
//  MFSpringView
//
//  Created by Lyman Li on 2018/11/25.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import "MFVertexAttribArrayBuffer.h"

#import "MFSpringView.h"

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
} SenceVertex;

static const SenceVertex vertices[] =
{
    {{-0.5, -0.5, 0}, {0, 0}},
    {{0.5, -0.5, 0}, {1, 0}},
    {{-0.5, 0.5, 0}, {0, 1}},
    
    {{0.5, 0.5, 0}, {1, 1}},
    {{0.5, -0.5, 0}, {1, 0}},
    {{-0.5, 0.5, 0}, {0, 1}}
};

@interface MFSpringView () <GLKViewDelegate>

@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@property (nonatomic, strong) MFVertexAttribArrayBuffer *vertexAttribArrayBuffer;

@end

@implementation MFSpringView

- (void)dealloc {
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Private

- (void)commonInit {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.delegate = self;
    [EAGLContext setCurrentContext:self.context];
    glClearColor(1, 1, 1, 1);
    
    self.vertexAttribArrayBuffer = [[MFVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SenceVertex) numberOfVertices:sizeof(vertices) / sizeof(SenceVertex) data:vertices usage:GL_STATIC_DRAW];
    
    UIImage *image = [UIImage imageNamed:@"girl.jpg"];
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage]
                                                               options:options
                                                                 error:NULL];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.baseEffect prepareToDraw];
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.vertexAttribArrayBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition
                                      numberOfCoordinates:3
                                             attribOffset:offsetof(SenceVertex, positionCoord)
                                             shouldEnable:YES];
    
    [self.vertexAttribArrayBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0
                                      numberOfCoordinates:2
                                             attribOffset:offsetof(SenceVertex, textureCoord)
                                             shouldEnable:YES];
    
    [self.vertexAttribArrayBuffer drawArrayWithMode:GL_TRIANGLES
                                   startVertexIndex:0
                                   numberOfVertices:6];
}

@end
