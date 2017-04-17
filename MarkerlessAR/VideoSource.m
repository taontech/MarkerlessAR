//
//  VideoSource.m
//  LMarkerV2
//
//  Created by Hartisan on 15/5/9.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#import "VideoSource.h"


@implementation VideoSource

@synthesize _captureSession, _deviceInput, _delegate;


- (id)init {
    
    if (self = [super init]) {
        
        _captureSession = [[AVCaptureSession alloc] init];
        
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            
            [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
            NSLog(@"Set capture session preset AVCaptureSessionPreset640x480");
            
        } else if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            
            [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
            NSLog(@"Set capture session preset AVCaptureSessionPresetLow");
        }
    }
    
    return self;
}


// 外部调用，启动相机
- (bool) startWithDevicePosition:(AVCaptureDevicePosition)devicePosition {
    
    AVCaptureDevice* device = [self cameraWithPosition:devicePosition];
    if (!device) return FALSE;
    
    // 设置帧率
    NSError* err ;
    [device lockForConfiguration:&err];
    if (err == nil) {
        
        [device setActiveVideoMaxFrameDuration:CMTimeMake(1, 25)];
        [device setActiveVideoMinFrameDuration:CMTimeMake(1, 25)];
    }
    [device unlockForConfiguration];
    
    // 初始化
    NSError* error = nil;
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    self._deviceInput = input;
    
    if (!error) {
        
        if ([[self _captureSession] canAddInput:self._deviceInput]) {
            
            [[self _captureSession] addInput:self._deviceInput];
            
        } else {
            
            NSLog(@"Couldn't add video input");
            return FALSE;
        }
        
    } else {
        
        NSLog(@"Couldn't create video input");
        return FALSE;
    }
    
    //添加输出
    [self addRawViewOutput];
    
    //开始视频捕捉
    [_captureSession startRunning];
    
    return TRUE;
}


// 添加输出
- (void)addRawViewOutput {
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    
    // 同一时间只处理一帧，否则no
    output.alwaysDiscardsLateVideoFrames = YES;
    
    dispatch_queue_t queue;
    queue = dispatch_queue_create("com.EdgeInit.VideoSource", nil);
    [output setSampleBufferDelegate:self queue:queue];

    // 设置为BGRA格式
    [output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                             forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    if ([self._captureSession canAddOutput:output]) {
        
        [self._captureSession addOutput:output];
    }
}


// 获取相机
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position {
    
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        
        if ([device position] == position) {
            
            return device;
        }
    }
    
    return nil;
}


#pragma -mark AVCaptureOutput delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    [_delegate frameReady:pixelBuffer];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}


- (NSUInteger) supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

@end

