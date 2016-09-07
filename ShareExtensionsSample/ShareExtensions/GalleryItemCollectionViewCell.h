//
//  GalleryItemCollectionViewCell.h
//  ShopcrewExtensions
//
//  Created by Alex on 8/21/16.
//  Copyright © 2016 Alex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@class GalleryItem;

@interface GalleryItemCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet AsyncImageView *itemImageView;

@property (weak, nonatomic) IBOutlet UIImageView *imageSelected;

- (void)setGalleryItem:(GalleryItem *)item;

@end
