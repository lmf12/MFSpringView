//
//  MFSpringView.m
//  MFSpringView
//
//  Created by Lyman Li on 2018/11/25.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import "MFShaderHelper.h"
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
@property (nonatomic, assign) CGSize currentImageSize;

@property (nonatomic, assign, readwrite) BOOL hasChange;
@property (nonatomic, assign) CGFloat currentTextureWidth;

// 用于重新绘制纹理
@property (nonatomic, assign) CGFloat currentTextureStartY;
@property (nonatomic, assign) CGFloat currentTextureEndY;
@property (nonatomic, assign) CGFloat currentNewHeight;

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
    self.hasChange = YES;
    
    [self calculateOriginTextureCoordWithTextureSize:self.currentImageSize
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

- (UIImage *)createResult {
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGFloat textureWidth = (self.vertices[0].positionCoord.x - self.vertices[1].positionCoord.x) / 2;
    
    int imageWidth = self.frame.size.width * textureWidth * screenScale;
    int imageHeight = self.frame.size.height * [self textureHeight] * screenScale;
    int dataLength = imageWidth * imageHeight * 4;
    
    GLubyte *data = (GLubyte *)malloc(dataLength * sizeof(GLubyte));
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    
    glReadPixels((self.frame.size.width * screenScale - imageWidth) / 2, (self.frame.size.height * screenScale - imageHeight) / 2, imageWidth, imageHeight, GL_RGBA, GL_UNSIGNED_BYTE, data);  //从内存中读取像素
    
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(imageWidth, imageHeight, 8, 32, imageWidth * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast, ref, NULL, YES, kCGRenderingIntentDefault);
    
    UIGraphicsBeginImageContext(CGSizeMake(imageWidth, imageHeight));
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0, 0, imageWidth, imageHeight), iref);
    
    CGImageRef imageMasked = CGBitmapContextCreateImage(cgcontext);
    
    UIGraphicsEndImageContext();
    
    UIImage * image = [UIImage imageWithCGImage:imageMasked];
    
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    CGImageRelease(imageMasked);
    
    return image;
}

- (void)updateTexture {
    [self resetTextureWidthOriginWidth:self.currentImageSize.width
                          originHeight:self.currentImageSize.height
                                  topY:self.currentTextureStartY
                               bottomY:self.currentTextureEndY
                             newHeight:self.currentNewHeight];
    
    self.hasChange = NO;
    
    [self calculateOriginTextureCoordWithTextureSize:self.currentImageSize
                                              startY:0
                                                endY:0
                                           newHeight:0];
    [self.vertexAttribArrayBuffer updateDataWithAttribStride:sizeof(SenceVertex)
                                            numberOfVertices:kVerticesCount
                                                        data:self.vertices
                                                       usage:GL_STATIC_DRAW];
    [self display];
}

- (void)updateImage:(UIImage *)image {
    self.hasChange = NO;
    
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage]
                                                               options:options
                                                                 error:NULL];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
    
    self.currentImageSize = image.size;

    CGFloat ratio = (self.currentImageSize.height / self.currentImageSize.width) *
    (self.bounds.size.width / self.bounds.size.height);
    CGFloat textureHeight = MIN(ratio, kDefaultOriginTextureHeight);
    self.currentTextureWidth = textureHeight / ratio;
    
    [self calculateOriginTextureCoordWithTextureSize:self.currentImageSize
                                              startY:0
                                                endY:0
                                           newHeight:0];
    [self.vertexAttribArrayBuffer updateDataWithAttribStride:sizeof(SenceVertex)
                                            numberOfVertices:kVerticesCount
                                                        data:self.vertices
                                                       usage:GL_STATIC_DRAW];
    [self display];
}

#pragma mark - Private

- (void)commonInit {
    self.vertices = malloc(sizeof(SenceVertex) * kVerticesCount);
    
    self.backgroundColor = [UIColor clearColor];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.delegate = self;
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0, 0, 0, 0);
    
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
    CGFloat textureWidth = self.currentTextureWidth;
    CGFloat textureHeight = textureWidth * ratio;
    
    // 拉伸量
    CGFloat delta = (newHeight - (endY -  startY)) * textureHeight;
    
    // 纹理的顶点
    GLKVector3 pointLT = {-textureWidth, textureHeight + delta, 0};  // 左上角
    GLKVector3 pointRT = {textureWidth, textureHeight + delta, 0};  // 右上角
    GLKVector3 pointLB = {-textureWidth, -textureHeight - delta, 0};  // 左下角
    GLKVector3 pointRB = {textureWidth, -textureHeight - delta, 0};  // 右下角
    
    // 中间矩形区域的顶点
    CGFloat startYCoord = MIN(-2 * textureHeight * startY + textureHeight, textureHeight);
    CGFloat endYCoord = MAX(-2 * textureHeight * endY + textureHeight, -textureHeight);
    GLKVector3 centerPointLT = {-textureWidth, startYCoord + delta, 0};  // 左上角
    GLKVector3 centerPointRT = {textureWidth, startYCoord + delta, 0};  // 右上角
    GLKVector3 centerPointLB = {-textureWidth, endYCoord - delta, 0};  // 左下角
    GLKVector3 centerPointRB = {textureWidth, endYCoord - delta, 0};  // 右下角
    
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
    
    // 保存临时值
    self.currentTextureStartY = startY;
    self.currentTextureEndY = endY;
    self.currentNewHeight = newHeight;
}


