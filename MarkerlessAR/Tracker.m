
#import "Tracker.h"


@implementation Tracker

@synthesize _cameraParamMatrix, _cameraParamMatrixInvert, _matcher, _detector, _descrptPattern, _isTracking, _currFrame, _preFrame, _preHomography;

- (id)init {
    
    self = [super init];
    
    // 初始化内参矩阵并得到其逆矩阵
    self._cameraParamMatrix = [self getCameraParamMatrix];
    
    // 初始化检测器
//    int nfeatures=500;
//    float scaleFactor=1.2f;
//    int nlevels=8;
//    int edgeThreshold=15; // Changed default (31);
//    int firstLevel=0;
//    int WTA_K=2;
//    int scoreType=cv::ORB::HARRIS_SCORE;
//    int patchSize=31;
//    int fastThreshold=20;
//    
//    cv::ORB detector = cv::ORB::create(
//                                    nfeatures,
//                                    scaleFactor,
//                                    nlevels,
//                                    edgeThreshold,
//                                    firstLevel,
//                                    WTA_K,
//                                    scoreType,
//                                    patchSize,
//                                    fastThreshold );
    // cv::ORB ptt = *new cv::ORB;
    self._detector = cv::ORB();
    
    self._isTracking = false;
    
    return self;
}

// 获得摄像机内参矩阵
- (cv::Mat)getCameraParamMatrix {
    
    cv::Mat matrix;
    
    double elements[] = {IPAD_CAMERA_PARAM_FX, 0.0, IPAD_CAMERA_PARAM_U, 0.0, IPAD_CAMERA_PARAM_FY, IPAD_CAMERA_PARAM_V, 0.0, 0.0, 1.0};
    matrix = cv::Mat(3, 3, CV_64FC1, elements);
    
    return matrix.clone();
}

// 获得摄像头畸变矩阵
- (cv::Mat)getCameraDistCoeffs {
    
    cv::Mat distCoeffs(1, 4, CV_64F, 0.0f);
    
    return distCoeffs.clone();
}

// 提取pattern图像特征并训练
- (void)trainPattern:(NSString*)patternName {

    // 载入Pattern图像
    NSString *path = [[NSBundle mainBundle] pathForResource:patternName ofType:@"jpg"];
    const char* cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    cv::Mat imgPattern = cv::imread(cpath, cv::IMREAD_GRAYSCALE);
    
    // 检测特征点并计算描述子
    // self._detector->detectAndCompute(imgPattern, cv::noArray(), _keyPtPattern, _descrptPattern);
    // self._detector->compute(imgPattern, cv::noArray(), _descrptPattern);
    (self._detector)(imgPattern, cv::noArray(), _keyPtPattern, _descrptPattern);
    /*
    // 训练描述子匹配器
    self._matcher.clear();
    std::vector<cv::Mat> descrpts;
    descrpts.push_back(self._descrptPattern.clone());
    self._matcher.add(descrpts);
    self._matcher.train();
    */
}

