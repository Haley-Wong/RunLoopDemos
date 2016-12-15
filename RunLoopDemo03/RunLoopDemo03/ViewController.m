//
//  ViewController.m
//  RunLoopDemo03
//
//  Created by Harvey on 2016/12/14.
//  Copyright © 2016年 Haley. All rights reserved.
//

#import "ViewController.h"
#import "FluencyMonitor.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.tableView.rowHeight = 135.f;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(stopMonitor)];
}

- (void)stopMonitor
{
    [[FluencyMonitor shareMonitor] stop];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 200;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    for (NSInteger i = 1; i <= 5; i++) {
        [[cell.contentView viewWithTag:i] removeFromSuperview];
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 300, 25)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor redColor];
    label.text = [NSString stringWithFormat:@"%zd - Drawing index is top priority", indexPath.row];
    label.font = [UIFont boldSystemFontOfSize:13];
    label.tag = 1;
    [cell.contentView addSubview:label];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(105, 20, 85, 85)];
    imageView.tag = 2;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"spaceship" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
//    imageView.image = image;
    [imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
    NSLog(@"current:%@",[NSRunLoop currentRunLoop].currentMode);
    [cell.contentView addSubview:imageView];
    
    UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(200, 20, 85, 85)];
    imageView2.tag = 3;
    UIImage *image2 = [UIImage imageWithContentsOfFile:path];
    imageView2.contentMode = UIViewContentModeScaleAspectFit;
//    imageView2.image = image2;
    [imageView2 performSelectorOnMainThread:@selector(setImage:) withObject:image2 waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
    [cell.contentView addSubview:imageView2];
    
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(5, 99, 300, 35)];
    label2.lineBreakMode = NSLineBreakByWordWrapping;
    label2.numberOfLines = 0;
    label2.backgroundColor = [UIColor clearColor];
    label2.textColor = [UIColor colorWithRed:0 green:100.f/255.f blue:0 alpha:1];
    label2.text = [NSString stringWithFormat:@"%zd - Drawing large image is low priority. Should be distributed into different run loop passes.", indexPath.row];
    label2.font = [UIFont boldSystemFontOfSize:13];
    label2.tag = 4;
    
    UIImageView *imageView3 = [[UIImageView alloc] initWithFrame:CGRectMake(5, 20, 85, 85)];
    imageView3.tag = 5;
    UIImage *image3 = [UIImage imageWithContentsOfFile:path];
    imageView3.contentMode = UIViewContentModeScaleAspectFit;
//    imageView3.image = image3;
    [imageView3 performSelectorOnMainThread:@selector(setImage:) withObject:image3 waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
    [cell.contentView addSubview:label2];
    [cell.contentView addSubview:imageView3];
    
    return cell;
}



@end
