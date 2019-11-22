//
//  VideoViewController.m
//  sdkTest
//
//  Created by IanWong on 2019/10/9.
//  Copyright © 2019 com.SunYard.IanWong. All rights reserved.
//

#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height



#import "VideoViewController.h"
#import "FaceModel.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>

@interface VideoViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) dispatch_queue_t queue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) FaceModel *faceModel;

@end

@implementation VideoViewController



- (FaceModel *)faceModel{
    if(!_faceModel){
        _faceModel = [FaceModel new];
    }
    return _faceModel;
}


- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    _queue = dispatch_queue_create("net.bujige.testQueue", NULL);
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *deviceF;
    for (AVCaptureDevice *device in devices )
    {
        if ( device.position == AVCaptureDevicePositionFront )
        {
            deviceF = device;
            break;
        }
    }
    // 如果改变曝光设置，可以将其返回到默认配置
    if ([deviceF isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error = nil;
        if ([deviceF lockForConfiguration:&error]) {
            CGPoint exposurePoint = CGPointMake(0.5f, 0.5f);
            [deviceF setExposurePointOfInterest:exposurePoint];
            [deviceF setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
    }
    if ([deviceF isFocusModeSupported:AVCaptureFocusModeLocked]) {
        NSError *error = nil;
        if ([deviceF lockForConfiguration:&error]) {
            deviceF.focusMode = AVCaptureFocusModeLocked;
            [deviceF unlockForConfiguration];
        }
        else {
        }
    }
    AVCaptureDeviceInput*input = [[AVCaptureDeviceInput alloc] initWithDevice:deviceF error:nil];
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    
    [output setSampleBufferDelegate:self queue: _queue];
    //    AVCaptureMetadataOutput *metaout = [[AVCaptureMetadataOutput alloc] init];
    //    [metaout setMetadataObjectsDelegate:self queue:_faceQueue];
    self.session = [[AVCaptureSession alloc] init];
    [self.session beginConfiguration];
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [self.session setSessionPreset:AVCaptureSessionPreset640x480];
    }
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }
    [self.session commitConfiguration];
    
    NSString     *key           = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber     *value         = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [output setVideoSettings:videoSettings];

    AVCaptureSession* session = (AVCaptureSession *)self.session;
    //前置摄像头一定要设置一下 要不然画面是镜像
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        for (AVCaptureConnection * av in output.connections) {
            //判断是否是前置摄像头状态
            if (av.supportsVideoMirroring) {
                //镜像设置
                av.videoOrientation = AVCaptureVideoOrientationPortrait;
                av.videoMirrored = YES;
            }
        }
    }
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = (CGRect){CGPointZero, [UIScreen mainScreen].bounds.size};
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    [self.session startRunning];
    self.imageView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:self.imageView];
    
}


- (UIImage*)imageFromPixelBuffer:(CMSampleBufferRef)p {
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(p);
    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = (uint8_t *)CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return image;
}


-(UIImage *)drawFaces:(std::vector<FaceInfo>)face_info  InImage:(UIImage *)image {
        CGSize imageSize = [image size];
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
        [image drawAtPoint:CGPointMake(0, 0)];
        CGContextRef context = UIGraphicsGetCurrentContext();
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
       return UIGraphicsGetImageFromCurrentImageContext();
}

#pragma mark AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
     std::vector<FaceInfo> face_info;
     UIImage *image = [self imageFromPixelBuffer:sampleBuffer];
     NSLog(@"begin to recoganize card...........");
     face_info = [self.faceModel detectImg:image];
     dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image  = [self drawFaces:face_info InImage:image];
    });
}


- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)shouldAutorotate {
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"mem out");
    // Dispose of any resources that can be recreated.
}

@end
