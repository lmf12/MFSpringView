//
//  MFSpringView.m
//  MFSpringView
//
//  Created by Lyman Li on 2018/11/25.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import "MFVertexAttribArrayBuffer.h"

#import "MFSpringView.h"

static CGFloat const kDefaultOriginTextureHeight = 0.7f;  // 初始纹理高度占控件高度的比例
static NSInteger const kVerticesCount = 4;  // 顶点数量

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
} SenceVertex;

@interface MFSpringView () <GLKViewDelegate>

@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, assign) SenceVertex *vertices;

@property (nonatomic, strong) MFVertexAttribArrayBuffer *vertexAttribArrayBuffer;

@end

@implementation MFSpringView

- (void)dealloc {
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_vertices) {
        free(_vertices);
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
    self.vertices = malloc(sizeof(SenceVertex) * kVerticesCount);
    
    self.backgroundColor = [UIColor clearColor];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.delegate = self;
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0, 0, 0, 0);
    
    UIImage *image = [UIImage imageNamed:@"girl.jpg"];
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage]
                                                               options:options
                                                                 error:NULL];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
    
    [self calculateOriginTextureCoordWithImage:image];
    
    self.vertexAttribArrayBuffer = [[MFVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SenceVertex) numberOfVertices:kVerticesCount data:self.vertices usage:GL_STATIC_DRAW];
}

// 根据当前控件的尺寸和纹理的尺寸，计算初始纹理坐标
- (void)calculateOriginTextureCoordWithImage:(UIImage *)image {
    CGFloat ratio = (image.size.height / image.size.width) *
                    (self.bounds.size.width / self.bounds.size.height);
    CGFloat textureHeight = MIN(ratio, kDefaultOriginTextureHeight);
    CGFloat textureWidth = textureHeight / ratio;
    GLKVector3 pointLT = {-textureWidth, textureHeight, 0};  // 左上角
    GLKVector3 pointRT = {textureWidth, textureHeight, 0};  // 右上角
    GLKVector3 pointLB = {-textureWidth, -textureHeight, 0};  // 左下角
    GLKVector3 pointRB = {textureWidth, -textureHeight, 0};  // 右下角
    
    self.vertices[0].positionCoord = pointRT;
    self.vertices[0].textureCoord = GLKVector2Make(1, 1);
    self.vertices[1].positionCoord = pointLT;
    self.vertices[1].textureCoord = GLKVector2Make(0, 1);
    self.vertices[2].positionCoord = pointRB;
    self.vertices[2].textureCoord = GLKVector2Make(1, 0);
    self.vertices[3].positionCoord = pointLB;
    self.vertices[3].textureCoord = GLKVector2Make(0, 0);
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
    
    [self.vertexAttribArrayBuffer drawArrayWithMode:GL_TRIANGLE_STRIP
                                   startVertexIndex:0
                                   numberOfVertices:kVerticesCount];
}

@end
