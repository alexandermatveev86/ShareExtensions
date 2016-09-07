//
//  ShareViewController.m
//  ShopcrewExtensions
//
//  Created by Alex on 8/21/16.
//  Copyright © 2016 Alex. All rights reserved.
//

#import "ShareViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "AFAppDotNetAPIClient.h"
#import "NSString+MD5.h"
#import "MBProgressHUD.h"

#import "GalleryItemCollectionViewCell.h"

@import AFNetworking;

#define PRIVATE_KEY     @"private_key"


@interface ShareViewController () {
    
    NSMutableArray * arrayImageUrls;
    NSMutableArray * arrayCollectionImages;
//    NSArray *_galleryItems;

}

//post view
@property (weak, nonatomic) IBOutlet UIView *viewPost;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollViewSelectedImages;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;

//collection view
@property (weak, nonatomic) IBOutlet UIView *viewCollection;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation ShareViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    arrayImageUrls = [[NSMutableArray alloc] init];
    arrayCollectionImages = [[NSMutableArray alloc] init];
    
    [self parseData];
    
    return;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark -
#pragma parse stuff

- (void) parseData {
    
    __block float x_imagePos = 0.0;
    
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                
                //from Photo Album...
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id image, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (image) {
                            
                            NSData * data=[NSData dataWithContentsOfURL:image];
                            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:data]];
                            [imageView setFrame:CGRectMake(x_imagePos, 0, self.scrollViewSelectedImages.frame.size.height, self.scrollViewSelectedImages.frame.size.height)];
                            [self.scrollViewSelectedImages addSubview:imageView];
                            
                            x_imagePos += self.scrollViewSelectedImages.frame.size.height;
                            self.scrollViewSelectedImages.contentSize = CGSizeMake(x_imagePos, self.scrollViewSelectedImages.frame.size.height);
                            
                            x_imagePos += 10;
                        }
                    });
                }];
            } else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
                
                //from website...
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *jsDict, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSDictionary *jsPreprocessingResults = jsDict[NSExtensionJavaScriptPreprocessingResultsKey];
                        NSString *pageTitle = jsPreprocessingResults[@"title"];
                        NSString *pageURL = jsPreprocessingResults[@"URL"];
                        
                        NSLog(@"%@ : %@", pageTitle, pageURL);
                        
                        _labelTitle.hidden = NO;
                        _labelTitle.text = pageTitle;
                        
                        _viewPost.hidden = YES;
                        _viewCollection.hidden = NO;
                        
                        [self getImageUrls:pageURL];
                        
                    });
                }];
                
                break;
            }
        }
    }
    
}

#pragma mark -
#pragma UI Actions

- (IBAction)onPost:(id)sender {
    
    UIAlertController * alert= [UIAlertController
                                alertControllerWithTitle:@"Post"
                                message:@"The images was posted successfully!"
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
                             
                             [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                             
                         }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onGoToPost:(id)sender {
    
    if (arrayCollectionImages.count == 0) {
        
        UIAlertController *controller = [UIAlertController alertControllerWithTitle: @"Warnning"
                                                                            message: @"You should select at least an image."
                                                                     preferredStyle: UIAlertControllerStyleAlert];
        
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle: @"Close"
                                                              style: UIAlertActionStyleDestructive
                                                            handler: nil];
        
        [controller addAction: alertAction];
        
        [self presentViewController: controller animated: YES completion: nil];

        
        return;
    }
    
    self.viewCollection.hidden = YES;
    self.viewPost.hidden = NO;
    
    float x_imagePos = 0;
    
    for (int i = 0 ; i < arrayCollectionImages.count ; i ++) {
    
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[arrayCollectionImages objectAtIndex:i]];
        [imageView setFrame:CGRectMake(x_imagePos, 0, self.scrollViewSelectedImages.frame.size.height, self.scrollViewSelectedImages.frame.size.height)];
        [self.scrollViewSelectedImages addSubview:imageView];
        
        x_imagePos += self.scrollViewSelectedImages.frame.size.height;
        self.scrollViewSelectedImages.contentSize = CGSizeMake(x_imagePos, self.scrollViewSelectedImages.frame.size.height);
        
        x_imagePos += 10;
    }
}

