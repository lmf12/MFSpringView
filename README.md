# MFSpringView

基于 OpenGL ES 实现图片局部拉伸功能的控件，可以用来实现长腿功能。

## 效果展示

![](https://lymanli-1258009115.cos.ap-guangzhou.myqcloud.com/image/github/MFSpringView/image.gif)

## 原理

将图片分割为 6 个三角形，如下图所示，然后对中间矩形（V2~V5）进行拉伸或压缩处理。

![](https://lymanli-1258009115.cos.ap-guangzhou.myqcloud.com/image/github/MFSpringView/image1.jpg)

## 渲染到纹理

当单次图片编辑结束之后，需要重新生成纹理，即读取当前屏幕呈现的结果。

出于对结果分辨率的考虑，我们不会直接读取当前屏幕渲染结果对应的帧缓存，而是采取「渲染到纹理」的方式，重新生成一个宽度与原图一致的纹理。

## 为什么使用 OpenGL ES

实现图片局部拉伸功能的逻辑并不复杂，理论上也可以通过 CoreGraphics 的绘图功能来实现。

但是由于 CoreGraphics 的绘图功能依赖于 CPU ，不断地重绘图像会引起卡顿。

因此，从性能的角度考虑，使用 OpenGL ES 更佳。

## 更多介绍

[使用 iOS OpenGL ES 实现长腿功能](http://www.lymanli.com/2019/03/04/ios-opengles-spring/)
