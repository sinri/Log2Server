//
//  ViewController.m
//  Log2Server
//
//  Created by 倪 李俊 on 15/5/28.
//  Copyright (c) 2015年 com.sinri. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UILabel * label=[[UILabel alloc]initWithFrame:(CGRectMake(10, 70, self.view.frame.size.width-20, 30))];
    [label setText:@"Log here by hand:"];
    [self.view addSubview:label];
    
    _logTF = [[UITextField alloc]initWithFrame:(CGRectMake(10, 110, self.view.frame.size.width-20, 30))];
    [_logTF setPlaceholder:@"Log Text Here"];
    [_logTF setBorderStyle:(UITextBorderStyleRoundedRect)];
    [self.view addSubview:_logTF];
    
    UIButton * btn = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [btn setFrame:(CGRectMake(100, 150, self.view.frame.size.width-200, 30))];
    [btn setTitle:@"Log" forState:(UIControlStateNormal)];
    [btn addTarget:self action:@selector(onLogBtn:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:btn];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onLogSend:) name:@"Log2ServerRegularLogSendNotification" object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)onLogBtn:(id)sender{
    SLog(@"%@",_logTF.text);
    _logTF.text=@"";
    [self.view endEditing:YES];
}

-(void)onLogSend:(NSNotification*)notification{
    //NSLog(@"notification: %@",notification);
}

@end
