//
//  ViewController.m
//  SpeechBlinker
//
//  Created by David Ecker on 4/17/14.
//  Copyright (c) 2014 David Ecker. All rights reserved.
//

#import "ViewController.h"
#import <OpenEars/LanguageModelGenerator.h>
#import <OpenEars/PocketsphinxController.h> // Please note that unlike in previous versions of OpenEars, we now link the headers through the framework.
#import <OpenEars/FliteController.h>
#import <OpenEars/OpenEarsLogging.h>
#import <OpenEars/AcousticModel.h>

#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@end

@implementation ViewController

@synthesize pocketsphinxController;
@synthesize fliteController;
@synthesize startButton;
@synthesize stopButton;
@synthesize statusTextView;
@synthesize pocketsphinxDbLabel;
@synthesize fliteDbLabel;
@synthesize openEarsEventsObserver;
@synthesize pathToFirstDynamicallyGeneratedLanguageModel;
@synthesize pathToFirstDynamicallyGeneratedDictionary;
@synthesize uiUpdateTimer;
@synthesize slt;
@synthesize restartAttemptsDueToPermissionRequests;
@synthesize startupFailedDueToLackOfPermissions;

// speech status indicators
@synthesize recognitionStatus;
@synthesize isSpeakingStatus;
@synthesize listeningStatus;
@synthesize speechStatus;

// bluetooth controls/status indicators
@synthesize httButton;
@synthesize connectButton;
@synthesize disconnectButton;
@synthesize youSaidLabel;
@synthesize oneBar;
@synthesize twoBar;
@synthesize threeBar;
@synthesize rssiLabel;
@synthesize bluetoothStatus;
@synthesize transmitStatus;

// LED status indicators
@synthesize redLed;
@synthesize greenLed;
@synthesize blueLed;

// BLE Stuff
@synthesize ble;

#define kLevelUpdatesPerSecond 18 // We'll have the ui update 18 times a second to show some fluidity without hitting the CPU too hard.

bool isFirstRun = true;
bool ledEnabled = false;
bool torchIsOn = false;

- (void)dealloc {
	[self stopDisplayingLevels]; // We'll need to stop any running timers before attempting to deallocate here.
	openEarsEventsObserver.delegate = nil;
}

// Lazily allocated PocketsphinxController.
- (PocketsphinxController *)pocketsphinxController {
	if (pocketsphinxController == nil) {
		pocketsphinxController = [[PocketsphinxController alloc] init];
        //pocketsphinxController.verbosePocketSphinx = TRUE; // Uncomment me for verbose debug output
        pocketsphinxController.outputAudio = TRUE;
#ifdef kGetNbest
        pocketsphinxController.returnNbest = TRUE;
        pocketsphinxController.nBestNumber = 5;
#endif
	}
	return pocketsphinxController;
}

// Lazily allocated slt voice.
- (Slt *)slt {
	if (slt == nil) {
		slt = [[Slt alloc] init];
	}
	return slt;
}

// Lazily allocated FliteController.
- (FliteController *)fliteController {
	if (fliteController == nil) {
		fliteController = [[FliteController alloc] init];
        
	}
	return fliteController;
}

