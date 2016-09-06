//
//  ViewController.m
//  EdgeInitialization
//
//  Created by Hartisan on 15/10/1.
//  Copyright © 2015年 Hartisan. All rights reserved.
//

#import "GLViewController.h"
#import "ribWire_invert.h"

// Uniform index.
enum {
    
    UNIFORM,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

GLushort _indices[] = {
    
    0, 1, 2,
    2, 3, 1
};

GLfloat _vertices[] = {
    
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f
};

GLfloat _texcoords[] = {
    
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 0.0f
};


@implementation GLViewController

@synthesize _context, _effect, _renderColor, _projectionMatrix, _modelViewMatrix, _modelName, _drawModels;

// 由某个GLKView初始化
- (id)initWithGLKView:(GLKView *)glkView {
    
    if ((self = [super init])) {
        
        self._context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self.view = glkView;
        glkView.context = self._context;
        self.preferredFramesPerSecond = 30;
        
        [self setupGL];
        
        CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
        
        self._drawModels = false;
    }
    
    return self;
}


// 由远方传来的pixelBuffer更新背景
- (void)updateBackgroundTexture:(CVImageBufferRef)pixelBuffer {
    
    CVReturn err;
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    if (!_videoTextureCache) {
        
        NSLog(@"No video texture cache");
        return;
    }
    
    [self cleanUpTextures];
    
    // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture optimally from CVImageBufferRef.
    glActiveTexture(GL_TEXTURE0);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       (GLsizei)width,
                                                       (GLsizei)height,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_texture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_texture), CVOpenGLESTextureGetName(_texture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

}


- (void)setupGL
{
    [EAGLContext setCurrentContext:_context];
    
    [self loadShaders];
    glUseProgram(_program);
    glUniform1i(uniforms[UNIFORM], 0);
    
    GLKBaseEffect* baseEffect = [[GLKBaseEffect alloc] init];
    self._effect = baseEffect;
    
    // 设置绘制颜色
    self._renderColor = GLKVector4Make(0.0, 1.0, 0.0, 1.0);
    
    // 计算投影矩阵
    [self getProjectionMatrix];
}


- (void)setupBuffers {
    
    glGenBuffers(1, &_indexVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(_indices), _indices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_positionVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _positionVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_vertices), _vertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    glGenBuffers(1, &_texcoordVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _texcoordVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_texcoords), _texcoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
}

// 更新
- (void)update {
    
    // 更新投影矩阵
    self._effect.transform.projectionMatrix = self._projectionMatrix;
    
    // 物体
    self._effect.transform.modelviewMatrix = self._modelViewMatrix;
}


// 绘制
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 画背景
    [self setupBuffers];
    glDrawElements(GL_TRIANGLE_STRIP, 6, GL_UNSIGNED_SHORT, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glDisableVertexAttribArray(ATTRIB_VERTEX);
    glDisableVertexAttribArray(ATTRIB_TEXCOORD);
    
    // 画模型
    if (self._drawModels) {
        
        self._effect.useConstantColor = YES;
        self._effect.constantColor = self._renderColor;
        glUseProgram(0);
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glEnableVertexAttribArray(GLKVertexAttribNormal);
        if ([self._modelName isEqualToString:@"Rib"]){
            
            glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, ribWire_invertVerts);
            glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, ribWire_invertNormals);
            [self._effect prepareToDraw];
            glDrawArrays(GL_TRIANGLES, 0, ribWire_invertNumVerts);
        }
        glDisableVertexAttribArray(GLKVertexAttribPosition);
        glDisableVertexAttribArray(GLKVertexAttribNormal);
        glUseProgram(_program);
    }
    
    // 清空内存占用
    glDeleteBuffers(1, &_positionVBO);
    glDeleteBuffers(1, &_texcoordVBO);
    glDeleteBuffers(1, &_indexVBO);
}


// 根据摄像头内参、分辨率等参数计算projectionMatrix
- (void)getProjectionMatrix {
    
    float matrix[16];
    float fx = 536.84710693359375;
    float fy = 536.7637939453125;
    float cx = 316.23187255859375;
    float cy = 223.457733154296875;
    float width = 640.0;
    float height = 480.0;
    float near = 0.001;
    float far = 100.0;
    
    matrix[0] = 2.0f * fx / width;
    matrix[1] = 0.0f;
    matrix[2] = 0.0f;
    matrix[3] = 0.0f;
    
    matrix[4] = 0.0f;
    matrix[5] = 2.0f * fy / height;
    matrix[6] = 0.0f;
    matrix[7] = 0.0f;
    
    matrix[8] = 1.0f - 2.0 * cx / width;
    matrix[9] = 2.0f * cy / height - 1.0f;
    matrix[10] = - (far + near) / (far - near);
    matrix[11] = - 1.0f;
    
    matrix[12] = 0.0f;
    matrix[13] = 0.0f;
    matrix[14] = - 2.0f * far * near / (far - near);
    matrix[15] = 0.0f;
    
    self._projectionMatrix = GLKMatrix4MakeWithArray(matrix);
}


// 设置当前需要加载哪个模型
- (void)setModelNameWithImg:(NSString*)targetName {
    
    if ([targetName isEqualToString:@"MetaioMan"]) {
        
        self._modelName = @"Rib";
    }
}


// 清理纹理缓存
- (void)cleanUpTextures
{    
    if (_texture)
    {
        CFRelease(_texture);
        _texture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}


- (void)tearDownGL
{
    [EAGLContext setCurrentContext:_context];
    
    glDeleteBuffers(1, &_positionVBO);
    glDeleteBuffers(1, &_texcoordVBO);
    glDeleteBuffers(1, &_indexVBO);
    
    if (_program) {
        
        glDeleteProgram(_program);
        _program = 0;
    }
}


- (void)viewDidUnload {
    
    [super viewDidUnload];
    
    if ([EAGLContext currentContext] == self._context) {
        
        [EAGLContext setCurrentContext:nil];
    }
    
    self._context = nil;
    self._effect = nil;
}


#pragma mark - OpenGL ES 2 shader compilation
- (BOOL)loadShaders {
    
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM] = glGetUniformLocation(_program, "Sampler");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}


- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}


- (BOOL)linkProgram:(GLuint)prog {
    
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
