//
//  ViewController.h
//  SpeechBlinker
//
//  Created by David Ecker on 4/17/14.
//  Copyright (c) 2014 David Ecker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Slt/Slt.h>

@class PocketsphinxController;
@class FliteController;
#import <OpenEars/OpenEarsEventsObserver.h> // We need to import this here in order to use the delegate.

@interface ViewController : UIViewController <OpenEarsEventsObserverDelegate> {
    Slt *slt; // the voice
    
    // These three are important OpenEars classes that ViewController demonstrates the use of. There is a fourth important class (LanguageModelGenerator) demonstrated
	// inside the ViewController implementation in the method viewDidLoad.
	
	OpenEarsEventsObserver *openEarsEventsObserver; // A class whose delegate methods which will allow us to stay informed of changes in the Flite and Pocketsphinx statuses.
	PocketsphinxController *pocketsphinxController; // The controller for Pocketsphinx (voice recognition).
	FliteController *fliteController; // The controller for Flite (speech).
    
    // UI stuff
    IBOutlet UITextView *heardTextView;
	IBOutlet UIButton *stopButton;
	IBOutlet UIButton *startButton;
	IBOutlet UIButton *suspendListeningButton;
	IBOutlet UIButton *resumeListeningButton;
	IBOutlet UITextView *statusTextView;
    IBOutlet UISwitch *lightToggle;
    IBOutlet UILabel *listeningStatus;
    IBOutlet UILabel *recognitionStatus;
    IBOutlet UILabel *speechStatus;
    IBOutlet UILabel *isSpeakingStatus;
    
    // DB stuff?
    IBOutlet UILabel *pocketsphinxDbLabel;
	IBOutlet UILabel *fliteDbLabel;
    
    BOOL usingStartLanguageModel;
    int restartAttemptsDueToPermissionRequests;
    BOOL startupFailedDueToLackOfPermissions;
    
    // Strings which aren't required for OpenEars but which will help us show off the dynamic language features in this sample app.
	NSString *pathToFirstDynamicallyGeneratedLanguageModel;
	NSString *pathToFirstDynamicallyGeneratedDictionary;
	
	NSString *pathToSecondDynamicallyGeneratedLanguageModel;
	NSString *pathToSecondDynamicallyGeneratedDictionary;
    
    // Our NSTimer that will help us read and display the input and output levels without locking the UI
	NSTimer *uiUpdateTimer;
}

// UI actions, not specifically related to OpenEars other than the fact that they invoke OpenEars methods.
- (IBAction) stopButtonAction;
- (IBAction) startButtonAction;
- (IBAction) suspendListeningButtonAction;
- (IBAction) resumeListeningButtonAction;

// Light actions
- (IBAction) toggleLight;
- (void) lightsOn;
- (void) lightsOff;
- (void) toggleTorch: (bool) on;

// Example for reading out the input audio levels without locking the UI using an NSTimer
- (void) startDisplayingLevels;
- (void) stopDisplayingLevels;

// These three are the important OpenEars objects that this class demonstrates the use of.
@property (nonatomic, strong) Slt *slt;

@property (nonatomic, strong) OpenEarsEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) PocketsphinxController *pocketsphinxController;
@property (nonatomic, strong) FliteController *fliteController;

// Some UI, not specifically related to OpenEars.
@property (nonatomic, strong) IBOutlet UIButton *stopButton;
@property (nonatomic, strong) IBOutlet UIButton *startButton;
@property (nonatomic, strong) IBOutlet UIButton *suspendListeningButton;
@property (nonatomic, strong) IBOutlet UIButton *resumeListeningButton;
@property (nonatomic, strong) IBOutlet UITextView *statusTextView;
@property (nonatomic, strong) IBOutlet UITextView *heardTextView;
@property (nonatomic, strong) IBOutlet UILabel *pocketsphinxDbLabel;
@property (nonatomic, strong) IBOutlet UILabel *fliteDbLabel;
@property (nonatomic, strong) IBOutlet UISwitch *lightToggle;

@property (nonatomic, strong) IBOutlet UILabel *listeningStatus;
@property (nonatomic, strong) IBOutlet UILabel *recognitionStatus;
@property (nonatomic, strong) IBOutlet UILabel *speechStatus;
@property (nonatomic, strong) IBOutlet UILabel *isSpeakingStatus;

@property (nonatomic, assign) BOOL usingStartLanguageModel;
@property (nonatomic, assign) int restartAttemptsDueToPermissionRequests;
@property (nonatomic, assign) BOOL startupFailedDueToLackOfPermissions;

// Things which help us show off the dynamic language features.
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedDictionary;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedDictionary;

// Our NSTimer that will help us read and display the input and output levels without locking the UI
@property (nonatomic, strong) 	NSTimer *uiUpdateTimer;

@end
