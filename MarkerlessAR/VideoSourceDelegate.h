//
//  VideoSourceDelegate.h
//  LMarkerV2
//
//  Created by Hartisan on 15/5/9.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

@protocol VideoSourceDelegate <NSObject>

- (void)frameReady:(CVImageBufferRef)pixelBuffer;

@end
