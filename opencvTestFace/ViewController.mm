//
//  ViewController.m
//  opencvTestFace
//
//  Created by Mingyi Yuan on 12-6-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#include "opencv2/opencv.hpp"

using namespace cv;

Mat grayImageFromUIImage(UIImage *image) {
    CGImageRef cgImage = image.CGImage;
    int width = CGImageGetWidth(cgImage);
    int height = CGImageGetHeight(cgImage);
    
//    CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
//    CFDataRef data = CGDataProviderCopyData(provider);
//    const UInt8 *imageData = CFDataGetBytePtr(data);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();    
    CGContextRef context = CGBitmapContextCreate(NULL, 
                                                 width,
                                                 height,
                                                 8,
                                                 width*4,
                                                 colorspace,
                                                 kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    void *imageData = CGBitmapContextGetData(context);

    Mat colorMat(width, height, CV_8UC4, (void*)imageData);
    Mat grayMat;
    cvtColor(colorMat, grayMat, CV_RGBA2BGR);
    CGContextRelease(context);
    CGColorSpaceRelease(colorspace);
//    CFRelease(data);
    
    return grayMat;
}

UIImage *uIImageFromGrayImage(const Mat &mat) {
    Mat colorMat;
    cvtColor(mat, colorMat, CV_BGR2RGBA);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();    
    CGContextRef context = CGBitmapContextCreate(colorMat.data, 
                                                 colorMat.cols,
                                                 colorMat.rows,
                                                 8,
                                                 colorMat.step,
                                                 colorspace,
                                                 kCGImageAlphaPremultipliedLast);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *outImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorspace); 
    return outImage;
}

@interface ViewController () 

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
- (void)closeImagePicker;
- (void)updateImage:(UIImage *)image;
- (void)setupImagePickerSourceType:(UIImagePickerControllerSourceType)sourceType
                    usePopoverView:(BOOL)usePopoverView 
                        fromButton:(UIBarButtonItem *)button;
- (UIImage *)detectFace:(UIImage *)image;

@end

@implementation ViewController

@synthesize selectedImage;
@synthesize imageView;
@synthesize photoButton;
@synthesize cameraButton;
@synthesize popoverController;
@synthesize imagePickerController;

# pragma mark --
# pragma mark View life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setSelectedImage:nil];
    [self setImageView:nil];
    [self setPhotoButton:nil];
    [self setCameraButton:nil];
    [self setPopoverController:nil];
    [self setImagePickerController:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

# pragma mark --
# pragma mark helper methods
- (void)closeImagePicker {
    if (self.imagePickerController) {
        if (self.popoverController) {
            [self.popoverController dismissPopoverAnimated:YES];
            self.popoverController = nil;
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        self.imagePickerController = nil;
    }
}

- (void)updateImage:(UIImage *)image {
    self.selectedImage = image;
    UIImage *resultImage = [self detectFace:image];
    if (resultImage) {
        self.imageView.image = resultImage;
    } else {
        self.imageView.image = image;
    }
}

- (void)setupImagePickerSourceType:(UIImagePickerControllerSourceType)sourceType
                    usePopoverView:(BOOL)usePopoverView
                        fromButton:(UIBarButtonItem *)button {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return;
    }
    imagePicker.sourceType = sourceType;
    imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    imagePicker.allowsEditing = NO;
    imagePicker.delegate = self;
    self.imagePickerController = imagePicker;
    if (usePopoverView) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
        popover.delegate = self;
        self.popoverController = popover;
        [popover presentPopoverFromBarButtonItem:button 
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
    } else {
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (UIImage *)detectFace:(UIImage*)image {
    Mat mat = grayImageFromUIImage(image);
    image = uIImageFromGrayImage(mat);
    return image;
}

# pragma mark --
# pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popoverController = nil;
    self.imagePickerController = nil;
}

# pragma mark --
# pragma mark UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self closeImagePicker];
}
- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    [self updateImage:image];
    [self closeImagePicker];
}

# pragma mark --
# pragma mark Action responders
- (IBAction)openCamera:(id)sender {
    if (self.imagePickerController) {
        UIImagePickerControllerSourceType sourceType = self.imagePickerController.sourceType;
        [self closeImagePicker];
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            return;
        }
    }
    [self setupImagePickerSourceType:UIImagePickerControllerSourceTypeCamera
                      usePopoverView:NO
                          fromButton:nil];
}

- (IBAction)openPhoto:(id)sender {
    if (self.imagePickerController) {
        UIImagePickerControllerSourceType sourceType = self.imagePickerController.sourceType;
        [self closeImagePicker];
        if (sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
            return;
        }
    }
    [self setupImagePickerSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                      usePopoverView:YES
                          fromButton:self.photoButton];
}

@end
