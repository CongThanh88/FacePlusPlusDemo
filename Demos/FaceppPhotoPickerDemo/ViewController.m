//
//  ViewController.m
//  FaceppPhotoPickerDemo
//
//  Created by youmu on 12-12-5.
//  Copyright (c) 2012年 Megvii. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD.h"
#import "NSMutableArray+TestPersons.h"
#import "../APIKey+APISecret.h"
#import "NSMutableArray+TestPersons.h"


@implementation ViewController
{
    BOOL isFirstStart;
    NSMutableArray *personIds;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    imagePicker = [[UIImagePickerController alloc] init];
    isFirstStart = YES;
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
    
    NSMutableArray *personNames = [NSMutableArray testPersons:@"Do Hung Tam" number:11];
    NSMutableArray *faceIds = [NSMutableArray arrayWithCapacity:11];
    NSString *face_id = nil;
    
    NSString *path = [[NSBundle mainBundle]resourcePath];
    // DETECTION
    for (int i=0; i<[personNames count]; i++) {
        // delete person if exists
        [[FaceppAPI person] deleteWithPersonName:[personNames objectAtIndex:i] orPersonId:nil];
        // create new person, detect faces from person's image_url
        
        
        NSString *imageName = [[path stringByAppendingPathComponent:@"Sources"] stringByAppendingPathComponent:[NSString stringWithFormat:@"Picture %d.jpg",(i+1)]];
        UIImage *image = [UIImage imageWithContentsOfFile:imageName];
        FaceppResult *detectLocalFileResult = [[ FaceppAPI detection ] detectWithURL : nil orImageData : UIImageJPEGRepresentation (image , 1 ) mode : FaceppDetectionModeNormal attribute : FaceppDetectionAttributeAll tag : nil async : NO ];
        if ([detectLocalFileResult success]) {
            int face_count = (int)[[detectLocalFileResult content][@"face"] count];
            if (face_count > 0) {
                face_id = [detectLocalFileResult content][@"face"][0][@"face_id"];
                [faceIds addObject:face_id];
                FaceppResult *personResult = [[FaceppAPI person] createWithPersonName: [personNames objectAtIndex:i]
                                                                            andFaceId: [NSArray arrayWithObject:face_id]
                                                                               andTag: nil
                                                                           andGroupId: nil
                                                                          orGroupName: nil];
                if ([personResult success]) {
                    NSString *person_id = [personResult content][@"person_id"];
                    [personIds addObject:person_id];
                     [[FaceppAPI train] trainSynchronouslyWithId:person_id orName:nil andType:FaceppTrainVerify refreshDuration:1 timeout:5];
                }
               
            }
            
        } else {
            // something wrong
            FaceppError *error = [detectLocalFileResult error];
            NSLog(@"Error message: %@", [error message]);
        }
    }
    
    // create a new group, add persons into group
    NSString *groupName = @"sampe_group";
    [[FaceppAPI group] deleteWithGroupName: groupName
                                 orGroupId: nil];
    [[FaceppAPI group] createWithGroupName: groupName
                                    andTag: nil
                               andPersonId: personIds
                              orPersonName: nil];
    
    // generate training model for group
    [[FaceppAPI train] trainSynchronouslyWithId:nil
                                         orName:groupName
                                        andType:FaceppTrainIdentify
                                refreshDuration:1.0f
                                        timeout:10.0f];
    
    // recognize
    
    NSString *imageName1 = [[path stringByAppendingPathComponent:@"Sources"] stringByAppendingPathComponent:@"Picture 1.jpg"];
    UIImage *image1 = [UIImage imageWithContentsOfFile:imageName1];
    [[FaceppAPI recognition] identifyWithGroupId:nil
                                     orGroupName:groupName
                                          andURL:nil
                                     orImageData:UIImageJPEGRepresentation (image1 , 1 )
                                     orKeyFaceId:nil
                                           async:NO];
    
    // create a new faceset, add faces into faceset
    NSString* facesetName = @"sample_faceset";
    [[FaceppAPI faceset] deleteWithFacesetName:facesetName orFacesetId:nil];
    [[FaceppAPI faceset] createWithFacesetName:facesetName andFaceId:faceIds andTag:nil];
    [[FaceppAPI train] trainSynchronouslyWithId:nil
                                         orName:facesetName
                                        andType:FaceppTrainSearch
                                refreshDuration:1.0f
                                        timeout:10.0f];

    
//    // search
    [[FaceppAPI recognition] searchWithKeyFaceId:face_id andFacesetId:nil orFacesetName:facesetName];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)pickFromCameraButtonPressed:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentModalViewController:imagePicker animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"failed to camera"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        [alert release];
    }
}

-(IBAction)pickFromLibraryButtonPressed:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentModalViewController:imagePicker animated:YES];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"failed to access photo library"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        [alert release];
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
-(void) detectWithImage: (UIImage*) image {
    NSMutableArray *personNames = [NSMutableArray testPersons:@"Do Hung Tam" number:11];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    FaceppResult *detectLocalFileResult = [[ FaceppAPI detection ] detectWithURL : nil orImageData : UIImageJPEGRepresentation (image , 0.6 ) mode : FaceppDetectionModeNormal attribute : FaceppDetectionAttributeAll tag : nil async : NO ];
    if ([detectLocalFileResult success]) {
        int face_count = (int)[[detectLocalFileResult content][@"face"] count];
        if (face_count > 0) {
            NSString *faceId = [detectLocalFileResult content][@"face"][0][@"face_id"];
            
            for (NSString *perName in personNames) {
                FaceppResult *result = [[FaceppAPI recognition] verifyWithFaceId:faceId andPersonId:nil orPersonName:perName async:NO];
                if ([result success]) {
                    BOOL isSamePerson = [[result content][@"is_same_person"] boolValue];
                    if(isSamePerson){
                        [image release];
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        
                        [pool release];
                        
                        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"verify" message:[NSString stringWithFormat:@"verify %@", perName] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alert show];

                        return;
                    }
                }
            }
        }
        
    } else {
        // some errors occurred
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:[NSString stringWithFormat:@"error message: %@", [detectLocalFileResult error].message]
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        [alert release];
    }
    [image release];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [pool release];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    UIImage *sourceImage = info[UIImagePickerControllerOriginalImage];
    UIImage *imageToDisplay = [self fixOrientation:sourceImage];
    
    // perform detection in background thread
    [self performSelectorInBackground:@selector(detectWithImage:) withObject:[imageToDisplay retain]];
    
    [picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
}

-(void) dealloc {
    [imagePicker release];
    [super dealloc];
}
@end
