//
//  ViewController.m
//  App
//
//  Created by joker on 2021/10/23.
//

#import "ViewController.h"
#import <OrzOrderFile/OrzOrderFile.h>
#import "App-Swift.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *symbolsTextView;
@property (weak, nonatomic) IBOutlet UIButton *stopRecordBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.shareBtn.enabled = NO;
    [self.stopRecordBtn addTarget:self action:@selector(stopRecordAction:) forControlEvents:UIControlEventTouchUpInside];
    [SwiftClass callSwiftMethod];
}

- (void)stopRecordAction:(UIButton *)sender {
    [OrzOrderFile stopRecordOrderFileSymbols];
    NSString *orderFileContent = [OrzOrderFile orderFileContent];
    self.symbolsTextView.text = orderFileContent;
    self.stopRecordBtn.hidden = YES;
    self.shareBtn.enabled = !!orderFileContent;
    self.title = @"OrderFile内容如下";
}
- (IBAction)shareAction:(UIBarButtonItem *)sender {
    [OrzOrderFile shareOrderFileWithAirDrop];
}
@end
