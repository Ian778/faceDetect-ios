//
//  FaceModel.m
//  Face Detect
//
//  Created by IanWong on 2019/11/12.
//  Copyright © 2019 Sunyard. All rights reserved.
//

#import "FaceModel.h"
#import <ncnn/ncnn/net.h>

#define clip(x, y) (x < 0 ? 0 : (x > y ? y : x))
#define hard_nms 1
#define blending_nms 2
const float mean_vals[3] = {127, 127, 127};
const float norm_vals[3] = {1.0 / 128, 1.0 / 128, 1.0 / 128};
static std::vector<std::vector<float>> priors;
const float iou_threshold = 0.35;
const float score_threshold = 0.7;


static int image_w;
static int image_h;

@implementation FaceModel

/**
 加载模型
 @return true or false
 */
-(bool)loadModel{
    
    NSString *paramPath = [[NSBundle mainBundle] pathForResource:@"slim_320" ofType:@"param"];
    NSString *binPath = [[NSBundle mainBundle] pathForResource:@"slim_320" ofType:@"bin"];
    int r0 = faceNet.load_param([paramPath UTF8String]);
    int r1 = faceNet.load_model([binPath UTF8String]);
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
-(std::vector<FaceInfo>) detectImg:(UIImage *)image{
    std::vector<FaceInfo> face_info;
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
        ncnn::Mat inputMat = ncnn::Mat::from_pixels_resize(rgba, ncnn::Mat::PIXEL_RGBA2RGB, image_w, image_h, 320, 240);
        inputMat.substract_mean_normalize(mean_vals, norm_vals);
       
        if([self loadModel]){
            ncnn::Extractor ex = faceNet.create_extractor();
            ex.set_num_threads(4);
            ex.input("input", inputMat);
            ncnn::Mat scores;
            ncnn::Mat boxes;
            ex.extract("scores", scores);
            ex.extract("boxes", boxes);
            std::vector<FaceInfo> bbox_collection;
            generateBBox(bbox_collection, boxes, scores);
            nms(bbox_collection, face_info, hard_nms);
        }
    }
    return face_info;
}

void generat_prior(){
    
    NSInteger img_w = 320, img_h = 240;
    float feature_map_w_h_list[2][4] = {{40, 20, 10, 5},
        {30, 15, 8, 4}};
    float min_boxes[4][3] = {{10, 16, 24},
        {32, 48},
        {64, 96},
        {128, 192, 256}};
    
    float shrink_list[2][4] = {{8.0, 16.0, 32.0, 64.0},
        {8.0, 16.0, 30.0, 60.0}};
    for(int index=0;index<4;index++){
        float scale_w = img_w / shrink_list[0][index];
        float scale_h = img_h / shrink_list[1][index];
        for(int j=0;j<feature_map_w_h_list[1][index];j++){
            for(int k=0;k<feature_map_w_h_list[0][index];k++){
                float x_center = (k+0.5) / scale_w;
                float y_center = (j+0.5) / scale_h;
                int len = sizeof(min_boxes[index]) / sizeof(min_boxes[index][0]);
                for(int l=0;l<len;l++){
                    float a = min_boxes[index][l];
                    if(a!=0){
                        float w = a / img_w;
                        float h = a / img_h;
                        float prior[4] = {x_center, y_center, w, h};
                        // 限制在（0，1）之间
                        std::vector<float> p;
                        for(int elment = 0;elment<4;elment++){
                            prior[elment] > 1? prior[elment]=1:prior[elment]=prior[elment];
                            prior[elment] < 0? prior[elment]=0:prior[elment]=prior[elment];
                            p.push_back(prior[elment]);
                        }
                        priors.push_back(p);
                    }
                }
            }
        }
    }
}


void generateBBox(std::vector<FaceInfo> &bbox_collection,ncnn::Mat boxes,ncnn::Mat scores){
    generat_prior();
    float center_variance = 0.1, size_variance=0.2;
    for(int i=0;i< 4420;i++){
        if (scores.channel(0)[i * 2 + 1] > score_threshold) {
            
            NSLog(@"score is %f",scores.channel(0)[i*2+1]);
            FaceInfo rects;
            float x_center = boxes.channel(0)[i * 4] * center_variance * priors[i][2] + priors[i][0];
            float y_center = boxes.channel(0)[i * 4 + 1] * center_variance * priors[i][3] + priors[i][1];
            float w = exp(boxes.channel(0)[i * 4 + 2] * size_variance) * priors[i][2];
            float h = exp(boxes.channel(0)[i * 4 + 3] * size_variance) * priors[i][3];
            
            rects.x1 = clip(x_center - w / 2.0, 1) * image_w;
            rects.y1 = clip(y_center - h / 2.0, 1) * image_h;
            rects.x2 = clip(x_center + w / 2.0, 1) * image_w;
            rects.y2 = clip(y_center + h / 2.0, 1) * image_h;
            rects.score = clip(scores.channel(0)[i * 2 + 1], 1);
            bbox_collection.push_back(rects);
        }
    }
}
void nms(std::vector<FaceInfo> &input, std::vector<FaceInfo> &output, int type) {
    //按概率从大到小顺序排列 从大到小
    std::sort(input.begin(), input.end(), [](const FaceInfo &a, const FaceInfo &b) { return a.score > b.score;});
    auto box_num = input.size();
    std::vector<int> merged(box_num, 0);
    for (int i = 0; i < box_num; i++) {
        if (merged[i])
            continue;
        std::vector<FaceInfo> buf;
        buf.push_back(input[i]);
        merged[i] = 1;
        float h0 = input[i].y2 - input[i].y1 + 1;
        float w0 = input[i].x2 - input[i].x1 + 1;
        float area0 = h0 * w0;
        for (int j = i + 1; j < box_num; j++) {
            if (merged[j])
                continue;
            float inner_x0 = input[i].x1 > input[j].x1 ? input[i].x1 : input[j].x1;
            float inner_y0 = input[i].y1 > input[j].y1 ? input[i].y1 : input[j].y1;
            float inner_x1 = input[i].x2 < input[j].x2 ? input[i].x2 : input[j].x2;
            float inner_y1 = input[i].y2 < input[j].y2 ? input[i].y2 : input[j].y2;
            float inner_h = inner_y1 - inner_y0 + 1;
            float inner_w = inner_x1 - inner_x0 + 1;
            if (inner_h <= 0 || inner_w <= 0)
                continue;
            float inner_area = inner_h * inner_w;
            float h1 = input[j].y2 - input[j].y1 + 1;
            float w1 = input[j].x2 - input[j].x1 + 1;
            float area1 = h1 * w1;
            float score;
            score = inner_area / (area0 + area1 - inner_area);
            if (score > iou_threshold) {
                merged[j] = 1;
                buf.push_back(input[j]);
            }
        }
        switch (type) {
            case hard_nms: {
                output.push_back(buf[0]);
                break;
            }
            case blending_nms: {
                float total = 0;
                for (int i = 0; i < buf.size(); i++) {
                    total += exp(buf[i].score);
                }
                FaceInfo rects;
                memset(&rects, 0, sizeof(rects));
                for (int i = 0; i < buf.size(); i++) {
                    float rate = exp(buf[i].score) / total;
                    rects.x1 += buf[i].x1 * rate;
                    rects.y1 += buf[i].y1 * rate;
                    rects.x2 += buf[i].x2 * rate;
                    rects.y2 += buf[i].y2 * rate;
                    rects.score += buf[i].score * rate;
                }
                output.push_back(rects);
                break;
            }
            default: {
                printf("wrong type of nms.");
                exit(-1);
            }
        }
    }
}


@end
