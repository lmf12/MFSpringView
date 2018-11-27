//
//  MFVertexAttribArrayBuffer.h
//  MFSpringView
//
//  Created by Lyman on 2018/11/26.
//  Copyright © 2018 Lyman Li. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface MFVertexAttribArrayBuffer : NSObject

- (id)initWithAttribStride:(GLsizei)stride
          numberOfVertices:(GLsizei)count
                      data:(const GLvoid *)data
                     usage:(GLenum)usage;

- (void)prepareToDrawWithAttrib:(GLuint)index
            numberOfCoordinates:(GLint)count
                   attribOffset:(GLsizeiptr)offset
                   shouldEnable:(BOOL)shouldEnable;

- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count;

- (void)updateDataWithAttribStride:(GLsizei)stride
                  numberOfVertices:(GLsizei)count
                              data:(const GLvoid *)data
                             usage:(GLenum)usage;

@end