/**
 根据当前屏幕上的显示，来重新创建纹理

 @param originWidth 纹理的原始实际宽度
 @param originHeight 纹理的原始实际高度
 @param topY 0 ~ 1，拉伸区域的顶边的纵坐标
 @param bottomY 0 ~ 1，拉伸区域的底边的纵坐标
 @param newHeight 0 ~ 1，拉伸区域的新高度
 */
- (void)resetTextureWidthOriginWidth:(CGFloat)originWidth
                        originHeight:(CGFloat)originHeight
                                topY:(CGFloat)topY
                             bottomY:(CGFloat)bottomY
                           newHeight:(CGFloat)newHeight {
    // 新的纹理尺寸
    GLsizei newTextureWidth = originWidth;
    GLsizei newTextureHeight = originHeight * (newHeight - (bottomY - topY)) + originHeight;
    
    // 高度变化百分比
    CGFloat heightScale = newTextureHeight / originHeight;
    
    // 重置图片的尺寸
    self.currentImageSize = CGSizeMake(newTextureWidth, newTextureHeight);
    // 在新的纹理坐标下，重新计算topY、bottomY
    CGFloat newTopY = topY / heightScale;
    CGFloat newBottomY = (topY + newHeight) / heightScale;
    
    // 创建顶点数组
    SenceVertex *tmpVertices = malloc(sizeof(SenceVertex) * kVerticesCount);
    tmpVertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    tmpVertices[1] = (SenceVertex){{1, 1, 0}, {1, 1}};
    tmpVertices[2] = (SenceVertex){{-1, -2 * newTopY + 1, 0}, {0, 1 - topY}};
    tmpVertices[3] = (SenceVertex){{1, -2 * newTopY + 1, 0}, {1, 1 - topY}};
    tmpVertices[4] = (SenceVertex){{-1, -2 * newBottomY + 1, 0}, {0, 1 - bottomY}};
    tmpVertices[5] = (SenceVertex){{1, -2 * newBottomY + 1, 0}, {1, 1 - bottomY}};
    tmpVertices[6] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    tmpVertices[7] = (SenceVertex){{1, -1, 0}, {1, 0}};
    
    
    /// 下面开始渲染到纹理的流程
    // 生成帧缓存，挂载渲染缓存
    GLuint frameBuffer;
    GLuint texture;
    
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, newTextureWidth, newTextureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    
    // 设置视口尺寸
    glViewport(0, 0, newTextureWidth, newTextureHeight);
    
    // 获取着色器程序
    GLuint program = [MFShaderHelper programWithShaderName:@"spring"];
    glUseProgram(program);
    
    // 获取参数
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    // 传值
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.baseEffect.texture2d0.name);
    glUniform1i(textureSlot, 0);
    
    MFVertexAttribArrayBuffer *vbo = [[MFVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SenceVertex) numberOfVertices:kVerticesCount data:tmpVertices usage:GL_STATIC_DRAW];
    
    [vbo prepareToDrawWithAttrib:positionSlot numberOfCoordinates:3 attribOffset:offsetof(SenceVertex, positionCoord) shouldEnable:YES];
    [vbo prepareToDrawWithAttrib:textureCoordsSlot numberOfCoordinates:2 attribOffset:offsetof(SenceVertex, textureCoord) shouldEnable:YES];
    
    // 绘制
    [vbo drawArrayWithMode:GL_TRIANGLE_STRIP startVertexIndex:0 numberOfVertices:kVerticesCount];
    
    // 将生成的新纹理 ID 赋值给 baseEffest
    if (self.baseEffect.texture2d0.name != 0) {
        GLuint textureName = self.baseEffect.texture2d0.name;
        glDeleteTextures(1, &textureName);
    }
    self.baseEffect.texture2d0.name = texture;
    
    // 解绑缓存
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    // 删除缓存
    glDeleteBuffers(1, &frameBuffer);
    // 释放顶点数组
    free(tmpVertices);
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
