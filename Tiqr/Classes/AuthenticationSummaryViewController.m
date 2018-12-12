/*
 * Copyright (c) 2010-2011 SURFnet bv
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of SURFnet bv nor the names of its contributors 
 *    may be used to endorse or promote products derived from this 
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AuthenticationSummaryViewController.h"
#import "TiqrAppDelegate.h"
#import "ServiceContainer.h"
#import "NSString+LocalizedBiometricString.h"

@interface AuthenticationSummaryViewController ()

@property (nonatomic, strong) AuthenticationChallenge *challenge;

@property (nonatomic, strong) IBOutlet UILabel *loginConfirmLabel;
@property (nonatomic, strong) IBOutlet UILabel *loginInformationLabel;
@property (nonatomic, strong) IBOutlet UILabel *toLabel;
@property (nonatomic, strong) IBOutlet UILabel *accountLabel;
@property (nonatomic, strong) IBOutlet UILabel *accountIDLabel;
@property (nonatomic, strong) IBOutlet UILabel *identityDisplayNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *identityIdentifierLabel;
@property (nonatomic, strong) IBOutlet UILabel *serviceProviderDisplayNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *serviceProviderIdentifierLabel;
@property (nonatomic, strong) IBOutlet UIButton *returnButton;
@property (nonatomic, copy) NSString *PIN;

@end

@implementation AuthenticationSummaryViewController

- (instancetype)initWithAuthenticationChallenge:(AuthenticationChallenge *)challenge usedPIN:(NSString *)PIN {
    self = [super initWithNibName:@"AuthenticationSummaryView" bundle:nil];
	if (self != nil) {
		self.challenge = challenge;
        self.PIN = PIN;
	}
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loginConfirmLabel.text = NSLocalizedString(@"successfully_logged_in", @"Login succes confirmation message");
    self.loginInformationLabel.text = NSLocalizedString(@"loggedin_with_account", @"Login information message");
    self.toLabel.text = NSLocalizedString(@"to_service_provider", @"to:");
    self.accountLabel.text = NSLocalizedString(@"full_name", @"Account");
    self.accountIDLabel.text = NSLocalizedString(@"id", @"Tiqr account ID");

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.leftBarButtonItem = backButton;
    
	self.identityDisplayNameLabel.text = self.challenge.identity.displayName;
	self.identityIdentifierLabel.text = self.challenge.identity.identifier;
	self.serviceProviderDisplayNameLabel.text = self.challenge.serviceProviderDisplayName;
	self.serviceProviderIdentifierLabel.text = self.challenge.serviceProviderIdentifier;
    
    if (self.challenge.returnUrl != nil) {
        [self.returnButton setTitle:NSLocalizedString(@"return_button", @"Return to button title") forState:UIControlStateNormal];
        self.returnButton.hidden = NO;
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (ServiceContainer.sharedInstance.secretService.biometricIDAvailable &&
        !self.challenge.identity.usesBiometrics &&
        ![self.challenge.identity.biometricIDAvailable boolValue] &&
        [self.challenge.identity.shouldAskToEnrollInBiometricID boolValue] &&
        self.PIN) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"upgrade_to_biometric_id", @"Upgrade account to TouchID alert title")  message:LocalizedBiometricString(@"upgrade_to_touch_id_message", @"upgrade_to_face_id_message") preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"upgrade", @"Upgrade (to TouchID)") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [ServiceContainer.sharedInstance.identityService upgradeIdentityToTouchID:self.challenge.identity withPIN:self.PIN];
            self.PIN = nil;
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            self.challenge.identity.shouldAskToEnrollInBiometricID = @NO;
            [ServiceContainer.sharedInstance.identityService saveIdentities];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)done {
    [(TiqrAppDelegate *)[UIApplication sharedApplication].delegate popToStartViewControllerAnimated:YES];
}

- (IBAction)returnToCaller {
    [(TiqrAppDelegate *)[UIApplication sharedApplication].delegate popToStartViewControllerAnimated:NO];
    NSString *returnURL = [NSString stringWithFormat:@"%@?successful=1", self.challenge.returnUrl];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:returnURL]];
}

@end