// Lazily allocated OpenEarsEventsObserver.
- (OpenEarsEventsObserver *)openEarsEventsObserver {
	if (openEarsEventsObserver == nil) {
		openEarsEventsObserver = [[OpenEarsEventsObserver alloc] init];
	}
	return openEarsEventsObserver;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) startListening {
    
    // startListeningWithLanguageModelAtPath:dictionaryAtPath:languageModelIsJSGF always needs to know the grammar file being used,
    // the dictionary file being used, and whether the grammar is a JSGF. You must put in the correct value for languageModelIsJSGF.
    // Inside of a single recognition loop, you can only use JSGF grammars or ARPA grammars, you can't switch between the two types.
    
    // An ARPA grammar is the kind with a .languagemodel or .DMP file, and a JSGF grammar is the kind with a .gram file.
    
    // If you wanted to just perform recognition on an isolated wav file for testing, you could do it as follows:
    
    // NSString *wavPath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"test.wav"];
    //[self.pocketsphinxController runRecognitionOnWavFileAtPath:wavPath usingLanguageModelAtPath:self.pathToGrammarToStartAppWith dictionaryAtPath:self.pathToDictionaryToStartAppWith languageModelIsJSGF:FALSE];  // Starts the recognition loop.
    
    // But under normal circumstances you'll probably want to do continuous recognition as follows:
    
    [self.pocketsphinxController startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to perform Spanish recognition instead of English.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // ble initialization
    ble = [[BLE alloc] init];
    [ble controlSetup];
    ble.delegate = self;
    
    self.restartAttemptsDueToPermissionRequests = 0;
    self.startupFailedDueToLackOfPermissions = FALSE;
    self.httButton.layer.cornerRadius = 5;
    self.httButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.httButton.layer.borderWidth = 0.5;
    self.httButton.hidden = TRUE;

    
    //[OpenEarsLogging startOpenEarsLogging]; // Uncomment me for OpenEarsLogging
    
	[self.openEarsEventsObserver setDelegate:self]; // Make this class the delegate of OpenEarsObserver so we can get all of the messages about what OpenEars is doing.
    
    
    
    // This is the language model we're going to start up with. The only reason I'm making it a class property is that I reuse it a bunch of times in this example,
	// but you can pass the string contents directly to PocketsphinxController:startListeningWithLanguageModelAtPath:dictionaryAtPath:languageModelIsJSGF:
    
    NSArray *firstLanguageArray = [[NSArray alloc] initWithArray:[NSArray arrayWithObjects: // All capital letters.
                                                                  @"LIGHTS",
                                                                  @"OFF",
                                                                  @"RED",
                                                                  @"BLUE",
                                                                  @"GREEN",
                                                                  @"ON",
                                                                  @"AND",
                                                                  @"STOP LISTENING",
                                                                  @"CONNECT",
                                                                  @"DISCONNECT",
                                                                  @"TOGGLE LIGHTS",
                                                                  @"FLASHLIGHT",
                                                                  nil]];
    LanguageModelGenerator *languageModelGenerator = [[LanguageModelGenerator alloc] init];
    
	NSError *error = [languageModelGenerator generateLanguageModelFromArray:firstLanguageArray withFilesNamed:@"FirstOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
    
	NSDictionary *firstDynamicLanguageGenerationResultsDictionary = nil;
	if([error code] != noErr) {
		NSLog(@"Dynamic language generator reported error %@", [error description]);
	} else {
		firstDynamicLanguageGenerationResultsDictionary = [error userInfo];
		
		NSString *lmFile = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"LMFile"];
		NSString *dictionaryFile = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"DictionaryFile"];
		NSString *lmPath = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"LMPath"];
		NSString *dictionaryPath = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"DictionaryPath"];
		
		NSLog(@"Dynamic language generator completed successfully, you can find your new files %@\n and \n%@\n at the paths \n%@ \nand \n%@", lmFile,dictionaryFile,lmPath,dictionaryPath);
        
		self.pathToFirstDynamicallyGeneratedLanguageModel = lmPath;
		self.pathToFirstDynamicallyGeneratedDictionary = dictionaryPath;
	}
    
	// [self startDisplayingLevels] is not an OpenEars method, just an approach for level reading
	// that I've included with this sample app. My example implementation does make use of two OpenEars
	// methods:	the pocketsphinxInputLevel method of PocketsphinxController and the fliteOutputLevel
	// method of fliteController.
	//
	// The example is meant to show one way that you can read those levels continuously without locking the UI,
	// by using an NSTimer, but the OpenEars level-reading methods
	// themselves do not include multithreading code since I believe that you will want to design your own
	// code approaches for level display that are tightly-integrated with your interaction design and the
	// graphics API you choose.
	//
	// Please note that if you use my sample approach, you should pay attention to the way that the timer is always stopped in
	// dealloc. This should prevent you from having any difficulties with deallocating a class due to a running NSTimer process.
	
	[self startDisplayingLevels];
}

