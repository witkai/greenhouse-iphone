//
//  Copyright 2012 the original author or authors.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//
//  GHJoinNowViewController.h
//  Greenhouse
//
//  Created by Roy Clarkson on 8/1/12.
//

#import <UIKit/UIKit.h>

@class GHFormTextFieldCell;

@interface GHJoinNowViewController : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, retain) IBOutlet UITableView *signUpForm;
@property (nonatomic, retain) IBOutlet UIView *formView;
@property (nonatomic, retain) IBOutlet GHFormTextFieldCell *firstNameCell;
@property (nonatomic, retain) IBOutlet GHFormTextFieldCell *lastNameCell;
@property (nonatomic, retain) IBOutlet GHFormTextFieldCell *emailCell;
@property (nonatomic, retain) IBOutlet GHFormTextFieldCell *passwordCell;
@property (nonatomic, retain) IBOutlet GHFormTextFieldCell *genderCell;
@property (nonatomic, retain) IBOutlet GHFormTextFieldCell *birthdayCell;
@property (nonatomic, retain) IBOutlet UIToolbar *formToolbar;
@property (nonatomic, retain) IBOutletCollection(UITextField) NSArray *formTextFields;
@property (nonatomic, retain) IBOutlet UITextField *firstNameTextField;
@property (nonatomic, retain) IBOutlet UITextField *lastNameTextField;
@property (nonatomic, retain) IBOutlet UITextField *emailTextField;
@property (nonatomic, retain) IBOutlet UITextField *passwordTextField;
@property (nonatomic, retain) IBOutlet UITextField *genderTextField;
@property (nonatomic, retain) IBOutlet UITextField *birthdayTextField;
@property (nonatomic, retain) IBOutlet UIPickerView *genderPickerView;
@property (nonatomic, retain) IBOutlet UIDatePicker *birthdayPickerView;

- (IBAction)actionCancel:(id)sender;
- (IBAction)actionSubmit:(id)sender;
- (IBAction)actionPrevious:(id)sender;
- (IBAction)actionNext:(id)sender;
- (IBAction)actionDone:(id)sender;
- (IBAction)actionBirthdayValueChanged:(id)sender;

@end
