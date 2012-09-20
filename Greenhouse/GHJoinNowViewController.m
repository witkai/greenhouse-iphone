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
//  GHJoinNowViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 8/1/12.
//

#import "GHJoinNowViewController.h"
#import "GHFormTextFieldCell.h"

@interface GHJoinNowViewController ()
{
    BOOL keyboardIsDisplaying;
    NSInteger selectedFormField;
}

@property (nonatomic, retain) NSArray *formCells;

- (void)signUp;
- (void)addNotificationCenterObservers;
- (void)removeNotificationCenterObservers;
- (NSTimeInterval)keyboardAnimationDurationForNotification:(NSNotification*)notification;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

@end

@implementation GHJoinNowViewController

@synthesize formCells;
@synthesize formView;
@synthesize signUpForm;
@synthesize firstNameCell;
@synthesize lastNameCell;
@synthesize emailCell;
@synthesize passwordCell;
@synthesize genderCell;
@synthesize birthdayCell;
@synthesize formToolbar;
@synthesize formTextFields;
@synthesize firstNameTextField;
@synthesize lastNameTextField;
@synthesize emailTextField;
@synthesize passwordTextField;
@synthesize genderTextField;
@synthesize birthdayTextField;
@synthesize genderPickerView;
@synthesize birthdayPickerView;


#pragma mark -
#pragma mark Public methods

- (IBAction)actionCancel:(id)sender
{
    [formTextFields enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UITextField *field = (UITextField *)obj;
        field.text = nil;
    }];
    [self.view endEditing:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)actionSubmit:(id)sender
{
    [self signUp];
}

- (IBAction)actionPrevious:(id)sender
{

}

- (IBAction)actionNext:(id)sender
{

}

- (IBAction)actionDone:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)actionBirthdayValueChanged:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MMMM, yyyy"];
    birthdayTextField.text = [dateFormatter stringFromDate:birthdayPickerView.date];
}


#pragma mark -
#pragma mark Private methods

- (void)signUp
{
    // TODO
}

- (void)addNotificationCenterObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
}

- (void)removeNotificationCenterObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (NSTimeInterval)keyboardAnimationDurationForNotification:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    NSValue* value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration = 0;
    [value getValue:&duration];
    return duration;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    DLog(@"");
    if (keyboardIsDisplaying)
    {
        return;
    }

    // get the size of the keyboard
    //    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    CGRect toolbarFrame = self.formToolbar.frame;
    toolbarFrame.origin.y = self.view.frame.size.height - 260.0;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[self keyboardAnimationDurationForNotification:notification]];
    self.formToolbar.frame = toolbarFrame;
    [UIView commitAnimations];

    keyboardIsDisplaying = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    DLog(@"");

    // adjust the toolbar
    CGRect toolbarFrame = self.formToolbar.frame;
    toolbarFrame.origin.y = self.view.frame.size.height;

    // adjust the view
    CGRect formViewFrame = self.formView.frame;
    formViewFrame.origin.y = 0.0f;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[self keyboardAnimationDurationForNotification:notification]];
    self.formToolbar.frame = toolbarFrame;
    self.formView.frame = formViewFrame;
    [UIView commitAnimations];

    keyboardIsDisplaying = NO;
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    DLog(@"begin ediding %i", textField.tag);

    selectedFormField = textField.tag;

    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.25];

    // move view to position visibility of form fields
    NSInteger offset = 44.0f * textField.tag;
    CGRect formViewFrame = self.formView.frame;
    formViewFrame.origin.y = -offset;
    self.formView.frame = formViewFrame;

    [UIView commitAnimations];

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSInteger cellIndex = textField.tag;
    NSInteger nextCellIndex = textField.tag + 1;
    NSInteger lastCellIndex = formCells.count - 1;

    // if we're on the last form field, then close the keyboard
    if (cellIndex >= lastCellIndex)
    {
        GHFormTextFieldCell *cell = formCells.lastObject;
        [cell.formTextField resignFirstResponder];
    }
    // otherwise, select the next form field
    else if (cellIndex >= 0 && cellIndex < lastCellIndex)
    {
        GHFormTextFieldCell *nextCell = [formCells objectAtIndex:nextCellIndex];
        [nextCell.formTextField becomeFirstResponder];
    }

    return NO;
}


#pragma mark -
#pragma mark UIPickerViewDelegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (row == 1)
    {
        genderTextField.text = @"Male";
    }
    else if (row == 2)
    {
        genderTextField.text = @"Female";
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    switch (row) {
        case 0:
            return @"";
            break;
        case 1:
            return @"Male";
            break;
        case 2:
            return @"Female";
            break;
        default:
            return nil;
            break;
    }
}


#pragma mark -
#pragma mark UIPickerViewDataSource methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 3;
}


#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark -
#pragma mark UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.row >= 0 && indexPath.row <= formCells.count)
    {
        cell = (UITableViewCell *)[formCells objectAtIndex:indexPath.row];
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return formCells.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Sign Up";

    birthdayPickerView.maximumDate = [NSDate date];
    genderTextField.inputView = genderPickerView;
    birthdayTextField.inputView = birthdayPickerView;

    self.formCells = [[NSArray alloc] initWithObjects:firstNameCell, lastNameCell, emailCell, passwordCell, genderCell, birthdayCell, nil];
    [formCells enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
        GHFormTextFieldCell *cell = (GHFormTextFieldCell *)obj;
        cell.formTextField.tag = index;
    } ];

//    UIScrollView *scrollView = (UIScrollView *)self.view;
//    scrollView.contentSize = containerView.frame.size;
//    [self.view addSubview:containerView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self addNotificationCenterObservers];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self removeNotificationCenterObservers];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.formCells = nil;
    self.formView = nil;
    self.signUpForm = nil;
    self.firstNameCell = nil;
    self.lastNameCell = nil;
    self.emailCell = nil;
    self.passwordCell = nil;
    self.genderCell = nil;
    self.birthdayCell = nil;
    self.firstNameCell = nil;
    self.formToolbar = nil;
    self.formTextFields = nil;
    self.firstNameTextField = nil;
    self.lastNameTextField = nil;
    self.emailTextField = nil;
    self.passwordTextField = nil;
    self.genderTextField = nil;
    self.birthdayTextField = nil;
    self.genderPickerView = nil;
    self.birthdayPickerView = nil;
}

@end
