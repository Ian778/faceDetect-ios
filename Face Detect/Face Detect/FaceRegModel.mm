//
//  FaceRegModel.m
//  Face Detect
//
//  Created by IanWong on 2019/11/25.
//  Copyright © 2019 Sunyard. All rights reserved.
//

#import "FaceRegModel.h"
#import <ncnn/ncnn/net.h>


static int image_w;
static int image_h;


@implementation FaceRegModel

/**
 加载模型
 @return true or false
 */
-(bool)loadModel{
    
    NSString *paramPath = [[NSBundle mainBundle] pathForResource:@"mobilefacenet" ofType:@"param"];
    NSString *binPath = [[NSBundle mainBundle] pathForResource:@"mobilefacenet" ofType:@"bin"];
    int r0 = faceRegNet.load_param([paramPath UTF8String]);
    int r1 = faceRegNet.load_model([binPath UTF8String]);
    if(r0 == 0 && r1 == 0){
        return true;
    }
    return false;
}
/**
 预测
 @param image 输入图像
 @return true or false
 */
-(std::vector<float>) detectImg:(UIImage *)image{
    std::vector<float> cls_scores;
    image_w = image.size.width;
    image_h = image.size.height;
    NSLog(@"input_w == %d, input_h == %d",image_w,image_h);
    if(image != nullptr){
        unsigned char* rgba = new unsigned char[image_w*image_h*4];
        {
            CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
            
            CGContextRef contextRef = CGBitmapContextCreate(rgba, image_w, image_h, 8, image_w*4,
                                                            colorSpace,
                                                            kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
            CGContextDrawImage(contextRef, CGRectMake(0, 0, image_w, image_h), image.CGImage);
            CGContextRelease(contextRef);
        }
        ncnn::Mat inputMat = ncnn::Mat::from_pixels_resize(rgba, ncnn::Mat::PIXEL_RGBA2RGB, image_w, image_h, 112, 112);
//        const float mean_vals[3] = {127.5, 127.5, 127.5};
//        const float norm_vals[3] = {0.0078125, 0.0078125, 0.0078125};
//        inputMat.substract_mean_normalize(mean_vals, norm_vals);
       
        if([self loadModel]){
            ncnn::Extractor ex = faceRegNet.create_extractor();
            ex.set_num_threads(4);
            ex.input("data", inputMat);
            ncnn::Mat features;
            ex.extract("fc1", features);
            cls_scores.resize(features.w);
            for (int j=0; j<features.w; j++)
            {
               cls_scores[j] =  features.channel(0)[j];
            }
        }
    }
    return cls_scores;
}
//static double calculSimilar(std::vector<float>& v1, std::vector<float>& v2)
//{
//    assert(v1.size() == v2.size());
//    double ret = 0.0, mod1 = 0.0, mod2 = 0.0;
//    for (std::vector<float>::size_type i = 0; i != v1.size(); ++i)
//    {
//        ret += v1[i] * v2[i];
//        mod1 += v1[i] * v1[i];
//        mod2 += v2[i] * v2[i];
//    }
//    return (ret / sqrt(mod1) / sqrt(mod2) + 1) / 2.0;
//}
@end
