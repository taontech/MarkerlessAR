//
//  ViewController.h
//  EdgeInitialization
//
//  Created by Hartisan on 15/10/1.
//  Copyright © 2015年 Hartisan. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <CoreVideo/CVOpenGLESTextureCache.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>


@interface GLViewController : GLKViewController {
    
    EAGLContext *_context;
    
    // 背景纹理
    GLuint _program;
    GLuint _positionVBO;
    GLuint _texcoordVBO;
    GLuint _indexVBO;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    CVOpenGLESTextureRef _texture;
    
    // 绘制模型
    GLKBaseEffect* _effect;
    GLKVector4 _renderColor;
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _modelViewMatrix;
    NSString* _modelName;
    bool _drawModels;
}

@property (strong, nonatomic) EAGLContext *_context;
@property (nonatomic, strong) GLKBaseEffect* _effect;
@property GLKVector4 _renderColor;
@property GLKMatrix4 _projectionMatrix;
@property GLKMatrix4 _modelViewMatrix;
@property (nonatomic, strong) NSString* _modelName;
@property bool _drawModels;


- (id)initWithGLKView:(GLKView*)glkView;
- (void)updateBackgroundTexture:(CVImageBufferRef)pixelBuffer;

- (void)cleanUpTextures;
- (void)setupBuffers;
- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;

- (void)getProjectionMatrix;
- (void)setModelNameWithImg:(NSString*)targetName;

@end