// 从某帧图像中提取特征并匹配计算变换矩阵
- (cv::Mat)recogWithFrame:(cv::Mat&)frame {
    
    cv::Mat poseMatrix;
    
    // 灰度
    cv::Mat grayFrame;
    cv::cvtColor(frame, grayFrame, CV_BGR2GRAY);
    
    // 检测特征点并计算描述子
    std::vector<cv::KeyPoint> keyPtFrame;
    cv::Mat descrptFrame;
    (self._detector)(grayFrame, cv::noArray(), keyPtFrame, descrptFrame);
    
    // knn匹配
    std::vector<cv::DMatch> matches;
    
        // KD-Tree或KMeans只对SIFT、SURF的32F描述子格式，对于ORB\FREAK\BRIEF等需要格式转换
    if (descrptFrame.type() != CV_32F) {
        descrptFrame.convertTo(descrptFrame, CV_32F);
    }
    if (_descrptPattern.type() != CV_32F) {
        _descrptPattern.convertTo(_descrptPattern, CV_32F);
    }
    
    // knn算法匹配
    [self knnMatchBetweenPattern:_descrptPattern andFrame:descrptFrame into:matches];
    
    // Homography
    std::vector<cv::Point2f> ptsPattern;
    std::vector<cv::Point2f> ptsFrame;
    for (auto e : matches) {
        
        ptsPattern.push_back(_keyPtPattern[e.trainIdx].pt);
        ptsFrame.push_back(keyPtFrame[e.queryIdx].pt);
    }
    if (ptsPattern.size() < _keyPtPattern.size() * 0.07) {
        
        self._isTracking = false;
        return poseMatrix.clone();
    }
    cv::Mat homography = cv::findHomography(ptsPattern, ptsFrame, CV_RANSAC);
    
    // Homography提纯
    homography = [self improveHomography:homography withFrame:grayFrame];
    
    // 计算初始位姿
    poseMatrix = [self calcPoseWithHomography:homography];
    
    // 设置Track初始信息
    self._preFrame = grayFrame.clone();
    _preKeyPts = ptsFrame;
    self._preHomography = homography.clone();
    self._isTracking = true;
    
    return poseMatrix.clone();
}

// knnMatch,可设置K = 2,即对每个匹配返回两个最近邻描述符，仅当第一个匹配与第二个匹配之间的距离足够小时，才认为这是一个匹配
- (void) knnMatchBetweenPattern:(cv::Mat&)descrptPattern andFrame:(cv::Mat&)descrptFrame into:(std::vector<cv::DMatch>&)matches {
    
    const float minRatio = 0.8f;
    const int k = 2;
    
    std::vector<std::vector<cv::DMatch>> knnMatches;
    self._matcher.knnMatch(descrptFrame, descrptPattern, knnMatches, k);

    for (auto i = 0; i < knnMatches.size(); i++) {
        
        cv::DMatch& bestMatch = knnMatches[i][0];
        cv::DMatch& betterMatch = knnMatches[i][1];
        float  distanceRatio = bestMatch.distance / betterMatch.distance;
        if (distanceRatio < minRatio)
            matches.push_back(bestMatch);
    }
}

// Homography提纯
- (cv::Mat)improveHomography:(cv::Mat&)H withFrame:(cv::Mat&)grayFrame {
    
    cv::Mat betterH;
    cv::Mat warpedFrame;
    
    // 变换图像
    cv::warpPerspective(grayFrame, warpedFrame, H, cvSize(480.0, 640.0), cv::WARP_INVERSE_MAP | cv::INTER_CUBIC);
    
    // 检测特征点并计算描述子
    std::vector<cv::KeyPoint> keyPtWarpedFrame;
    cv::Mat descrptWarpedFrame;
    (self._detector)(warpedFrame, cv::noArray(), keyPtWarpedFrame, descrptWarpedFrame);
    
    // knn匹配
    std::vector<cv::DMatch> matches;
    
    // KD-Tree或KMeans只对SIFT、SURF的32F描述子格式，对于ORB\FREAK\BRIEF等需要格式转换
    if (descrptWarpedFrame.type() != CV_32F) {
        descrptWarpedFrame.convertTo(descrptWarpedFrame, CV_32F);
    }
    if (_descrptPattern.type() != CV_32F) {
        _descrptPattern.convertTo(_descrptPattern, CV_32F);
    }
    
    [self knnMatchBetweenPattern:_descrptPattern andFrame:descrptWarpedFrame into:matches];
    
    // New Homography
    std::vector<cv::Point2f> ptsPattern;
    std::vector<cv::Point2f> ptsWarpedFrame;
    for (auto e : matches) {
        
        ptsPattern.push_back(_keyPtPattern[e.trainIdx].pt);
        ptsWarpedFrame.push_back(keyPtWarpedFrame[e.queryIdx].pt);
    }
    if (ptsWarpedFrame.size() < 4) {
        return H.clone();
    }
    cv::Mat homography = cv::findHomography(ptsPattern, ptsWarpedFrame, CV_RANSAC);
    betterH = H * homography;
    
    return betterH.clone();
}

