//
//  MFShaderHelper.h
//  MFSpringViewDemo
//
//  Created by Lyman on 2019/2/28.
//  Copyright © 2019 Lyman Li. All rights reserved.
//

#import <OpenGLES/ES2/gl.h>
#import <Foundation/Foundation.h>

@interface MFShaderHelper : NSObject

/**
 将一个顶点着色器和一个片段着色器挂载到一个着色器程序上，并返回程序的 id

 @param shaderName 着色器名称，顶点着色器应该命名为 shaderName.vsh ，片段着色器应该命名为 shaderName.fsh
 @return 着色器程序的 ID
 */
+ (GLuint)programWithShaderName:(NSString *)shaderName;

@end
