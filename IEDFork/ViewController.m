//
//  ViewController.m
//  IEDFork
//
//  Created by Samuel Seng on 10/23/14.
//  Copyright (c) 2014 Samuel Seng. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()



@property (strong, nonatomic) IBOutlet UITextView *textReceived;
@property (strong, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) BLE *bleShield;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textReceived.text=NULL;
    
    self.bleShield = [[BLE alloc] init];
    [self.bleShield controlSetup];
    self.bleShield.delegate = self;
    
    
    LanguageModelGenerator *lmGenerator = [[LanguageModelGenerator alloc] init];
    NSArray* words = [NSArray arrayWithObjects:@"YES", @"CONNECT", nil];
    NSString*name = @"recognitionwords";
    NSError *err = [lmGenerator generateLanguageModelFromArray:words withFilesNamed:name forAcousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"]];
    
    NSDictionary *languageGeneratorResults = nil;
    
    NSString *lmPath = nil;
    NSString *dicPath = nil;
    
    if([err code] == noErr) {
        
        languageGeneratorResults = [err userInfo];
		
        lmPath = [languageGeneratorResults objectForKey:@"LMPath"];
        dicPath = [languageGeneratorResults objectForKey:@"DictionaryPath"];
		
    } else {
        NSLog(@"Error: %@",[err localizedDescription]);
    }
    
    
    [self.openEars setDelegate:self];
    
    [self.pocket startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dicPath acousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:NO];
    
  
    
    [self.flite say:@"For instructions say yes" withVoice:self.s];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) connectionTimer:(NSTimer *)timer
{
    if (self.bleShield.peripherals.count > 0)
    {
        [self.bleShield connectPeripheral:[self.bleShield.peripherals objectAtIndex:0]];
    }
    else
    {
        
    }
}

- (void)bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    self.textReceived.text = s;
}

NSTimer *rssiTimer;

- (void)readRSSITimer:(NSTimer *)timer
{
    [self.bleShield readRSSI];
}

- (void)bleDidDisconnect
{
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    [rssiTimer invalidate];
}

-(void)bleDidConnect
{
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    rssiTimer = [NSTimer scheduledTimerWithTimeInterval:(float)1.0 target:self selector:@selector(readRSSITimer:) userInfo:nil repeats:YES];
}

-(void)bleDidUpdateRSSI:(NSNumber *)rssi {
}
- (IBAction)bleConnectPressed:(id)sender {
    if (self.bleShield.activePeripheral)
    {
        if (self.bleShield.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[self.bleShield CM] cancelPeripheralConnection:[self.bleShield activePeripheral]];
            return;
        }
    }
    if (self.bleShield.peripherals) {
        self.bleShield.peripherals = nil;
    }
    [self.bleShield findBLEPeripherals:3];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
}

- (FliteController *)flite {  //controls the voice
	if (self.fliteController == nil) {
		self.fliteController = [[FliteController alloc] init];
	}
	return self.fliteController;
}

- (Slt *)s { //voice, might want to change
	if (self.slt == nil) {
		self.slt = [[Slt alloc] init];
	}
	return self.slt;
}
- (PocketsphinxController *)pocket{
	if (self.pocketsphinxController == nil) {
		self.pocketsphinxController = [[PocketsphinxController alloc] init];
	}
	return self.pocketsphinxController;
}
- (OpenEarsEventsObserver *)openEars {
	if (self.openEarsEventsObserver == nil) {
		self.openEarsEventsObserver = [[OpenEarsEventsObserver alloc] init];
	}
	return self.openEarsEventsObserver;
}

- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    if([hypothesis isEqualToString:@"YES"])
    {
        [self.flite say:@"Welcome to Fork  It. Forblue tooth connection please say the command: Connect" withVoice:self.s];
        self.textReceived.text= @"You said Yes";
        
        
    }
    if([hypothesis isEqualToString:@"CONNECT"]){
        
        [self bleConnectPressed:nil];
        self.textReceived.text= @"You said Connect";
    }
}

- (void) pocketsphinxDidStartCalibration {
	NSLog(@"Pocketsphinx calibration has started.");
}

- (void) pocketsphinxDidCompleteCalibration {
	NSLog(@"Pocketsphinx calibration is complete.");
}

- (void) pocketsphinxDidStartListening {
	NSLog(@"Pocketsphinx is now listening.");
}

- (void) pocketsphinxDidDetectSpeech {
    
	NSLog(@"Pocketsphinx has detected speech.");
    
}

- (void) pocketsphinxDidDetectFinishedSpeech {
	NSLog(@"Pocketsphinx has detected a period of silence, concluding an utterance.");
}

- (void) pocketsphinxDidStopListening {
	NSLog(@"Pocketsphinx has stopped listening.");
}

- (void) pocketsphinxDidSuspendRecognition {
	NSLog(@"Pocketsphinx has suspended recognition.");
}

- (void) pocketsphinxDidResumeRecognition {
	NSLog(@"Pocketsphinx has resumed recognition.");
}

- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
	NSLog(@"Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
}

- (void) pocketSphinxContinuousSetupDidFail { // This can let you know that something went wrong with the recognition loop startup. Turn on OPENEARSLOGGING to learn why.
	NSLog(@"Setting up the continuous recognition loop has failed for some reason, please turn on OpenEarsLogging to learn more.");
}
- (void) testRecognitionCompleted {
	NSLog(@"A test file that was submitted for recognition is now complete.");
}


@end