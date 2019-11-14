//
//  ViewController.m
//  Face Detect
//
//  Created by IanWong on 2019/11/12.
//  Copyright © 2019 Sunyard. All rights reserved.
//


#import "ViewController.h"
#import "FaceModel.h"




@interface ViewController ()
@property (strong, nonatomic) FaceModel *faceModel;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIButton *runButton;

@end

@implementation ViewController

- (FaceModel *)faceModel{
    if(!_faceModel){
        _faceModel = [FaceModel new];
    }
    return _faceModel;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    std::vector<FaceInfo> face_info;
    UIImage *image = [UIImage imageNamed:@"3.jpg"];
    face_info = [self.faceModel detectImg:image];
    CGSize imageSize = [image size];
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    [image drawAtPoint:CGPointMake(0, 0)];
    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextDrawPath(context, kCGPathStroke);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0/255.0 green:255/255.0 blue:0/255.0 alpha:1].CGColor);
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextSetLineWidth(context, 2.0f);
    CGContextStrokePath(context);
    if(face_info.size() > 0){
        
        for (int i = 0; i < face_info.size(); i++) {
            auto face = face_info[i];
            CGContextAddRect(context, CGRectMake(face.x1, face.y1, face.x2 - face.x1, face.y2-face.y1));
            CGContextDrawPath(context, kCGPathStroke);

        }
    }
    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();;
   
}
- (IBAction)run:(id)sender {
    
    
    //视频识别
//    std::vector<FaceInfo> face_info;
//    UIImage *image = [UIImage imageNamed:@"3.jpg"];
//    face_info = [_faceModel detectImg:image];
//    cv::Mat mat;
//    UIImageToMat(image, mat);
//    if(face_info.size() > 0){
//
//        for (int i = 0; i < face_info.size(); i++) {
//            auto face = face_info[i];
//            cv::Point pt1(face.x1, face.y1);
//            cv::Point pt2(face.x2, face.y2);
//            cv::rectangle(mat, pt1, pt2, cv::Scalar(0, 255, 0), 2);
//        }
//    }
//    image = MatToUIImage(mat);
//    self.imageView.image = image;
}


@end
