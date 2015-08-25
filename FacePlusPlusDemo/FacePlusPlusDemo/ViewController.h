//
//  ViewController.h
//  FacePlusPlusDemo
//
//  Created by Cong Thanh on 8/25/15.
//  Copyright (c) 2015 CongThanh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceppAPI.h"
#import "FaceDetecUtil.h"

@interface ViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate, FaceDetectUtilDelegate>

@property (weak, nonatomic) IBOutlet UIView *previewView;
- (IBAction)btnChosePhoto:(id)sender;
- (IBAction)btnTakePhoto:(id)sender;

@end

