//
//  UIImage+Extension.m
//  Unity-iPhone
//
//  Created by Zhen Wang on 27/04/2018.
//

#import "UIImage+Extension.h"

@implementation UIImage(Extension)

#pragma mark - 缩放

/**
 缩放图片到指定Size
 */
- (UIImage *)scaleImageWithSize:(CGSize)size{
    //创建上下文
    UIGraphicsBeginImageContextWithOptions(size, YES, self.scale);
    
    //绘图
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    //获取新图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

/**
 缩放图片到指定比例
 */
- (UIImage *) imageWithScale:(CGFloat)scale {
    if (scale < 0) {
        return self;
    }
    
    CGSize scaleSize = CGSizeMake(self.size.width * scale, self.size.height * scale);
    return [self scaleImageWithSize:scaleSize];
}

@end
