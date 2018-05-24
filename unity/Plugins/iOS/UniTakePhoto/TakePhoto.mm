//
//  TakePhoto.m
//  Unity-iPhone
//
//  Created by Zhen Wang on 26/04/2018.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIImage+Extension.h"

#pragma mark 声明TakePhoto类

@interface TakePhoto : NSObject<UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    
}

@property(nonatomic) UIImagePickerController* pickerController;

//@property(nonatomic) NSString* outputDir;
@property(nonatomic) NSString* outputFileName;
@property(nonatomic) NSInteger maxWidth;
@property(nonatomic) NSInteger maxHeight;

+ (instancetype)sharedInstance;
- (void)show:(NSString *)dir outputFileName:(NSString *)filename maxWidth:(NSInteger)width maxHeight:(NSInteger)height;

@end

#pragma mark Config
const char* UNITAKEPHOTO_CALLBACK_OBJECT = "Uninative.TakePhoto";
const char* UNITAKEPHOTO_CALLBACK_COMPLETE_METHOD = "OnComplete";
const char* UNITAKEPHOTO_CALLBACL_FAILURE_METHOD = "OnFailure";

#pragma mark 定义TakePhoto类

@implementation TakePhoto

+ (instancetype)sharedInstance {
    static TakePhoto* instance;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instance = [[TakePhoto alloc] init];
    });
    
    return instance;
}

- (void)show:(NSString *)dir outputFileName:(NSString *)filename maxWidth:(NSInteger)width maxHeight:(NSInteger)height {
    
    // check the device's camera status
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UnitySendMessage(UNITAKEPHOTO_CALLBACK_OBJECT, UNITAKEPHOTO_CALLBACL_FAILURE_METHOD, "Failed to call a camera from the device");
        return;
    }
    
    if (self.pickerController != nil) {
        UnitySendMessage(UNITAKEPHOTO_CALLBACK_OBJECT, UNITAKEPHOTO_CALLBACL_FAILURE_METHOD, "Failed to show, because the pickerController already existed, it must be nil");
        return;
    }
    
    self.pickerController = [[UIImagePickerController alloc] init];
    self.pickerController.delegate = self;
    
    // 是否允许编辑(YES, 图片选择完成后进入编辑模式)
    self.pickerController.allowsEditing = YES;
    // 设置资源来源（相机，相册，图库）
    self.pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    UIViewController* viewController = UnityGetGLViewController();
    [viewController presentViewController:self.pickerController animated:YES completion:^{
//        self.outputDir = dir;
        self.outputFileName = filename;
        self.maxWidth = width;
        self.maxHeight = height;
    }];
}

#pragma mark UIImageControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    /*
     使用UIImagePickerControllerEditedImage取得编辑后的图，它的imageOrientation属性为0,即不需要在做多余旋转操作
     */
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    if (image == nil) {
        UnitySendMessage(UNITAKEPHOTO_CALLBACK_OBJECT, UNITAKEPHOTO_CALLBACL_FAILURE_METHOD, "Failed to get a UIImage Object from [didFinishPickingMediaWithInfo]");
        [self dismissPicker];
        return;
    }
    
    if (self.maxWidth > 0 && self.maxHeight > 0) {
        // 缩放图片至要求的尺寸
        image = [image scaleImageWithSize:CGSizeMake(self.maxWidth, self.maxHeight)];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths.count == 0) {
        UnitySendMessage(UNITAKEPHOTO_CALLBACK_OBJECT, UNITAKEPHOTO_CALLBACL_FAILURE_METHOD, "Failed to copy file(get 0 paths)");
        [self dismissPicker];
        return;
    }
    
    // 检测output file name
    NSString *imagename = self.outputFileName;
    if ([imagename hasSuffix:@".png"] == NO) {
        imagename = [imagename stringByAppendingString:@".png"];
    }
    
    // 从当前沙盒中获取Document路径
    NSString *documentDir = [paths objectAtIndex:0];
    NSString *imageSavePath = [documentDir stringByAppendingPathComponent:imagename];
    
    NSData *png = UIImagePNGRepresentation(image);
    if (png == nil) {
        UnitySendMessage(UNITAKEPHOTO_CALLBACK_OBJECT, UNITAKEPHOTO_CALLBACL_FAILURE_METHOD, "Failed to copy file(PNG parse error)");
        [self dismissPicker];
        return;
    }
    
    BOOL success = [png writeToFile:imageSavePath atomically:YES];
    if (success == NO) {
        UnitySendMessage(UNITAKEPHOTO_CALLBACK_OBJECT, UNITAKEPHOTO_CALLBACL_FAILURE_METHOD, [[NSString stringWithFormat:@"Failed to copy file(save png error)[%@]", imageSavePath] UTF8String]);
        [self dismissPicker];
        return;
    }
    
    UnitySendMessage(UNITAKEPHOTO_CALLBACK_OBJECT, UNITAKEPHOTO_CALLBACK_COMPLETE_METHOD, [imageSavePath UTF8String]);
    [self dismissPicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    UnitySendMessage(UNITAKEPHOTO_CALLBACK_OBJECT, UNITAKEPHOTO_CALLBACL_FAILURE_METHOD, "TakePhoto cancel");
    [self dismissPicker];
}

- (void)dismissPicker {
//    self.outputDir = nil;
    self.outputFileName = nil;
    
    if (self.pickerController != nil) {
        [self.pickerController dismissViewControllerAnimated:YES completion:^{
            self.pickerController = nil;
        }];
    }
}

#pragma mark 纠正图片方向
- (UIImage *) fixOrientation:(UIImage *)source {
    // if not need
    if (source.imageOrientation == UIImageOrientationUp) {
        return source;
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (source.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, source.size.width, source.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, source.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, source.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        default:
            break;
    }
    
    switch (source.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, source.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, source.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        default:
            break;
    }
    
    // create a new UIImage context, and apply the transform
    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             source.size.width,
                                             source.size.height,
                                             CGImageGetBitsPerComponent(source.CGImage),
                                             0,
                                             CGImageGetColorSpace(source.CGImage),
                                             CGImageGetBitmapInfo(source.CGImage));
    
    CGContextConcatCTM(ctx, transform);
    
    switch (source.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, source.size.height, source.size.width), source.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, source.size.width, source.size.height), source.CGImage);
            break;
    }
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    
    return img;
}

@end

#pragma mark Unity Plugin

extern "C" {
    void unitakephoto_show(const char* dir, const char* filename, int width, int height) {
        TakePhoto *takephoto = [TakePhoto sharedInstance];
        [takephoto show:[NSString stringWithUTF8String:dir] outputFileName:[NSString stringWithUTF8String:filename] maxWidth:width maxHeight:height];
    }
}