// RSSI Timer
NSTimer *rssiTimer;

- (void)bleDidDisconnect
{
    NSLog(@"~~~ BLE Disconnected ~~~");
    [self appendToStatus:@"BLE Disconnected."];
    
    //manipulate the UI to reflect the disconnect
    [connectButton setHidden:false];
    [disconnectButton setHidden:true];
    self.transmitStatus.textColor = [UIColor redColor];
    self.bluetoothStatus.textColor = [UIColor redColor];
    rssiLabel.text = @"---";
    
    oneBar.textColor = [UIColor lightGrayColor];
    twoBar.textColor = [UIColor lightGrayColor];
    threeBar.textColor = [UIColor lightGrayColor];
    
    [rssiTimer invalidate];
}

// When RSSI is changed, this will be called
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
    // update the signal indicator based on RSSI
    rssiLabel.text = rssi.stringValue;
    if (rssi.intValue > -50) {
        oneBar.textColor = [UIColor blackColor];
        twoBar.textColor = [UIColor blackColor];
        threeBar.textColor = [UIColor blackColor];
    }
    else if(rssi.intValue > -70){
        oneBar.textColor = [UIColor blackColor];
        twoBar.textColor = [UIColor blackColor];
        threeBar.textColor = [UIColor lightGrayColor];
    }
    else {
        oneBar.textColor = [UIColor blackColor];
        twoBar.textColor = [UIColor lightGrayColor];
        threeBar.textColor = [UIColor lightGrayColor];
    }
}

-(void) readRSSITimer:(NSTimer *)timer
{
    [ble readRSSI];
}

