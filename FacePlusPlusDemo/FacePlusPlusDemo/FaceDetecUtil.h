//
//  FaceDetecUtil.h
//  FacePlusPlusDemo
//
//  Created by Cong Thanh on 8/25/15.
//  Copyright (c) 2015 CongThanh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol FaceDetectUtilDelegate <NSObject>

- (void)didDetectedFaceWithImage:(UIImage*)image;

@end

@interface FaceDetecUtil : NSObject<UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic, strong)UIView *previewView;
@property(nonatomic, weak)id<FaceDetectUtilDelegate> delegate;
- (void)setupAVCapture;
- (void)teardownAVCapture;
@end
