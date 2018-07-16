//
//  ViewController.m
//  AudioRecordDemo
//
//  Created by olami on 2018/7/16.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import "ViewController.h"
#import "AudioUnitRecordController.h"

@interface ViewController ()
@property (nonatomic, strong) AudioUnitRecordController *record;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _record = [[AudioUnitRecordController alloc] init];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordAction:(id)sender {
    [_record recordAction];
}
- (IBAction)stopAction:(id)sender {
    [_record stopRecord];
}

@end