// This is called when bluetooth is connected
-(void) bleDidConnect
{
    NSLog(@"~~~ BLE Connected ~~~");
    [self appendToStatus:@"BLE Connected."];
    
    //manipulate the UI to reflect the connect
    [connectButton setHidden:true];
    [disconnectButton setHidden:false];
    self.transmitStatus.textColor = [UIColor redColor];
    self.bluetoothStatus.textColor = [UIColor greenColor];
    rssiLabel.text = @"";
    
    // send reset
    UInt8 buf[] = {0x00, 0x00, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
    
    // the LEDs on the board are currently disabled due to the reset signal, update the flag
    ledEnabled = false;
    
    // Schedule to read RSSI every 1 sec.
    rssiTimer = [NSTimer scheduledTimerWithTimeInterval:(float)1.0 target:self selector:@selector(readRSSITimer:) userInfo:nil repeats:YES];
}

// this is for reading data over bluetooth, don't need it for this app
/*-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSLog(@"Length: %d", length);
    
    // parse data, all commands are in 3-byte
    for (int i = 0; i < length; i+=3)
    {
        NSLog(@"0x%02X, 0x%02X, 0x%02X", data[i], data[i+1], data[i+2]);
        
        // do stuff with the data, change the UI
        if (data[i] == 0x0A){}
        
    }
}*/

// What follows are all of the delegate methods you can optionally use once you've instantiated an OpenEarsEventsObserver and set its delegate to self.
// I've provided some pretty granular information about the exact phase of the Pocketsphinx listening loop, the Audio Session, and Flite, but I'd expect
// that the ones that will really be needed by most projects are the following:
//
//- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID;
//- (void) audioSessionInterruptionDidBegin;
//- (void) audioSessionInterruptionDidEnd;
//- (void) audioRouteDidChangeToRoute:(NSString *)newRoute;
//- (void) pocketsphinxDidStartListening;
//- (void) pocketsphinxDidStopListening;
//
// It isn't necessary to have a PocketsphinxController or a FliteController instantiated in order to use these methods.  If there isn't anything instantiated that will
// send messages to an OpenEarsEventsObserver, all that will happen is that these methods will never fire.  You also do not have to create a OpenEarsEventsObserver in
// the same class or view controller in which you are doing things with a PocketsphinxController or FliteController; you can receive updates from those objects in
// any class in which you instantiate an OpenEarsEventsObserver and set its delegate to self.

// An optional delegate method of OpenEarsEventsObserver which delivers the text of speech that Pocketsphinx heard and analyzed, along with its accuracy score and utterance ID.
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID); // Log it.
    
    if([hypothesis isEqualToString:@"STOP LISTENING"]){
        // press stop listening button
        [self stopButtonAction];
    }
    
    if([hypothesis rangeOfString:@"RED ON"].location != NSNotFound){
        //if hypothesis contains "red on" turn red on
        redLed.textColor =[UIColor redColor];
        if (!ledEnabled) {
            [self lightsOn];
            ledEnabled = true;
        }
        [self redOn];
    }
    
    if([hypothesis rangeOfString:@"RED OFF"].location != NSNotFound){
        //if hypothesis contains "red off" turn red off
        redLed.textColor =[UIColor lightGrayColor];
        if (!ledEnabled) {
            [self lightsOn];
            ledEnabled = true;
        }
        [self redOff];
    }
    
    if([hypothesis rangeOfString:@"GREEN ON"].location != NSNotFound){
        //if hypothesis contains "green on" turn green on
        greenLed.textColor =[UIColor greenColor];
        if (!ledEnabled) {
            [self lightsOn];
            ledEnabled = true;
        }
        [self greenOn];
    }
    
    if([hypothesis rangeOfString:@"GREEN OFF"].location != NSNotFound){
        //if hypothesis contains "green off" turn green on
        greenLed.textColor =[UIColor lightGrayColor];
        if (!ledEnabled) {
            [self lightsOn];
            ledEnabled = true;
        }
        [self greenOff];
    }
    
    if([hypothesis rangeOfString:@"BLUE ON"].location != NSNotFound){
        //if hypothesis contains "blue on" turn blue on
        blueLed.textColor =[UIColor blueColor];
        if (!ledEnabled) {
            [self lightsOn];
            ledEnabled = true;
        }
        [self blueOn];
    }
    
    if([hypothesis rangeOfString:@"BLUE OFF"].location != NSNotFound){
        //if hypothesis contains "blue off" turn blue off
        blueLed.textColor =[UIColor lightGrayColor];
        if (!ledEnabled) {
            [self lightsOn];
            ledEnabled = true;
        }
        [self blueOff];
    }
    
    
    if([hypothesis rangeOfString:@"TOGGLE LIGHTS"].location != NSNotFound){
        //toggle all the lights on or off
        if (!ledEnabled) {
            [self lightsOn];
            ledEnabled = true;
        }
        else {
            ledEnabled = false;
            [self lightsOff];
        }
    }
    
    if ([hypothesis isEqualToString:@"LIGHTS ON"]) {
        // turn the lights on (ground the led)
        if (!ledEnabled) {
            [self lightsOn];
            ledEnabled = true;
        }
    }
    
    if ([hypothesis isEqualToString:@"LIGHTS OFF"]) {
        // turn the lights off (remove the potential across the led)
        if (ledEnabled) {
            [self lightsOff];
            ledEnabled = false;
        }
    }
    
    if ([hypothesis isEqualToString:@"CONNECT"]) {
        if (connectButton.isHidden) {
            // if the connect button is hidden, then the disconnect button is visible, therefore bluetooth is connected
            // and this command is not applicable
            [self appendToStatus:@"Bluetooth is already connected."];
        }
        else {
            [self connectButtonAction];
        }
    }
    
    if ([hypothesis isEqualToString:@"DISCONNECT"]) {
        if (disconnectButton.isHidden) {
            // if the disconnect button is hidden, then the connect button is visible, therefore bluetooth is disconnected
            // and this command is not applicable
            [self appendToStatus:@"Bluetooth is not connected."];
        }
        else {
            [self disconnectButtonAction];
        }
    }
    
    if ([hypothesis rangeOfString:@"FLASHLIGHT"].location != NSNotFound) {
        // if the user mentions the flashlight, then turn it on
        [self toggleTorch:torchIsOn];
    }
	
    // display the hypothesis in the you said: box
    youSaidLabel.text = [NSString stringWithFormat:@"\"%@\"", hypothesis];
}

