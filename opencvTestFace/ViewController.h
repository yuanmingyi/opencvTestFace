//
//  ViewController.h
//  opencvTestFace
//
//  Created by Mingyi Yuan on 12-6-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, 
                UINavigationControllerDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) UIImage * selectedImage;
@property (strong, nonatomic) UIPopoverController * popoverController;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *photoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

- (IBAction)openCamera:(id)sender;
- (IBAction)openPhoto:(id)sender;

- (void)updateImage:(UIImage*)image;

@end
