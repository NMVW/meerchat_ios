/*
     File: CaptureManager.m
 
 Based on AVCamCaptureManager by Apple
 
 Abstract: Uses the AVCapture classes to capture video and still images.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "CaptureManager.h"
#import "BFTMainPostViewController.h"
#import "AVCamRecorder.h"
#import "AVCamUtilities.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>
#import "BFTDataHandler.h"
#import "BFTPostHandler.h"
#import "BFTDatabaseRequest.h"
#import "AFNetworking.h"
#import "BFTAppDelegate.h"
#import "BFTMessageThreads.h"
#import "BFTCaptureManagerDelegate.h"
#import "BFTConstants.h"

#define MAX_DURATION 0.25

@interface CaptureManager (RecorderDelegate) <AVCamRecorderDelegate>
@end


#pragma mark -
@interface CaptureManager (InternalUtilityMethods)
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *) frontFacingCamera;
- (AVCaptureDevice *) backFacingCamera;
- (AVCaptureDevice *) audioDevice;
- (NSURL *) tempFileURL;
- (void) removeFile:(NSURL *)outputFileURL;
- (void) copyFileToDocuments:(NSURL *)fileURL;
@end


#pragma mark -
@implementation CaptureManager

- (instancetype)init {
    self = [super init];
    if (self != nil) {
		__block id weakSelf = self;
        void (^deviceConnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];
			
			BOOL sessionHasDeviceWithMatchingMediaType = NO;
			NSString *deviceMediaType = nil;
			if ([device hasMediaType:AVMediaTypeAudio])
                deviceMediaType = AVMediaTypeAudio;
			else if ([device hasMediaType:AVMediaTypeVideo])
                deviceMediaType = AVMediaTypeVideo;
			
			if (deviceMediaType != nil) {
				for (AVCaptureDeviceInput *input in [self.session inputs])
				{
					if ([[input device] hasMediaType:deviceMediaType]) {
						sessionHasDeviceWithMatchingMediaType = YES;
						break;
					}
				}
				
				if (!sessionHasDeviceWithMatchingMediaType) {
					NSError	*error;
					AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
					if ([self.session canAddInput:input])
						[self.session addInput:input];
				}				
			}
            
			if ([self.delegate respondsToSelector:@selector(captureManagerDeviceConfigurationChanged:)]) {
				[self.delegate captureManagerDeviceConfigurationChanged:self];
			}			
        };
        void (^deviceDisconnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];
			
			if ([device hasMediaType:AVMediaTypeAudio]) {
				[self.session removeInput:[weakSelf audioInput]];
				[weakSelf setAudioInput:nil];
			}
			else if ([device hasMediaType:AVMediaTypeVideo]) {
				[self.session removeInput:[weakSelf videoInput]];
				[weakSelf setVideoInput:nil];
			}
			
			if ([self.delegate respondsToSelector:@selector(captureManagerDeviceConfigurationChanged:)]) {
				[self.delegate captureManagerDeviceConfigurationChanged:self];
			}			
        };
        
        self.assets = [[NSMutableArray alloc] init];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [self setDeviceConnectedObserver:[notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification object:nil queue:nil usingBlock:deviceConnectedBlock]];
        [self setDeviceDisconnectedObserver:[notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification object:nil queue:nil usingBlock:deviceDisconnectedBlock]];
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		
		self.orientation = AVCaptureVideoOrientationPortrait;
    }
    
    return self;
}

- (void) dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:[self deviceConnectedObserver]];
    [notificationCenter removeObserver:[self deviceDisconnectedObserver]];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[self session] stopRunning];
}

- (BOOL) setupSession {
    BOOL success = NO;
	
    // Init the device inputs
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:nil];
    AVCaptureDeviceInput *newAudioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    
    // Create session (use default AVCaptureSessionPresetHigh)
    AVCaptureSession *newCaptureSession = [[AVCaptureSession alloc] init];
    
    
    // Add inputs and output to the capture session
    if ([newCaptureSession canAddInput:newVideoInput]) {
        [newCaptureSession addInput:newVideoInput];
    }
    if ([newCaptureSession canAddInput:newAudioInput]) {
        [newCaptureSession addInput:newAudioInput];
    }

    [self setVideoInput:newVideoInput];
    [self setAudioInput:newAudioInput];
    [self setSession:newCaptureSession];
    
	// Set up the movie file output
    NSURL *outputFileURL = [self tempFileURL];
    AVCamRecorder *newRecorder = [[AVCamRecorder alloc] initWithSession:[self session] outputFileURL:outputFileURL];
    [newRecorder setDelegate:self];
	
	// Send an error to the delegate if video recording is unavailable
	if (![newRecorder recordsVideo] && [newRecorder recordsAudio]) {
		NSString *localizedDescription = NSLocalizedString(@"Video recording unavailable", @"Video recording unavailable description");
		NSString *localizedFailureReason = NSLocalizedString(@"Movies recorded on this device will only contain audio. They will be accessible through iTunes file sharing.", @"Video recording unavailable failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey, 
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey, 
								   nil];
		NSError *noVideoError = [NSError errorWithDomain:@"AVCam" code:0 userInfo:errorDict];
		if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
			[[self delegate] captureManager:self didFailWithError:noVideoError];
		}
	}
	
	[self setRecorder:newRecorder];
	
    success = YES;
    
    return success;
}

- (void)switchCamera
{
    NSArray* inputs = self.session.inputs;
    for (AVCaptureDeviceInput* input in inputs) {
        AVCaptureDevice* device = input.device;
        if ([device hasMediaType: AVMediaTypeVideo]) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice* newCamera = nil;
            AVCaptureDeviceInput* newInput = nil;
            
            if (position == AVCaptureDevicePositionFront)
                newCamera = [self cameraWithPosition: AVCaptureDevicePositionBack];
            else
                newCamera = [self cameraWithPosition: AVCaptureDevicePositionFront];
            
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error: nil] ;
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.session beginConfiguration] ;
            
            [self.session removeInput :input] ;
            [self.session addInput : newInput] ;
            
            //Changes take effect once the outermost commitConfiguration is invoked.
            [self.session commitConfiguration] ;
            break ;
        }
    }
}

- (void) startRecording
{
//    [self MP4NameGet];
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns
		// to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library
		// when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error:
		// after the recorded file has been saved.
        [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}]];
    }
    
    [self removeFile:[[self recorder] outputFileURL]];
    [[self recorder] startRecordingWithOrientation:self.orientation];
}

- (void) stopRecording {
    [[self recorder] stopRecording];
}

- (void) saveVideoWithCompletionBlock:(void (^)(BOOL))completion {
    //Should really be video began saving
    [self.delegate videoUploadBegan];
    
    if ([self.assets count] != 0) {
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        __block CMTime time = kCMTimeZero;
        __block CGAffineTransform translate;
        __block CGSize size;
        
        [self.assets enumerateObjectsUsingBlock:^(AVAsset *asset, NSUInteger idx, BOOL *stop) {

           // AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:string]];//obj]];
            AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                           ofTrack:videoAssetTrack atTime:time error:nil];
            
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:time error:nil];
            
            if(idx == 0)
            {
                // Set your desired output aspect ratio here. 1.0 for square, 16/9.0 for widescreen, etc.
                CGFloat desiredAspectRatio = 1.0;
                CGSize naturalSize = CGSizeMake(videoAssetTrack.naturalSize.width, videoAssetTrack.naturalSize.height);
                CGSize adjustedSize = CGSizeApplyAffineTransform(naturalSize, videoAssetTrack.preferredTransform);
                adjustedSize.width = ABS(adjustedSize.width);
                adjustedSize.height = ABS(adjustedSize.height);
                if (adjustedSize.width > adjustedSize.height) {
                    size = CGSizeMake(adjustedSize.height * desiredAspectRatio, adjustedSize.height);
                    translate = CGAffineTransformMakeTranslation(-(adjustedSize.width - size.width) / 2.0, 0);
                } else {
                    size = CGSizeMake(adjustedSize.width, adjustedSize.width / desiredAspectRatio);
                    translate = CGAffineTransformMakeTranslation(0, -(adjustedSize.height - size.height) / 2.0);
                }
                CGAffineTransform newTransform = CGAffineTransformConcat(videoAssetTrack.preferredTransform, translate);
                [videoTrack setPreferredTransform:newTransform];
                
                // Check the output size - for best results use sizes that are multiples of 16
                // More info: http://stackoverflow.com/questions/22883525/avassetexportsession-giving-me-a-green-border-on-right-and-bottom-of-output-vide
                if (fmod(size.width, 4.0) != 0)
                    NSLog(@"NOTE: The video output width %0.1f is not a multiple of 4, which may cause a green line to appear at the edge of the video", size.width);
                if (fmod(size.height, 4.0) != 0)
                    NSLog(@"NOTE: The video output height %0.1f is not a multiple of 4, which may cause a green line to appear at the edge of the video", size.height);
            }
            
            time = CMTimeAdd(time, asset.duration);
        }];
        
        AVMutableVideoCompositionInstruction *vtemp = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        vtemp.timeRange = CMTimeRangeMake(kCMTimeZero, time);
        
        // Also tried videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack
        AVMutableVideoCompositionLayerInstruction *vLayerInstruction = [AVMutableVideoCompositionLayerInstruction
                                                                        videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        

        [vLayerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
        vtemp.layerInstructions = @[vLayerInstruction];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.renderSize = size;
        videoComposition.frameDuration = CMTimeMake(1,30);
        videoComposition.instructions = @[vtemp];
        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path =  [documentsDirectory stringByAppendingPathComponent:
                                 [NSString stringWithFormat:@"%@.mp4", [[BFTDataHandler sharedInstance] mp4Name]]];
        NSURL *url = [NSURL fileURLWithPath:path];
        
        self.exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                               presetName:AVAssetExportPresetMediumQuality];
        self.exportSession.outputURL = url;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        self.exportSession.shouldOptimizeForNetworkUse = YES;
        self.exportSession.videoComposition = videoComposition;
        
        self.exportProgressBarTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self.delegate selector:@selector(updateProgress) userInfo:nil repeats:YES];
        
        __block id weakSelf = self;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.exportSession.error) {
                    [self.delegate postingFailedWithError:self.exportSession.error];
                }
                else {
                    [weakSelf exportDidFinish:self.exportSession withCompletionBlock:completion];
                }
            });
        }];
    }
}

-(void)exportDidFinish:(AVAssetExportSession*)session withCompletionBlock:(void(^)(BOOL success))completion {
    self.exportSession = nil;
    
    __block id weakSelf = self;
    //delete stored pieces
    [self.assets enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(AVAsset *asset, NSUInteger idx, BOOL *stop) {
        
        NSURL *fileURL = nil;
        if ([asset isKindOfClass:AVURLAsset.class])
        {
            AVURLAsset *urlAsset = (AVURLAsset*)asset;
            fileURL = urlAsset.URL;
        }
        
        if (fileURL)
            [weakSelf removeFile:fileURL];
    }];
    
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        if ([[BFTDataHandler sharedInstance] postView]) {
            NSLog(@"Upload To Post View");
            [self uploadToMainWithURL:outputURL];
            
        }else{
            NSLog(@"Upload To User");
            [self uploadToUserWithURL:outputURL];
        }
    }
    
    //Upload service
    completion(YES);
    
    
    [self.assets removeAllObjects];
}

#pragma mark upload Methods
-(void)uploadToMainWithURL:(NSURL *)URL {
    NSString* videoName = [NSString stringWithFormat:@"%@.mp4",[[BFTDataHandler sharedInstance] mp4Name]];
    
    //NSData *imageData = UIImagePNGRepresentation(uploadThumb);
    NSString *urlString = [NSString stringWithFormat:@"http://www.bafit.mobi/cScripts/v1/uploadVid.php"];

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:urlString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:URL name:@"file" fileName:videoName mimeType:@"video/mp4" error:nil];
    } error:nil];
    
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    [progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionInitial context:nil];
    [progress becomeCurrentWithPendingUnitCount:1];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (!error) {
            NSLog(@"Video Upload Success");
            [self.delegate videoUploadedToNetwork];
            [progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) context:nil];
            
            [self generateImageFromURI:URL];
            [self PostVideoToMain];
        }
        else {
            [self.delegate postingFailedWithError:error];
        }
    }];
    
    [uploadTask resume];
}

-(void)uploadToUserWithURL:(NSURL *)URL {
    NSString* videoName = [NSString stringWithFormat:@"%@.mp4", [[BFTDataHandler sharedInstance] mp4Name]];
    NSString *thumbName = [NSString stringWithFormat:@"%@.jpg", [[BFTDataHandler sharedInstance] mp4Name]];
    NSString *urlString = [NSString stringWithFormat:@"http://www.bafit.mobi/cScripts/v1/uploadVid.php"];
    NSString *videoSaveString = [NSString stringWithFormat:@"http://www.bafit.mobi/userPosts/%@", videoName];
    NSString *thumbSaveString = [NSString stringWithFormat:@"http://bafit.mobi/userPosts/thumb/%@",thumbName];
    [[BFTPostHandler sharedInstance] setXmppVideoURL:videoSaveString];
    [[BFTPostHandler sharedInstance] setXmppThumbURL:thumbSaveString];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:urlString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:URL name:@"file" fileName:videoName mimeType:@"video/mp4" error:nil];
    } error:nil];
    
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    [progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionInitial context:nil];
    [progress becomeCurrentWithPendingUnitCount:1];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (!error) {
            NSLog(@"Video Upload Success");
            [self.delegate videoUploadedToNetwork];
            [progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) context:nil];
            
            [self generateImageFromURI:URL];
            [self sendVideoToUser];
        }
        else {
            [self.delegate postingFailedWithError:error];
        }
    }];
    
    [uploadTask resume];
    
}

-(void)PostVideoToMain {
    BFTDataHandler *data = [BFTDataHandler sharedInstance];
    BFTPostHandler *post = [BFTPostHandler sharedInstance];
    
    //TODO: Fix Category Stuff
    NSString *urlString = [NSString stringWithFormat:@"postVideo.php?UIDr=%@&BUN=%@&hash_tag=%@&category=%zd&GPSLat=%f&GPSLon=%f&FName=%@&MC=%@",[post postUID], [data BUN], [post postHash_tag], [post postCategory] == 0 ? 1 : [post postCategory], [post postGPSLat], [post postGPSLon], [post postFName], [post postMC]];
    [[[BFTDatabaseRequest alloc] initWithURLString:urlString completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([responseString boolValue]) {
                NSLog(@"Video Successfully Posted To Main");
                [self.delegate videoPostedToMain];
            }
            else {
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:responseString forKey:NSUnderlyingErrorKey];
                [details setValue:@"Video could not be posted to main" forKey:NSLocalizedDescriptionKey];
                
                NSError *error = [[NSError alloc] initWithDomain:@"com.bafit.videopostingerror" code:1 userInfo:details];
                [self.delegate postingFailedWithError:error];
            }
        }
        else{
            NSLog(@"Could Not Post Video To Main");
            [self.delegate postingFailedWithError:error];
        }
    }] startConnection];
}

-(void)sendVideoToUser {
    //xmpp toUser
    NSLog(@"\n\nSending Video To: %@\nWith URL: %@\nThumb URL: %@\n\n", [[BFTPostHandler sharedInstance] xmmpToUser], [[BFTPostHandler sharedInstance] xmppVideoURL], [[BFTPostHandler sharedInstance] xmppThumbURL]);
    self.appDelegate = (BFTAppDelegate*)[[UIApplication sharedApplication] delegate];
    [self.appDelegate sendVideoMessageWithURL:[[BFTPostHandler sharedInstance] xmppVideoURL] thumbURL:[[BFTPostHandler sharedInstance] xmppThumbURL] toUser:[[BFTPostHandler sharedInstance] xmmpToUser]];
    [self.delegate videoSentToUser];
}

-(NSString *)MP4NameGet {
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"http://bafit.mobi/cScripts/v1/registerVid.php?UIDr=%@&UIDp=%@", [[BFTDataHandler sharedInstance] UID], [[BFTDataHandler sharedInstance] UID]] completionBlock:^(NSMutableData *data, NSError *error) {
        
        if (!error) {
            NSArray *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            for (NSDictionary *dict in responseJSON) {
                self.mp4Name = [dict objectForKey:@"FName"];
                NSLog(@"Video Name: %@", self.mp4Name);
            }
        }
        else{
            [self.delegate postingFailedWithError:error];
        }
    }] startConnection];
    
    return self.mp4Name;
}

#pragma mark Capture Image From URL
-(void)generateImageFromURI:(NSURL *)url
{
    _thumbImg = [[UIImage alloc] init];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(1,1);
    CGImageRef imageRef = [generator copyCGImageAtTime:thumbTime actualTime:nil error:nil];
    _thumbImg = [UIImage imageWithCGImage:imageRef];

    [self uploadImageThumb:_thumbImg];
}

-(void)uploadImageThumb:(UIImage *)imageThumb{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    //write Jpeg to file
    NSString *jpegFilePath = [NSString stringWithFormat:@"%@/%@.jpg", docDir, [[BFTDataHandler sharedInstance] mp4Name]];
    NSData *imageData = UIImageJPEGRepresentation(imageThumb, .8);
    [imageData writeToFile:jpegFilePath atomically:YES];
    
    NSString* thumbName = [NSString stringWithFormat:@"%@.jpg",[[BFTDataHandler sharedInstance] mp4Name]];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.bafit.mobi/"]];
    
    AFHTTPRequestOperation *op = [manager POST:@"cScripts/v1/uploadThumb.php" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"file" fileName:thumbName mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success: %@", operation.responseString);
        [self.delegate imageUploaded];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.delegate postingFailedWithError:error];
    }];
    op.responseSerializer = [AFHTTPResponseSerializer serializer];
    op.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [op start];
    
    //remove file form directory
    [self removeImage:[NSString stringWithFormat:@"%@.jpeg", [[BFTDataHandler sharedInstance] mp4Name]]];
}

- (void)removeImage:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:fileName];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (success) {
        NSLog(@"File removed succesfully");
    }
    else {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
}


#pragma mark Device Counts
- (NSUInteger) cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (NSUInteger) micCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] count];
}


#pragma mark Camera Properties
// Perform an auto focus at the specified point. The focus mode will automatically change to locked once the auto focus is complete.
- (void) autoFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        } else {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
            }
        }        
    }
}

// Switch to continuous auto focus mode at the specified point
- (void) continuousFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
	
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
		NSError *error;
		if ([device lockForConfiguration:&error]) {
			[device setFocusPointOfInterest:point];
			[device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
			[device unlockForConfiguration];
		} else {
			if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
			}
		}
	}
}


-(void) deleteLastAsset
{
    AVAsset *asset = [self.assets lastObject];
    
    [self.delegate removeTimeFromDuration:CMTimeGetSeconds(asset.duration)];
    
    NSURL *fileURL = nil;
    if ([asset isKindOfClass:AVURLAsset.class])
    {
        AVURLAsset *urlAsset = (AVURLAsset*)asset;
        fileURL = urlAsset.URL;
    }
    
    if (fileURL)
        [self removeFile:fileURL];
    
    [self.assets removeLastObject];
}

#pragma mark delegate stuff

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSProgress *progress = object;
        [self.delegate videoUploadMadeProgress:progress.fractionCompleted];
    }];
}

@end

#pragma mark - CaptureManager Internal Utility Methods
@implementation CaptureManager (InternalUtilityMethods)

// Find a camera with the specificed AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

// Find a front facing camera, returning nil if one is not found
- (AVCaptureDevice *) frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

// Find a back facing camera, returning nil if one is not found
- (AVCaptureDevice *) backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

// Find and return an audio device, returning nil if one is not found
- (AVCaptureDevice *) audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0) {
        return [devices objectAtIndex:0];
    }
    return nil;
}

- (NSURL *)tempFileURL
{
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"]];
}

- (void)removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
            }            
        }
    }
}

- (void) copyFileToDocuments:(NSURL *)fileURL
{
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
	NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/output_%@.mov", [dateFormatter stringFromDate:[NSDate date]]];
    
	NSError	*error;
	if (![[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:destinationPath] error:&error]) {
		if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
			[[self delegate] captureManager:self didFailWithError:error];
		}
	}
    
    //add asset into the array or pieces
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:destinationPath]];
    [self.assets addObject:asset];
}

@end


#pragma mark -
@implementation CaptureManager (RecorderDelegate)

-(void)recorderRecordingDidBegin:(AVCamRecorder *)recorder
{
    if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingBegan:)]) {
        [[self delegate] captureManagerRecordingBegan:self];
    }
}

-(void)recorder:(AVCamRecorder *)recorder recordingDidFinishToOutputFileURL:(NSURL *)outputFileURL error:(NSError *)error
{
    //save file in the app's Documents directory for this session
    [self copyFileToDocuments:outputFileURL];
    
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundRecordingID]];
    }
    
    if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingFinished:)]) {
        [[self delegate] captureManagerRecordingFinished:self];
    }
}

@end

