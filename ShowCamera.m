//
//  ShowCamera.m
//  mcapp
//
//  Created by zhuchao on 14-10-16.
//  Copyright (c) 2014年 zhuchao. All rights reserved.
//

#import "ShowCamera.h"
#import "CheckCamera.h"

@interface ShowCamera()
@property(nonatomic,weak)id<ShowCameraDelegate> cameraDelegate;
@property(nonatomic,assign)BOOL ifShouldCrop;
@end
@implementation ShowCamera

-(instancetype)initWithParentController:(UIViewController *)controller delegate:(id<ShowCameraDelegate>)delegate{
    self = [self init];
    if (self) {
        _parentController = controller;
        _cameraDelegate = delegate;
        _ratio = 0.7f;
        _scaledToWidth = 320.0f;
        _imageCompressionQuality = 0.0f;
        self.ifShouldCrop = YES;
    }
    return self;
}

-(void)showCameraSheetWithOutCrop{
    self.ifShouldCrop = NO;
    [self showCameraSheet];
}

-(void)showCameraSheet{
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        [self openCamera:UIImagePickerControllerSourceTypePhotoLibrary];
        return;
    }
    [RMUniversalAlert showActionSheetInViewController:_parentController withTitle:@"选择图片" message:@"" cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@[@"拍摄照片",@"从相册选择"] popoverPresentationControllerBlock:nil tapBlock:^(RMUniversalAlert *alert, NSInteger buttonIndex) {
        if(alert.firstOtherButtonIndex == buttonIndex){
            [self openCamera:UIImagePickerControllerSourceTypeCamera];
        }else if(alert.firstOtherButtonIndex + 1 == buttonIndex){
            [self openCamera:UIImagePickerControllerSourceTypePhotoLibrary];
        }
    }];
}

- (void)openCamera:(UIImagePickerControllerSourceType)sourceType{
    if([CheckCamera shouldOpenMedia:sourceType inController:_parentController]){
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = sourceType;
        [self.cameraDelegate showPickViewController:picker];
    }
}

#pragma mark –
#pragma mark Camera View Delegate Methods
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^() {
        UIImage *portraitImg = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self startCropper:portraitImg];
    }];
}

-(void)startCropper:(UIImage *)portraitImg{
    portraitImg = [portraitImg imageByScalingToMaxSize];
    if (self.ifShouldCrop) {// 裁剪
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.width*_ratio;
        CGFloat originY = ([UIScreen mainScreen].bounds.size.height - height - 80)/2;
        VPImageCropperViewController *imgEditorVC = [[VPImageCropperViewController alloc] initWithImage:portraitImg cropFrame:CGRectMake(0, originY, width, height) limitScaleRatio:3.0];
        imgEditorVC.delegate = self;
        [self.cameraDelegate showCropperViewController:imgEditorVC];
    }else{
        [self saveImage:portraitImg];
    }
}

#pragma mark VPImageCropperDelegate
- (void)imageCropper:(VPImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage {
    [self saveImage:editedImage];
    [cropperViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.cameraDelegate dismissViewController];
}
- (void)imageCropperDidCancel:(VPImageCropperViewController *)cropperViewController{
    [self.cameraDelegate dismissViewController];
}

- (void)saveImage:(UIImage *)image {
    UIImage *midImage = [ImageTool imageWithImageSimple:image scaledToWidth:self.scaledToWidth];
    NSData * data = nil;
    if (self.imageCompressionQuality > 0.0f && self.imageCompressionQuality <=1.0f) {
        data = UIImageJPEGRepresentation(midImage, self.imageCompressionQuality);
    }else{
        data = UIImagePNGRepresentation(midImage);
    }
    NSString *imageName = [NSString stringWithFormat:@"%@.jpg",[[NSString stringWithFormat:@"%@",[NSDate date]] MD5]];
    NSString * localPath = [ImageTool saveData:data WithName:imageName];
    [self.cameraDelegate callBackPath:localPath];
}

@end