#pragma mark -
#pragma mark API calls

- (void) sortRealImageUrls:(NSArray *) arrayValue {
    
    for (int i = 0 ; i < arrayValue.count ; i ++) {
        
        NSString * strImageUrl = [arrayValue objectAtIndex:i];
        NSString * strLastFour = [strImageUrl substringFromIndex: [strImageUrl length] - 4];
        NSString * strLastFive = [strImageUrl substringFromIndex: [strImageUrl length] - 5];
        
        if ([strLastFour isEqualToString:@".png"] || [strLastFour isEqualToString:@".jpg"] || [strLastFive isEqualToString:@".jpeg"] || [strLastFour isEqualToString:@".bmp"] || [strLastFour isEqualToString:@".gif"] || [strLastFive isEqualToString:@".tiff"] || [strLastFour isEqualToString:@".svg"]) {
            
            NSRange range = [strImageUrl rangeOfString:@"http" options:NSBackwardsSearch];
            
            if (range.location == NSNotFound) {
                range = [strImageUrl rangeOfString:@"www" options:NSBackwardsSearch];
            }
            
            if (range.location != NSNotFound) {
                
                NSString * strReal = [strImageUrl substringFromIndex: range.location];
                [arrayImageUrls addObject:strReal];
                NSLog(@"%@", strReal);
            }
            
        }
    }

}

- (void) getImageUrls:(NSString *) url {
    
    [MBProgressHUD showHUDAddedTo:self.viewCollection animated:YES];

    
    NSMutableDictionary * dictParameters = [[NSMutableDictionary alloc] init];
    
    NSString * tempURL = url;
    NSString * strLast = [url substringFromIndex: [url length] - 1];
    
    if ([strLast isEqualToString:@"/"]) {
        
        tempURL = [url substringToIndex:[url length] - 1];
    }

    [dictParameters setValue:tempURL forKey:@"url"];
    
    NSString * hash = [[NSString alloc] generateMD5:[tempURL stringByAppendingString:PRIVATE_KEY]];
    hash = [hash lowercaseString];
    [dictParameters setValue:hash forKey:@"hash"];
    
    
    /*NSURLSessionTask * task = */
    [[AFAppDotNetAPIClient sharedClient] globalTimelinePostsWithBlock:dictParameters completed:^(NSArray * valueArray, NSError *error) {
        
        NSLog(@"%@", valueArray);
        
        if (!error) {
            
            [self sortRealImageUrls:valueArray];
            
            [self initGalleryItems];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.viewCollection animated:YES];
        });

    }];
    
}

- (void)initGalleryItems
{

    [_collectionView reloadData];
}

#pragma mark -
#pragma mark - UICollectionViewDataSource



- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [arrayImageUrls count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GalleryItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GalleryItemCollectionViewCell" forIndexPath:indexPath];
    [cell setGalleryItem:arrayImageUrls[indexPath.row]];
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

#pragma mark -
#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    GalleryItemCollectionViewCell * cell = (GalleryItemCollectionViewCell * )[collectionView cellForItemAtIndexPath:indexPath];
    
    if (cell.itemImageView.image == nil)
        return;
    
    if (cell.imageSelected.hidden == YES) {
        
        cell.imageSelected.hidden = NO;
        [arrayCollectionImages addObject:cell.itemImageView.image];
        
    } else {
        
        cell.imageSelected.hidden = YES;
        [arrayCollectionImages removeObject:cell.itemImageView.image];
    }
}

#pragma mark -
#pragma mark - UICollectionViewFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat picDimension = self.collectionView.frame.size.width / 4.0f;
    return CGSizeMake(picDimension, picDimension);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat leftRightInset = self.collectionView.frame.size.width / 14.0f;
    return UIEdgeInsetsMake(0, leftRightInset, 0, leftRightInset);
}



@end
