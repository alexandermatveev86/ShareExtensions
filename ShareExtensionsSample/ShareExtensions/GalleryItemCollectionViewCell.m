//
//  GalleryItemCollectionViewCell.m
//  ShopcrewExtensions
//
//  Created by Alex on 8/21/16.
//  Copyright © 2016 Alex. All rights reserved.
//

#import "GalleryItemCollectionViewCell.h"


@implementation GalleryItemCollectionViewCell

- (void)setGalleryItem:(NSString *)item
{
    _imageSelected.hidden = YES;

    if (item == nil)
        return;
    
    //cancel loading previous image for cell
    [[AsyncImageLoader sharedLoader] cancelLoadingImagesForTarget:_itemImageView];
    
    //load the image
    _itemImageView.imageURL = [NSURL URLWithString:item];

}

@end
