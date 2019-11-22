//
//  ViewController.m
//  Face Detect
//
//  Created by IanWong on 2019/11/12.
//  Copyright © 2019 Sunyard. All rights reserved.
//


#import "ViewController.h"
#import "FaceModel.h"
#import "VideoViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<bankCardVideoControllerDelegate>
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
    UIImage *image = [UIImage imageNamed:@"1.jpeg"];
    cv::Mat imgMat;
    UIImageToMat(image, imgMat);
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
            NSLog(@"x1 = %f, x2 = %f",face.x1,face.x2);
            CGContextAddRect(context, CGRectMake(face.x1, face.y1, face.x2 - face.x1, face.y2-face.y1));
            CGContextDrawPath(context, kCGPathStroke);
        }
    }
    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    
}
- (IBAction)run:(id)sender {
    
    NSLog(@"video ======");
    VideoViewController *conttroller = [[VideoViewController alloc]init];
    conttroller.delegate = self;
    [self presentViewController:conttroller animated:YES completion:nil];
}

- (void)videoDidGetOneFrameToImage:(UIImage *)image{
    self.imageView.image = image;
}

@end
