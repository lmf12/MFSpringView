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
static NSInteger const kVerticesCount = 8;  // 顶点数量

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
} SenceVertex;

@interface MFSpringView () <GLKViewDelegate>

@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, assign) SenceVertex *vertices;

@property (nonatomic, strong) MFVertexAttribArrayBuffer *vertexAttribArrayBuffer;
@property (nonatomic, assign) CGSize currentTextureSize;

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

#pragma mark - Public

- (void)stretchingFromStartY:(CGFloat)startY
                      toEndY:(CGFloat)endY
               withNewHeight:(CGFloat)newHeight {
    [self calculateOriginTextureCoordWithTextureSize:self.currentTextureSize
                                              startY:startY
                                                endY:endY
                                           newHeight:newHeight];
    [self.vertexAttribArrayBuffer updateDataWithAttribStride:sizeof(SenceVertex)
                                            numberOfVertices:kVerticesCount
                                                        data:self.vertices
                                                       usage:GL_STATIC_DRAW];
    [self display];
    
    if (self.springDelegate &&
        [self.springDelegate respondsToSelector:@selector(springViewStretchAreaDidChanged:)]) {
        [self.springDelegate springViewStretchAreaDidChanged:self];
    }
}

- (CGFloat)textureTopY {
    return (1 - self.vertices[0].positionCoord.y) / 2;
}

- (CGFloat)textureBottomY {
    return (1 - self.vertices[7].positionCoord.y) / 2;
}

- (CGFloat)stretchAreaTopY {
    return (1 - self.vertices[2].positionCoord.y) / 2;
}

- (CGFloat)stretchAreaBottomY {
    return (1 - self.vertices[5].positionCoord.y) / 2;
}

- (CGFloat)textureHeight {
    return self.textureBottomY - self.textureTopY;
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
    
    self.currentTextureSize = image.size;
    [self calculateOriginTextureCoordWithTextureSize:self.currentTextureSize
                                              startY:0
                                                endY:0
                                           newHeight:0];
    
    self.vertexAttribArrayBuffer = [[MFVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SenceVertex) numberOfVertices:kVerticesCount data:self.vertices usage:GL_STATIC_DRAW];
}

/**
 根据当前控件的尺寸和纹理的尺寸，计算初始纹理坐标

 @param size 原始纹理尺寸
 @param startY 中间区域的开始纵坐标位置 0~1
 @param endY 中间区域的结束纵坐标位置 0~1
 @param newHeight 新的中间区域的高度
 */
- (void)calculateOriginTextureCoordWithTextureSize:(CGSize)size
                                            startY:(CGFloat)startY
                                              endY:(CGFloat)endY
                                         newHeight:(CGFloat)newHeight {
    CGFloat ratio = (size.height / size.width) *
                    (self.bounds.size.width / self.bounds.size.height);
    CGFloat textureHeight = MIN(ratio, kDefaultOriginTextureHeight);
    CGFloat textureWidth = textureHeight / ratio;
    
    // 拉伸量
    CGFloat delta = newHeight - (endY -  startY);
    
    // 纹理的顶点
    GLKVector3 pointLT = {-textureWidth, textureHeight + delta / 2, 0};  // 左上角
    GLKVector3 pointRT = {textureWidth, textureHeight + delta / 2, 0};  // 右上角
    GLKVector3 pointLB = {-textureWidth, -textureHeight - delta / 2, 0};  // 左下角
    GLKVector3 pointRB = {textureWidth, -textureHeight - delta / 2, 0};  // 右下角
    
    // 中间矩形区域的顶点
    CGFloat startYCoord = MIN(-2 * textureHeight * startY + textureHeight, textureHeight);
    CGFloat endYCoord = MAX(-2 * textureHeight * endY + textureHeight, -textureHeight);
    GLKVector3 centerPointLT = {-textureWidth, startYCoord + delta / 2, 0};  // 左上角
    GLKVector3 centerPointRT = {textureWidth, startYCoord + delta / 2, 0};  // 右上角
    GLKVector3 centerPointLB = {-textureWidth, endYCoord - delta / 2, 0};  // 左下角
    GLKVector3 centerPointRB = {textureWidth, endYCoord - delta / 2, 0};  // 右下角
    
    // 纹理的上面两个顶点
    self.vertices[0].positionCoord = pointRT;
    self.vertices[0].textureCoord = GLKVector2Make(1, 1);
    self.vertices[1].positionCoord = pointLT;
    self.vertices[1].textureCoord = GLKVector2Make(0, 1);
    // 中间区域的4个顶点
    self.vertices[2].positionCoord = centerPointRT;
    self.vertices[2].textureCoord = GLKVector2Make(1, 1 - startY);
    self.vertices[3].positionCoord = centerPointLT;
    self.vertices[3].textureCoord = GLKVector2Make(0, 1 - startY);
    self.vertices[4].positionCoord = centerPointRB;
    self.vertices[4].textureCoord = GLKVector2Make(1, 1 - endY);
    self.vertices[5].positionCoord = centerPointLB;
    self.vertices[5].textureCoord = GLKVector2Make(0, 1 - endY);
    // 纹理的下面两个顶点
    self.vertices[6].positionCoord = pointRB;
    self.vertices[6].textureCoord = GLKVector2Make(1, 0);
    self.vertices[7].positionCoord = pointLB;
    self.vertices[7].textureCoord = GLKVector2Make(0, 0);
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
