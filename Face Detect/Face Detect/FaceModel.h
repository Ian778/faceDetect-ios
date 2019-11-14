//
//  FaceModel.h
//  Face Detect
//
//  Created by IanWong on 2019/11/12.
//  Copyright © 2019 Sunyard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ncnn/ncnn/net.h>
NS_ASSUME_NONNULL_BEGIN

@interface FaceModel : NSObject{
    ncnn::Net faceNet;
}



typedef struct FaceInfo {
    float x1;
    float y1;
    float x2;
    float y2;
    float score;
    //float *landmarks;
} FaceInfo;

-(std::vector<FaceInfo>) detectImg:(UIImage*)image;


@end

NS_ASSUME_NONNULL_END
