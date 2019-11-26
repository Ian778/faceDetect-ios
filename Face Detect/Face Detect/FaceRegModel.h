//
//  FaceRegModel.h
//  Face Detect
//
//  Created by IanWong on 2019/11/25.
//  Copyright © 2019 Sunyard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ncnn/ncnn/net.h>

NS_ASSUME_NONNULL_BEGIN

@interface FaceRegModel : NSObject{
    ncnn::Net faceRegNet;
}



-(std::vector<float>) detectImg:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
