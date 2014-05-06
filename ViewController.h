//
//  ViewController.h
//  SpeechBlinker
//
//  Created by David Ecker on 4/17/14.
//  Copyright (c) 2014 David Ecker. All rights reserved.
//

// OpenEars imports
#import <UIKit/UIKit.h>
#import <Slt/Slt.h>
// BLE imports
#import "BLE.h"

@class PocketsphinxController;
@class FliteController;
#import <OpenEars/OpenEarsEventsObserver.h> // We need to import this here in order to use the delegate.

@interface ViewController : UIViewController <OpenEarsEventsObserverDelegate, BLEDelegate> {
    
    // OpenEars objects
    Slt *slt; // the voice
	
	OpenEarsEventsObserver *openEarsEventsObserver;
	PocketsphinxController *pocketsphinxController;
	FliteController *fliteController;
    
    // UI stuff
	IBOutlet UIButton *stopButton;
	IBOutlet UIButton *startButton;
	IBOutlet UITextView *statusTextView;
    IBOutlet UILabel *youSaidLabel;
    
    IBOutlet UILabel *listeningStatus;
    IBOutlet UILabel *recognitionStatus;
    IBOutlet UILabel *speechStatus;
    IBOutlet UILabel *isSpeakingStatus;
    
    IBOutlet UIButton *httButton;
    IBOutlet UIButton *connectButton;
    IBOutlet UIButton *disconnectButton;
    IBOutlet UILabel *oneBar;
    IBOutlet UILabel *twoBar;
    IBOutlet UILabel *threeBar;
    IBOutlet UILabel *rssiLabel;
    IBOutlet UILabel *bluetoothStatus;
    IBOutlet UILabel *transmitStatus;
    
    IBOutlet UILabel *redLed;
    IBOutlet UILabel *blueLed;
    IBOutlet UILabel *greenLed;
    
    
    // DB stuff?
    IBOutlet UILabel *pocketsphinxDbLabel;
	IBOutlet UILabel *fliteDbLabel;
    
    int restartAttemptsDueToPermissionRequests;
    BOOL startupFailedDueToLackOfPermissions;
    
    // Strings which aren't required for OpenEars but which will help us show off the dynamic language features in this sample app.
	NSString *pathToFirstDynamicallyGeneratedLanguageModel;
	NSString *pathToFirstDynamicallyGeneratedDictionary;
    
    // Our NSTimer that will help us read and display the input and output levels without locking the UI
	NSTimer *uiUpdateTimer;
}

// UI actions
- (IBAction) stopButtonAction;
- (IBAction) startButtonAction;
- (IBAction) suspendListeningButtonAction;
- (IBAction) resumeListeningButtonAction;
- (IBAction) connectButtonAction;
- (IBAction) disconnectButtonAction;

// Light actions
- (void) toggleTorch: (bool) on;

// Example for reading out the input audio levels without locking the UI using an NSTimer
- (void) startDisplayingLevels;
- (void) stopDisplayingLevels;

// append method
- (void) appendToStatus: (NSString*) message;

// These three are the important OpenEars objects that this class demonstrates the use of.
@property (nonatomic, strong) Slt *slt;

@property (nonatomic, strong) OpenEarsEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) PocketsphinxController *pocketsphinxController;
@property (nonatomic, strong) FliteController *fliteController;

// Some UI, not specifically related to OpenEars.
@property (nonatomic, strong) IBOutlet UIButton *stopButton;
@property (nonatomic, strong) IBOutlet UIButton *startButton;
@property (nonatomic, strong) IBOutlet UITextView *statusTextView;
@property (nonatomic, strong) IBOutlet UILabel *youSaidLabel;
@property (nonatomic, strong) IBOutlet UILabel *pocketsphinxDbLabel;
@property (nonatomic, strong) IBOutlet UILabel *fliteDbLabel;

@property (nonatomic, strong) IBOutlet UIButton *httButton;
@property (nonatomic, strong) IBOutlet UIButton *connectButton;
@property (nonatomic, strong) IBOutlet UIButton *disconnectButton;

@property (nonatomic, strong) IBOutlet UILabel *listeningStatus;
@property (nonatomic, strong) IBOutlet UILabel *recognitionStatus;
@property (nonatomic, strong) IBOutlet UILabel *speechStatus;
@property (nonatomic, strong) IBOutlet UILabel *isSpeakingStatus;

@property (nonatomic, strong) IBOutlet UILabel *oneBar;
@property (nonatomic, strong) IBOutlet UILabel *twoBar;
@property (nonatomic, strong) IBOutlet UILabel *threeBar;
@property (nonatomic, strong) IBOutlet UILabel *rssiLabel;
@property (nonatomic, strong) IBOutlet UILabel *bluetoothStatus;
@property (nonatomic, strong) IBOutlet UILabel *transmitStatus;

@property (nonatomic, strong) IBOutlet UILabel *redLed;
@property (nonatomic, strong) IBOutlet UILabel *blueLed;
@property (nonatomic, strong) IBOutlet UILabel *greenLed;

@property (nonatomic, assign) int restartAttemptsDueToPermissionRequests;
@property (nonatomic, assign) BOOL startupFailedDueToLackOfPermissions;

// Things which help us show off the dynamic language features.
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedDictionary;

// Our NSTimer that will help us read and display the input and output levels without locking the UI
@property (nonatomic, strong) 	NSTimer *uiUpdateTimer;

// BLE
@property (strong, nonatomic) BLE *ble;

@end
