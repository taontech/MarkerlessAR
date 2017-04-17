//
//  Created by Hartisan on 15/11/23.
//  Copyright © 2015年 Hartisan. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
//#import <opencv2/imgproc.hpp>
//#import <opencv2/features2d.hpp>
//#import <opencv2/highgui.hpp>
//#import <opencv2/core/core.hpp>

#define IPAD_CAMERA_PARAM_FX 536.84710693359375
#define IPAD_CAMERA_PARAM_FY 536.7637939453125
#define IPAD_CAMERA_PARAM_U 316.23187255859375
#define IPAD_CAMERA_PARAM_V 223.457733154296875


@interface Tracker : NSObject {
    
    // Pattern
    std::vector<cv::KeyPoint> _keyPtPattern;
    cv::Mat _descrptPattern;
    
    // ORB Detector
    cv::ORB _detector;
    
    // Flann Matcher
    cv::FlannBasedMatcher _matcher;
    std::vector<cv::DMatch> _matches;
    
    // Camera Param Matrix
    cv::Mat _cameraParamMatrix;
    cv::Mat _cameraParamMatrixInvert;

    // Track
    bool _isTracking;
    cv::Mat _preFrame;
    cv::Mat _currFrame;
    std::vector<cv::Point2f> _preKeyPts;
    std::vector<cv::Point2f> _currKeyPts;
    std::vector<unsigned char> _trackStatus;
    cv::Mat _preHomography;
}

@property cv::Mat _descrptPattern;
@property cv::ORB _detector;
@property cv::FlannBasedMatcher _matcher;
@property cv::Mat _cameraParamMatrix;
@property cv::Mat _cameraParamMatrixInvert;
@property bool _isTracking;
@property cv::Mat _preFrame;
@property cv::Mat _currFrame;
@property cv::Mat _preHomography;

- (cv::Mat)getCameraParamMatrix;
- (cv::Mat)getCameraDistCoeffs;
- (void)trainPattern:(NSString*)patternName;
- (cv::Mat)recogWithFrame:(cv::Mat&)frame;
- (void)knnMatchBetweenPattern:(cv::Mat&)descrptPattern andFrame:(cv::Mat&)descrptFrame into:(std::vector<cv::DMatch>&)matches;
- (cv::Mat)calcPoseWithHomography:(cv::Mat&)H;
- (cv::Mat)improveHomography:(cv::Mat&)H withFrame:(cv::Mat&)grayFrame;
- (cv::Mat)trackWithFrame:(cv::Mat&)frame;

@end