// the following group of methods are from the OpenEars sample app. I kept them in here because they help for error logging.

#ifdef kGetNbest
- (void) pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray {
    NSLog(@"hypothesisArray is %@",hypothesisArray);
}
#endif

- (void) audioSessionInterruptionDidBegin {
	NSLog(@"AudioSession interruption began.");
	[self.pocketsphinxController stopListening];
}

- (void) audioSessionInterruptionDidEnd {
	NSLog(@"AudioSession interruption ended.");
    [self startListening];
	
}

- (void) audioInputDidBecomeUnavailable {
	NSLog(@"The audio input has become unavailable");
	[self.pocketsphinxController stopListening];
}

- (void) audioInputDidBecomeAvailable {
	NSLog(@"The audio input is available");
    [self startListening];
}

- (void) audioRouteDidChangeToRoute:(NSString *)newRoute {
	NSLog(@"Audio route change. The new audio route is %@", newRoute); // Log it.
	self.statusTextView.text = [NSString stringWithFormat:@"Status: Audio route change. The new audio route is %@",newRoute];
    
	[self.pocketsphinxController stopListening];
    [self startListening];
}

- (void) pocketsphinxDidStartCalibration {
	NSLog(@"Pocketsphinx calibration has started.");
	self.statusTextView.text = @"Status: Pocketsphinx calibration has started.";
}

- (void) pocketsphinxDidCompleteCalibration {
	NSLog(@"Pocketsphinx calibration is complete.");
    
	self.fliteController.duration_stretch = .9; // Change the speed
	self.fliteController.target_mean = 1.2; // Change the pitch
	self.fliteController.target_stddev = 1.5; // Change the variance
	
    [self.fliteController say:@"Welcome to SpeechBlinker." withVoice:self.slt];
    // The same statement with the pitch and other voice values changed.
	
	self.fliteController.duration_stretch = 1.0; // Reset the speed
	self.fliteController.target_mean = 1.0; // Reset the pitch
	self.fliteController.target_stddev = 1.0; // Reset the variance
}

- (void) pocketsphinxRecognitionLoopDidStart {
	NSLog(@"Pocketsphinx is starting up.");
}

- (void) pocketsphinxDidStartListening {
	
	NSLog(@"Pocketsphinx is now listening.");
	
	self.startButton.hidden = TRUE;
	self.stopButton.hidden = FALSE;
    
    self.listeningStatus.textColor = [UIColor greenColor];
    self.speechStatus.textColor = [UIColor redColor];
}

- (void) pocketsphinxDidDetectSpeech {
	NSLog(@"Pocketsphinx has detected speech.");
    
    self.speechStatus.textColor = [UIColor greenColor];
}

- (void) pocketsphinxDidDetectFinishedSpeech {
	NSLog(@"Pocketsphinx has detected a second of silence, concluding an utterance.");
    
    self.speechStatus.textColor = [UIColor redColor];
}

- (void) pocketsphinxDidStopListening {
	NSLog(@"Pocketsphinx has stopped listening.");
    
    self.listeningStatus.textColor = [UIColor redColor];
    self.recognitionStatus.textColor = [UIColor redColor];
}

- (void) pocketsphinxDidSuspendRecognition {
	NSLog(@"Pocketsphinx has suspended recognition.");

    self.recognitionStatus.textColor = [UIColor redColor];
}

- (void) pocketsphinxDidResumeRecognition {
	NSLog(@"Pocketsphinx has resumed recognition.");
    
    self.recognitionStatus.textColor = [UIColor greenColor];
    
    //hack-y method of preventing recognition after starting listening
    if (isFirstRun) {
        [self suspendListeningButtonAction];
        isFirstRun = FALSE;
    }
    else {
        self.recognitionStatus.textColor = [UIColor greenColor];
    }
}

- (void) fliteDidStartSpeaking {
	NSLog(@"Flite has started speaking");
    
    self.isSpeakingStatus.textColor = [UIColor greenColor];
}

- (void) fliteDidFinishSpeaking {
	NSLog(@"Flite has finished speaking");
    
    self.isSpeakingStatus.textColor = [UIColor redColor];
}

