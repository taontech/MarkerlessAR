//
//  VideoSource.h
//  LMarkerV2
//
//  Created by Hartisan on 15/5/9.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoSourceDelegate.h"

@interface VideoSource : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    AVCaptureSession* _captureSession;
    AVCaptureDeviceInput* _deviceInput;
}

@property (nonatomic, strong) AVCaptureSession* _captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput* _deviceInput;
@property (nonatomic, weak) id<VideoSourceDelegate> _delegate;

- (bool) startWithDevicePosition:(AVCaptureDevicePosition)devicePosition;

@end
