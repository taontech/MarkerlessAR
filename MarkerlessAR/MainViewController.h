//
//  UIViewController+MainViewController.h
//  EdgeInitialization
//
//  Created by Hartisan on 15/11/18.
//  Copyright © 2015年 Hartisan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLViewController.h"
#import "VideoSource.h"
#import "Tracker.h"

@interface MainViewController : UIViewController <VideoSourceDelegate> {
    
    // 摄像机
    VideoSource* _videoSource;
    
    IBOutlet GLKView* _glView;
    GLViewController* _glVC;
    Tracker* _tracker;
    IBOutlet UIButton* _btnInit;
    cv::Mat _cvMatFromCVImageBufferRef;
    
    // 状态
    bool _trackOn;
}


@property (nonatomic, strong) VideoSource* _videoSource;
@property (nonatomic, strong) IBOutlet GLKView* _glView;
@property (nonatomic, strong) GLViewController* _glVC;
@property (nonatomic, strong) Tracker* _tracker;
@property (nonatomic, strong) IBOutlet UIButton* _btnInit;
@property cv::Mat _cvMatFromCVImageBufferRef;
@property bool _trackOn;


- (cv::Mat)cvMatFromCVImageBufferRef:(CVImageBufferRef)pixelBuffer;
- (void)setGLModelViewMatrixWithCVMatrix:(cv::Mat&)cvMatrix;
- (IBAction)initBtnPressed:(id)sender;

@end