- (void) pocketSphinxContinuousSetupDidFail {
	NSLog(@"Setting up the continuous recognition loop has failed for some reason, please turn on [OpenEarsLogging startOpenEarsLogging] in OpenEarsConfig.h to learn more.");
}

- (void) testRecognitionCompleted {
	NSLog(@"A test file which was submitted for direct recognition via the audio driver is done.");
    [self.pocketsphinxController stopListening];
    
}

- (void) pocketsphinxFailedNoMicPermissions {
    NSLog(@"The user has never set mic permissions or denied permission to this app's mic, so listening will not start.");
    self.startupFailedDueToLackOfPermissions = TRUE;
}

- (void) micPermissionCheckCompleted:(BOOL)result {
    if(result == TRUE) {
        self.restartAttemptsDueToPermissionRequests++;
        if(self.restartAttemptsDueToPermissionRequests == 1 && self.startupFailedDueToLackOfPermissions == TRUE) { // If we get here because there was an attempt to start which failed due to lack of permissions, and now permissions have been requested and they returned true, we restart exactly once with the new permissions.
            [self startListening]; // Only do this once.
            self.startupFailedDueToLackOfPermissions = FALSE;
        }
    }
}

// UI button actions:

// suspend recognition when the user stops pressing the htt button
- (IBAction) suspendListeningButtonAction {
    // if you are currently speaking and let go of the button, the app sort-of crashes,
    // this is my attempt at fixing the problem
    if(self.speechStatus.textColor != [UIColor greenColor]){
        [self.pocketsphinxController suspendRecognition];
        
        self.httButton.layer.backgroundColor = [UIColor whiteColor].CGColor;
        self.startButton.hidden = TRUE;
        self.stopButton.hidden = FALSE;
    }
}

// begin recognition when the user presses the htt button
- (IBAction) resumeListeningButtonAction { // This is the action for the button which resumes listening if it has been suspended
	if(self.speechStatus.textColor != [UIColor greenColor]){
        [self.pocketsphinxController resumeRecognition];
        
        self.httButton.layer.backgroundColor = [UIColor lightGrayColor].CGColor;
        self.startButton.hidden = TRUE;
        self.stopButton.hidden = FALSE;
    }
}

- (IBAction) stopButtonAction { // This is the action for the button which shuts down the recognition loop.
	[self.pocketsphinxController stopListening];
	
	self.startButton.hidden = FALSE;
	self.stopButton.hidden = TRUE;
    self.httButton.hidden = TRUE;
}

- (IBAction) startButtonAction { // This is the action for the button which starts up the recognition loop again if it has been shut down.
    [self startListening];
	
	self.startButton.hidden = TRUE;
	self.stopButton.hidden = FALSE;
    self.httButton.hidden = FALSE;
    isFirstRun = true;
}

- (IBAction) connectButtonAction{
    
    [self appendToStatus:@"Connecting to Bluetooth hardware."];
    
    if (ble.peripherals)
        ble.peripherals = nil;
    
    [ble findBLEPeripherals:2];
    
    // Allow the device to search for a bluetooth device for 3 seconds
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    [connectButton setEnabled:false];
}

-(void) connectionTimer:(NSTimer *)timer
{
    if (ble.peripherals.count > 0)
    {
        [ble connectPeripheral:[ble.peripherals objectAtIndex:0]];
        [connectButton setEnabled:true];
        [connectButton setHidden:true];
        [disconnectButton setHidden:false];
    }
    else
    {
        [connectButton setEnabled:true];
        [connectButton setHidden:false];
        [disconnectButton setHidden:true];
        [self appendToStatus:@"Cannot find any Bluetooth hardware."];
    }
}

- (IBAction) disconnectButtonAction{
    //disconnect from the ble board
    [ble.CM cancelPeripheralConnection: ble.activePeripheral];
    [self appendToStatus:@"Disconnecting from Bluetooth hardware."];
    redLed.textColor = [UIColor lightGrayColor];
    greenLed.textColor = [UIColor lightGrayColor];
    blueLed.textColor = [UIColor lightGrayColor];
}

