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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.stopRecordBtn addTarget:self action:@selector(stopRecordAction:) forControlEvents:UIControlEventTouchUpInside];
    [SwiftClass callSwiftMethod];
}

- (void)stopRecordAction:(UIButton *)sender {
    [OrzOrderFile stopRecordOrderFileSymbolsWithCompletion:^(NSString * _Nullable orderFilePath) {
        NSString *orderFileContent = [NSString stringWithContentsOfFile:orderFilePath encoding:NSUTF8StringEncoding error:nil];
        self.symbolsTextView.text = orderFileContent;
        self.stopRecordBtn.hidden = YES;
        self.title = @"OrderFile内容如下";
    }];

}
@end
