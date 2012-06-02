//
//  ViewController.m
//  opencvTestFace
//
//  Created by Mingyi Yuan on 12-6-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <Utilities/Utilities.h>

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

    Mat colorMat(height, width, CV_8UC4, (void*)imageData, width*4);
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


NSString *faceCascadeName = @"haarcascade_frontalface_alt";
NSString *eyesCascadeName = @"haarcascade_eye_tree_eyeglasses";

@interface ViewController () {
    CascadeClassifier faceCascade;
    CascadeClassifier eyesCascade;
}

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
    
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:faceCascadeName ofType:@"xml"];
    NSString *eyesCascadePath = [[NSBundle mainBundle] pathForResource:eyesCascadeName ofType:@"xml"];
    if (!faceCascadePath || !faceCascade.load([faceCascadePath UTF8String])) {
        NSLog(@"failed loading face cascade classifier!");
    }
    if (!eyesCascadePath || !eyesCascade.load([eyesCascadePath UTF8String])) {
        NSLog(@"failed loading eyes cascade classifier!");
    }
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
//    [UIAlertView alertWithMessage:[NSString stringWithFormat:
//                                   @"ori:%d\ncols:%d\nrows:%d", 
//                                   image.imageOrientation, 
//                                   CGImageGetWidth(image.CGImage),
//                                   CGImageGetHeight(image.CGImage)]];
    std::vector<cv::Rect> faces;
    Mat mat = [image mat], gray;
    cvtColor(mat, gray, CV_RGBA2GRAY);
    equalizeHist(gray, gray);
    
    faceCascade.detectMultiScale(gray, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
    
    // draw faces
    for (int i = 0; i < faces.size(); i++) {
        float halfWidth = faces[i].width*0.5;
        float halfHeight = faces[i].height*0.5;
        cv::Point center(faces[i].x + halfWidth, faces[i].y + halfHeight);
        ellipse(mat, center, cv::Size(halfWidth, halfHeight), 0, 0, 360, Scalar(255, 0, 255), 4, 8, 0);
        
        cv::Mat faceROI = gray(faces[i]);
        std::vector<cv::Rect> eyes;
        //-- In each face, detect eyes
        eyesCascade.detectMultiScale(faceROI, eyes, 1.1, 2, 0 |CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
        for (int j = 0; j < eyes.size(); j++) {
            cv::Point center(faces[i].x + eyes[j].x + eyes[j].width*0.5, faces[i].y + eyes[j].y + eyes[j].height*0.5); 
            int radius = cvRound((eyes[j].width + eyes[j].height)*0.25);
            circle(mat, center, radius, Scalar(255, 0, 0), 4, 8, 0);
        }
    }
    
    image = [UIImage imageWithMat:mat];
    
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