-(IBAction)sendData:(UInt8[3]) buf
{
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}

- (void) toggleTorch: (bool) on {
    
    // check if flashlight available
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            [device lockForConfiguration:nil];
            if (!on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                torchIsOn = TRUE;
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                torchIsOn = FALSE;
            }
            [device unlockForConfiguration];
        }
    }
}

/*
 Light commands structure looks like this:
 000 - disable LED (set common cathode to high)
 010 - enable LED (set common cathode to low)
 100 - no lights (all signal bits high)
 110 - red on
 120 - red off
 130 - green on
 140 - green off
 150 - blue on
 160 - blue off
*/

- (void) redOn {
    UInt8 buf[3] = {0x01, 0x01, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
    //update the UI
}

- (void) blueOn {
    UInt8 buf[3] = {0x01, 0x05, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}

- (void) greenOn {
    UInt8 buf[3] = {0x01, 0x03, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}

- (void) redOff {
    UInt8 buf[3] = {0x01, 0x02, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}

- (void) blueOff {
    UInt8 buf[3] = {0x01, 0x06, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}

- (void) greenOff {
    UInt8 buf[3] = {0x01, 0x04, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}

- (void) lightsOn{
    UInt8 buf[3] = {0x00, 0x00, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
    ledEnabled = true;
}

- (void) lightsOff{
    UInt8 buf[3] = {0x00, 0x01, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
    ledEnabled = false;
}

// What follows are not OpenEars methods, just an approach for level reading
// that I've included with this sample app. My example implementation does make use of two OpenEars
// methods:	the pocketsphinxInputLevel method of PocketsphinxController and the fliteOutputLevel
// method of fliteController.
//
// The example is meant to show one way that you can read those levels continuously without locking the UI,
// by using an NSTimer, but the OpenEars level-reading methods
// themselves do not include multithreading code since I believe that you will want to design your own
// code approaches for level display that are tightly-integrated with your interaction design and the
// graphics API you choose.
//
// Please note that if you use my sample approach, you should pay attention to the way that the timer is always stopped in
// dealloc. This should prevent you from having any difficulties with deallocating a class due to a running NSTimer process.

- (void) startDisplayingLevels { // Start displaying the levels using a timer
	[self stopDisplayingLevels]; // We never want more than one timer valid so we'll stop any running timers first.
	self.uiUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/kLevelUpdatesPerSecond target:self selector:@selector(updateLevelsUI) userInfo:nil repeats:YES];
}

- (void) stopDisplayingLevels { // Stop displaying the levels by stopping the timer if it's running.
	if(self.uiUpdateTimer && [self.uiUpdateTimer isValid]) { // If there is a running timer, we'll stop it here.
		[self.uiUpdateTimer invalidate];
		self.uiUpdateTimer = nil;
	}
}

- (void) updateLevelsUI { // And here is how we obtain the levels.  This method includes the actual OpenEars methods and uses their results to update the UI of this view controller.
    
	self.pocketsphinxDbLabel.text = [NSString stringWithFormat:@"Pocketsphinx Input level:%f",[self.pocketsphinxController pocketsphinxInputLevel]];  //pocketsphinxInputLevel is an OpenEars method of the class PocketsphinxController.
    
	if(self.fliteController.speechInProgress == TRUE) {
		self.fliteDbLabel.text = [NSString stringWithFormat:@"Flite Output level: %f",[self.fliteController fliteOutputLevel]]; // fliteOutputLevel is an OpenEars method of the class FliteController.
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) appendToStatus: (NSString *)message
{
    if (statusTextView.text.length == 0) {
        //first line
        [statusTextView setText:[NSString stringWithFormat:@"- %@", message]];
    }
    else {
        //if there is already text in the status box, append dashes and the message
        [statusTextView setText:[NSString stringWithFormat:@"%@\n- %@", statusTextView.text, message]];
        //scroll to the bottom
        NSRange range = NSMakeRange(statusTextView.text.length - 1, 1);
        [statusTextView scrollRangeToVisible:range];
    }
}

@end
