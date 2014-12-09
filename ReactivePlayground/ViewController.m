//
//  ViewController.m
//  ReactivePlayground
//
//  Created by Steve Baker on 12/7/14.
//  Copyright (c) 2014 Beepscore LLC. All rights reserved.
//

#import "ViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (strong, nonatomic) RWDummySignInService *signInService;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.signInService = [RWDummySignInService new];

    // initially hide the failure message
    self.signInFailureText.hidden = YES;

    // update the style of the text fields based on
    // whether the current username and password combo is valid
    // map NSString to NSNumber. Box boolean to instantiate NSNumber
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal
                                      map:^id(NSString *text) {
                                          return @([self isValidUsername:text]);
                                      }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal
                                      map:^id(NSString *text) {
                                          return @([self isValidPassword:text]);
                                      }];

    // RAC macro uses signal output to set an object property
    // use validUsernameSignal to set object usernameTextField property backgroundColor
    RAC(self.usernameTextField, backgroundColor) = [validUsernameSignal
                                                    map:^id(NSNumber *usernameValid) {
                                                        return [usernameValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
                                                    }];
    
    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal
                                                    map:^id(NSNumber *passwordValid) {
                                                        return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
                                                    }];

    RACSignal *signUpActiveSignal =
    [RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal]
                      reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid) {
                          return @([usernameValid boolValue] &&
                          [passwordValid boolValue]);
                      }];

    [signUpActiveSignal subscribeNext:^(NSNumber *signupActive) {
        self.signInButton.enabled = [signupActive boolValue];
    }];

    // map converts button touch signal to sign in signal
    [[[self.signInButton
       rac_signalForControlEvents:UIControlEventTouchUpInside]
      map:^id(id x) {
          return [self signInSignal];
      }]
     subscribeNext:^(id x) {
         NSLog(@"Sign in result: %@", x);
     }];
}

- (BOOL)isValidUsername:(NSString *)username {
    return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
    return password.length > 3;
}

/**
 * Wrap asynchronous api in a signal
 @return a signal that signs in with current username and password
 */
- (RACSignal *)signInSignal {

    // When this signal has a subscriber, getNext will execute the block
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {

        // when signInWithUsername:password:complete: calls complete block
        // it will supply argument success
        [self.signInService signInWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                      complete:^(BOOL success) {
                                          [subscriber sendNext:@(success)];
                                          [subscriber sendCompleted];
                                      }];
        return nil;
    }];
}

@end