// 根据前帧图像进行跟踪并更新位姿矩阵
- (cv::Mat)trackWithFrame:(cv::Mat&)frame {
    
    cv::Mat poseMatrix;
    
    // 灰度
    cv::Mat grayFrame;
    cv::cvtColor(frame, grayFrame, CV_BGR2GRAY);
    
    // 设置当前帧并利用光流法计算跟踪点
    _currFrame = grayFrame.clone();
    _currKeyPts.clear();
    std::vector<float> err;
    cv::calcOpticalFlowPyrLK(_preFrame, _currFrame, _preKeyPts, _currKeyPts, _trackStatus, err, cv::Size(21,21), 3);
    
    // 统计成功跟踪的特征点数量
    std::vector<cv::Point2f> trackedPts;
    std::vector<cv::Point2f> trackedPrePts;
    for (size_t i = 0; i < _trackStatus.size(); i++)
    {
        if (_trackStatus[i]) {
            
            trackedPts.push_back(_currKeyPts[i]);
            trackedPrePts.push_back(_preKeyPts[i]);
        }
    }
    
    // 如果跟踪点太少（跟丢了）则重新识别，否则更新计算位姿
    if (trackedPts.size() < 8) {
        
        self._isTracking = false;
        return poseMatrix;
        
    } else {
        
        cv::Mat deltaHomography = cv::findHomography(trackedPrePts, trackedPts, CV_RANSAC);
        cv::Mat H = deltaHomography * self._preHomography;
        poseMatrix = [self calcPoseWithHomography:H];
        
        // 更新前帧信息
        self._preFrame = self._currFrame.clone();
        self._preHomography = H.clone();
        _preKeyPts = trackedPts;
    }
    
    return poseMatrix;
}

// 从Homography中计算Pose
- (cv::Mat)calcPoseWithHomography:(cv::Mat&)H {

    cv::Mat pose(4, 4, CV_64F);
    
    // 4对图像 - 世界对应点
    std::vector<cv::Point2f> points_2D_pattern(4);
    std::vector<cv::Point2f> points_2D_frame(4);
    std::vector<cv::Point3f> points_3D_pattern(4);
    points_2D_pattern[0] = cv::Point2f(0.0, 0.0);
    points_2D_pattern[1] = cv::Point2f(480.0, 0.0);
    points_2D_pattern[2] = cv::Point2f(480.0, 640.0);
    points_2D_pattern[3] = cv::Point2f(0.0, 640.0);
    cv::perspectiveTransform(points_2D_pattern, points_2D_frame, H);
    points_3D_pattern[0] = cv::Point3f(-1.0, -0.75, 0.5);
    points_3D_pattern[1] = cv::Point3f(1.0, -0.75, 0.5);
    points_3D_pattern[2] = cv::Point3f(1.0, 0.75, 0.5);
    points_3D_pattern[3] = cv::Point3f(-1.0, 0.75, 0.5); // 模型的原点不在底面上，故将Z平移0.5单位
    
    cv::Mat rVector;
    cv::Mat tVector;
    cv::Mat rMatrix;
    cv::Mat distCoeffs = [self getCameraDistCoeffs];
    
    // 利用solvePNP方法求解旋转与平移向量
    cv::solvePnP(points_3D_pattern, points_2D_frame, self._cameraParamMatrix, distCoeffs, rVector, tVector);
    
    // 利用罗德里格斯方法把旋转向量等效为矩阵
    cv::Rodrigues(rVector, rMatrix);
    
    // 组合为4*4矩阵
    for (int i = 0; i < 3; ++i) {
        
        for (int j = 0; j < 4; ++j) {
            
            if (j < 3) {
                
                pose.at<double>(i, j) = rMatrix.at<double>(i, j);
                
            } else {
                
                pose.at<double>(i, j) = tVector.at<double>(i, 0);
            }
        }
    }
    pose.at<double>(3, 0) = 0.0;
    pose.at<double>(3, 1) = 0.0;
    pose.at<double>(3, 2) = 0.0;
    pose.at<double>(3, 3) = 1.0;
    
    return pose.clone();
}


@end
