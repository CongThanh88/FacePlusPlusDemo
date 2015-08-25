//
//  ViewController.m
//  FacePlusPlusDemo
//
//  Created by Cong Thanh on 8/25/15.
//  Copyright (c) 2015 CongThanh. All rights reserved.
//

#import "ViewController.h"
#import "APIKey+APISecret.h"
#import "MBProgressHUD.h"

#define PERSON_NAME     @"Do Hung Tam"



@implementation ViewController
{
    BOOL isFirstStart;
    NSMutableArray *personIds;
    UIImagePickerController *imagePicker;
    FaceDetecUtil *faceUtil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    imagePicker = [[UIImagePickerController alloc] init];
    isFirstStart = YES;
    
//    faceUtil = [[FaceDetecUtil alloc]init];
//    faceUtil.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //setupData
    if (isFirstStart) {
        isFirstStart = NO;
        [self setupAndTrainingData];
    }
}

-(void)setupAndTrainingData
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    personIds = [[NSMutableArray alloc]init];
    
    NSString *API_KEY = _API_KEY;
    NSString *API_SECRET = _API_SECRET;
    
    // initialize
    [FaceppAPI initWithApiKey:API_KEY andApiSecret:API_SECRET andRegion:APIServerRegionUS];
    
    // turn on the debug mode
    [FaceppAPI setDebugMode:TRUE];
    NSMutableArray *faceIds = [NSMutableArray arrayWithCapacity:11];
    // DETECTION
    [[FaceppAPI person] deleteWithPersonName:PERSON_NAME orPersonId:nil];
    
    for (int i=1; i<=11; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"Picture %d.jpg",i]];
        FaceppResult *detectLocalFileResult = [[ FaceppAPI detection ] detectWithURL : nil orImageData : UIImageJPEGRepresentation (image , 1 ) mode : FaceppDetectionModeNormal attribute : FaceppDetectionAttributeAll tag : nil async : NO ];
        if ([detectLocalFileResult success]) {
            int face_count = (int)[[detectLocalFileResult content][@"face"] count];
            if (face_count > 0) {
                NSString *face_id = [detectLocalFileResult content][@"face"][0][@"face_id"];
                [faceIds addObject:face_id];
            }
            
        } else {
            // something wrong
            FaceppError *error = [detectLocalFileResult error];
            NSLog(@"Error message: %@", [error message]);
        }
        
    }
    
    if (faceIds && faceIds.count >0) {
        FaceppResult *personResult = [[FaceppAPI person] createWithPersonName: PERSON_NAME
                                                                    andFaceId: faceIds
                                                                       andTag: nil
                                                                   andGroupId: nil
                                                                  orGroupName: nil];
        if ([personResult success]) {
            NSString *person_id = [personResult content][@"person_id"];
            [personIds addObject:person_id];
        }
        
    }
    
    //    // create a new group, add persons into group
    //    NSString *groupName = @"Test_Group";
    //    [[FaceppAPI group] deleteWithGroupName: groupName
    //                                 orGroupId: nil];
    //    [[FaceppAPI group] createWithGroupName: groupName
    //                                    andTag: nil
    //                               andPersonId: personIds
    //                              orPersonName: nil];
    //
    //    // generate training model for group
    //    [[FaceppAPI train] trainSynchronouslyWithId:nil
    //                                         orName:groupName
    //                                        andType:FaceppTrainIdentify
    //                                refreshDuration:1.0f
    //                                        timeout:10.0f];
    //
    //    // recognize
    //
    //    NSString *imageName1 = [[path stringByAppendingPathComponent:@"Sources"] stringByAppendingPathComponent:@"Picture 1.jpg"];
    //    UIImage *image1 = [UIImage imageWithContentsOfFile:imageName1];
    //    [[FaceppAPI recognition] identifyWithGroupId:nil
    //                                     orGroupName:groupName
    //                                          andURL:nil
    //                                     orImageData:UIImageJPEGRepresentation (image1 , 1 )
    //                                     orKeyFaceId:nil
    //                                           async:NO];
    //
    //    // create a new faceset, add faces into faceset
    //    NSString* facesetName = @"Do Hung Tam";
    //    [[FaceppAPI faceset] deleteWithFacesetName:facesetName orFacesetId:nil];
    //    [[FaceppAPI faceset] createWithFacesetName:facesetName andFaceId:faceIds andTag:nil];
    //
    //
    //    [[FaceppAPI train] trainSynchronouslyWithId:nil
    //                                         orName:facesetName
    //                                        andType:FaceppTrainSearch
    //                                refreshDuration:1.0f
    //                                        timeout:10.0f];
    
    
    //    // search
    //    [[FaceppAPI recognition] searchWithKeyFaceId:face_id andFacesetId:nil orFacesetName:facesetName];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
//    faceUtil.previewView = _previewView;
//    [faceUtil setupAVCapture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)btnTakePhoto:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"failed to camera"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
}

-(IBAction)btnChosePhoto:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"failed to access photo library"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

// Use facepp SDK to detect faces
-(BOOL) detectWithImage: (UIImage*) image {

    FaceppResult *detectLocalFileResult = [[ FaceppAPI detection ] detectWithURL : nil orImageData : UIImageJPEGRepresentation (image , 0.6 ) mode : FaceppDetectionModeNormal attribute : FaceppDetectionAttributeAll tag : nil async : NO ];
    if ([detectLocalFileResult success]) {
        int face_count = (int)[[detectLocalFileResult content][@"face"] count];
        if (face_count > 0) {
            NSString *faceId = [detectLocalFileResult content][@"face"][0][@"face_id"];
            
            [[FaceppAPI train] trainSynchronouslyWithId:nil orName:PERSON_NAME andType:FaceppTrainVerify refreshDuration:2 timeout:10];
            
            FaceppResult *result = [[FaceppAPI recognition] verifyWithFaceId:faceId andPersonId:nil orPersonName:PERSON_NAME async:NO];
            if ([result success]) {
                BOOL isSamePerson = [[result content][@"is_same_person"] boolValue];
                if(isSamePerson){
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    
                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"verify" message:[NSString stringWithFormat:@"verify %@", PERSON_NAME] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [alert show];
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    return YES;
                }
            }
        }
        
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        // some errors occurred
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:[NSString stringWithFormat:@"error message: %@", [detectLocalFileResult error].message]
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    return NO;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    UIImage *sourceImage = info[UIImagePickerControllerOriginalImage];
    UIImage *imageToDisplay = [self fixOrientation:sourceImage];
    
    // perform detection in background thread
    [self performSelectorInBackground:@selector(detectWithImage:) withObject:imageToDisplay];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - FaceDetectUtilDelegate
-(void)didDetectedFaceWithImage:(UIImage *)image
{
    if (image) {
        _previewView.hidden = YES;
        faceUtil.delegate = nil;
        UIImageView *imgv = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, _previewView.frame.size.width, _previewView.frame.size.height)];
        imgv.image = image;
        [_previewView addSubview:imgv];
        if([self detectWithImage:image])
        {
            
        }
    }
}
@end
