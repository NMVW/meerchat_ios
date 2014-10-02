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
#import "BFTMeerPostViewController.h"
#import "AVCamRecorder.h"
#import "AVCamUtilities.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>
#import "BFTDataHandler.h"
#import "BFTDatabaseRequest.h"
#import "AFNetworking.h"

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

- (id) init
{
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

- (BOOL) setupSession
{
    BOOL success = NO;
    
    //Torch or flash can be set here. I personaly don't like it 
	// Set torch and flash mode to auto
/*	if ([[self backFacingCamera] hasFlash]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
			if ([[self backFacingCamera] isFlashModeSupported:AVCaptureFlashModeAuto]) {
				[[self backFacingCamera] setFlashMode:AVCaptureFlashModeAuto];
			}
			[[self backFacingCamera] unlockForConfiguration];
		}
	}
	if ([[self backFacingCamera] hasTorch]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
			if ([[self backFacingCamera] isTorchModeSupported:AVCaptureTorchModeAuto]) {
				[[self backFacingCamera] setTorchMode:AVCaptureTorchModeAuto];
			}
			[[self backFacingCamera] unlockForConfiguration];
		}
	}*/
	
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

- (void) stopRecording
{
    [[self recorder] stopRecording];
}

- (void) saveVideoWithCompletionBlock:(void (^)(BOOL))completion
{
    if ([self.assets count] != 0) {

        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        // 2 - Video track
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];        
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
        NSLog(@"\nInstruction vtemp's time range is %f %f", CMTimeGetSeconds( vtemp.timeRange.start),
              CMTimeGetSeconds(vtemp.timeRange.duration));
        
        // Also tried videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack
        AVMutableVideoCompositionLayerInstruction *vLayerInstruction = [AVMutableVideoCompositionLayerInstruction
                                                                        videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        

        [vLayerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
        vtemp.layerInstructions = @[vLayerInstruction];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.renderSize = size;
        videoComposition.frameDuration = CMTimeMake(1,30);
        videoComposition.instructions = @[vtemp];
        
        // 4 - Get path
//        NSString *nameOfMP4 = self.mp4Name;
//        nameOfMP4 = [self MP4NameGet];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path =  [documentsDirectory stringByAppendingPathComponent:
                                 [NSString stringWithFormat:@"%@.mp4", [[BFTDataHandler sharedInstance] mp4Name]]];
        NSURL *url = [NSURL fileURLWithPath:path];
        NSLog(@"Path of URL File: %@", path);

        // 5 - Create exporter
        self.exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                          presetName:AVAssetExportPresetPassthrough];
        self.exportSession.outputURL = url;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        self.exportSession.shouldOptimizeForNetworkUse = YES;
        self.exportSession.videoComposition = videoComposition;
        
        //self.exportProgressBarTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self.delegate selector:@selector(updateProgress) userInfo:nil repeats:YES];
        
        __block id weakSelf = self;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            NSLog (@"i is in your block, exportin. status is %ld",(long)self.exportSession.status);
            dispatch_async(dispatch_get_main_queue(), ^{
                //Try to set Bool for View in DataHandler and Pass it with Completion Block, handle in exportDidFinish
                [weakSelf exportDidFinish:self.exportSession withCompletionBlock:completion];
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
        NSLog(@"File Url: %@", fileURL);
    }];
    
    //[self.assets removeAllObjects];
    //[self.delegate removeProgress];
    
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        NSLog(@" Output URL: %@", outputURL);
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
//            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
//                //delete file from documents after saving to camera roll
//                [weakSelf removeFile:outputURL];
//        
//                if (error) {
//                    completion (NO);
//                } else {
//                    completion (YES);
//                }
//            }];
//        }
        BOOL test = [[BFTDataHandler sharedInstance] postView];
        NSLog(test ? @"Test is YES" : @"Test is NO");
        if ([[BFTDataHandler sharedInstance] postView]) {
            //post to main
            NSLog(@"inside post to main");
            [self uploadToMainWithURL:outputURL];
            
        }else{
            //post to user
            NSLog(@"inside post to user");
        }
        
//        if ([_postFromView isEqualToString:@"toMainView"]) {
//            //handle post to main view
//            NSLog(@"Inside View from Main");
//            _meerPost = [[BFTMeerPostViewController alloc] init];
//            [_meerPost uploadToMain];
//        }
//        if ([_postFromView isEqualToString:@"postToUser"]) {
//            //handle post to another user
//        }
    }
    
    //Upload service
    completion(YES);
    
    
    [self.assets removeAllObjects];
}

#pragma mark upload Methods
-(void)uploadToMainWithURL:(NSURL *)URL {

    NSLog(@"URL: %@", URL);
    //upload thumb image
    UIImage *uploadThumb = [[UIImage alloc] init];
    uploadThumb = [self generateImageFromURI:URL];
    
    NSString* thumbName = [NSString stringWithFormat:@"%@.mp4",[[BFTDataHandler sharedInstance] mp4Name]];
    
    NSData *imageData = UIImagePNGRepresentation(uploadThumb);
    NSString *urlString = [NSString stringWithFormat:@"http:www.bafit.mobi/cScripts/v1/uploadVid.php"];

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:urlString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:URL name:@"file" fileName:thumbName mimeType:@"video/mp4" error:nil];
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSProgress *progress = nil;
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
        }
    }];
    
    [uploadTask resume];
    
//   AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html; video/mp4"];
//    [manager POST:@"http:www.bafit.mobi/cScripts/v1/uploadVid.php"
//       parameters:nil
//constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
//    [formData appendPartWithFileURL:URL name:[[BFTDataHandler sharedInstance] mp4Name] error:nil];
//} success:^(AFHTTPRequestOperation *operation, id responseObject) {
//    NSLog(@"Success: %@", responseObject);
//} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//    NSLog(@"Error: %@", error);
//}];
    
    //new code
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http:www.bafit.mobi/cScripts/v1/uploadVid.php"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:6000.0];
//    [request setHTTPMethod:@"POST"];
//    [request setValue:@"postLength" forHTTPHeaderField:@"Content-Length"];
//    [request setValue:@"application/x-www-form-urlencoded; boundary=AaB03x" forHTTPHeaderField:@"Content-Type"];
    
//    [request setValue:@"/" forHTTPHeaderField:@"Content-Type"];
//    NSError *error;
//    [request setHTTPBody: [NSData dataWithContentsOfURL:URL options:0 error:&error]];
//    NSLog(@"Data Length in MB: %@",[NSByteCountFormatter stringFromByteCount:[[NSData dataWithContentsOfURL:URL] length] countStyle:NSByteCountFormatterCountStyleFile]);
    
//    NSInputStream *videoStream = [[NSInputStream alloc] initWithURL:URL];
//    [request setHTTPBodyStream:videoStream];
    
//    [NSURLConnection connectionWithRequest:request delegate:self];
    
    
//    //Newest Code
//    NSLog(@"POSTING");
//    
//    // Generate the postdata:
//    NSData *postData = [NSData dataWithContentsOfURL:URL];
//    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
//
//    // Setup the request:
//    NSMutableURLRequest *uploadRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http:www.bafit.mobi/cScripts/v1/uploadVid.php"] cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 30];
//    [uploadRequest setHTTPMethod:@"POST"];
//    [uploadRequest setValue:@"text/html" forHTTPHeaderField:@"Accept"];
//    [uploadRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
//    [uploadRequest setValue:[NSString stringWithFormat:@"%@", [[BFTDataHandler sharedInstance] mp4Name]] forHTTPHeaderField:@"filename"];
//    [uploadRequest setValue:@"multipart/form-data; boundary=AaB03x" forHTTPHeaderField:@"Content-Type"];
//    [uploadRequest setHTTPBody:postData];
    
    // Execute the reqest:
//    NSURLConnection *conn=[[NSURLConnection alloc] initWithRequest:uploadRequest delegate:self];
//    if (conn)
//    {
//        // Connection succeeded
//        NSLog(@"success");
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Got Server Response" message:@"Success" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
//    }
//    else
//    {
//        // Connection failed (cannot reach server).
//        NSLog(@"fail");
//    }

    
    //newest of the newest test code
//    NSString *videoURL = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@", [[BFTDataHandler sharedInstance] mp4Name]] ofType:@"mp4"];
//    NSData *videoData = [NSData dataWithContentsOfURL:URL];
//    
////    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http:www.bafit.mobi"]];
//    AFHTTPRequestOperationManager * manager = [[AFHTTPRequestOperationManager alloc] init];
//    
//    
//    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/cScripts/v1/uploadVid.php" parameters:nil constructingBodyWithBlock:^(id <AFMultipartFormData>formData)
//                                    {
//                                        [formData appendPartWithFileData:videoData name:@"file" fileName: mimeType:@"video/quicktime"];
//                                    }];
//    
//    
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest: request];
//    
//    [operation setUploadProgressBlock:^(NSInteger bytesWritten,long long totalBytesWritten,long long totalBytesExpectedToWrite)
//     {
//         
//         NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
//         
//     }];
//    
//    [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {NSLog(@"Video Uploaded Successfully");}
//                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {NSLog(@"Error : %@",  operation.responseString);}];
//    
//    
//    [operation start];
    
//    NSString *fileNameMP4 = [[BFTDataHandler sharedInstance] mp4Name];
    
    //newest code
//    NSString *urlString = @"http:www.bafit.mobi/cScripts/v1/uploadVid.php";
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//    [request setURL:[NSURL URLWithString:urlString]];
//    [request setHTTPMethod:@"POST"];
//    
//    NSString *contentType = [NSString stringWithFormat:@"video/mp4"];
//    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
//    
//    NSMutableData *body = [NSMutableData data];
//    [body appendData:[[NSString stringWithFormat:@"filename=\"%@\"rn",fileNameMP4] dataUsingEncoding:NSUTF8StringEncoding]];
////    [body appendData:[@"Content-Type: video/mp4" dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[NSData dataWithContentsOfURL:URL]];
////    [body appendData:[[NSString stringWithFormat:@"&s=YL4e6ouKirNDgCk0xV2HKixt&hw=141246514ytdjadh"] dataUsingEncoding:NSUTF8StringEncoding]];
//    [request setHTTPBody:body];
//    
//    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
//    NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
//    NSLog(@"RETURNED:%@",returnString);
    
//    //newest of new code
//    NSString *urlString = @"http:www.bafit.mobi/cScripts/v1/uploadVid.php";
//    NSString *filename = [[BFTDataHandler sharedInstance] mp4Name];
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//    [request setURL:[NSURL URLWithString:urlString]];
//    [request setHTTPMethod:@"POST"];
//    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data;"];
//    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
//    NSMutableData *postbody = [NSMutableData data];
////    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//    [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"%@.mp4\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
//    [postbody appendData:[@"Content-Type: video/mp4\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//    [postbody appendData:[NSData dataWithData:[NSData dataWithContentsOfURL:URL]]];
////    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//    [request setHTTPBody:postbody];
//    
//    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
//    NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
//    NSLog(@"%@", returnString);
    
    
}

-(NSString *)MP4NameGet {
    
//    __block NSString *mp4Name = nil;
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"http://bafit.mobi/cScripts/v1/registerVid.php?UIDr=%@&UIDp=%@", [[BFTDataHandler sharedInstance] UID], [[BFTDataHandler sharedInstance] UID]] completionBlock:^(NSMutableData *data, NSError *error) {
        
        //handle JSON from step one
        if (!error) {
            NSArray *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            for (NSDictionary *dict in responseJSON) {
                NSLog(@"Object value: %@", [dict allKeys]);
                self.mp4Name = [dict objectForKey:@"FName"];
            }
        }else{
            NSLog(@"No Data recived for file type");
        }
    }] startConnection];
    NSLog(@"%@", self.mp4Name);
    return self.mp4Name;
}

#pragma mark Capture Image From URL
-(UIImage *)generateImageFromURI:(NSURL *)url
{
    _thumbImg = [[UIImage alloc] init];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }
        _thumbImg = [UIImage imageWithCGImage:im];
    };
    
    CGSize maxSize = CGSizeMake(320, 180);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
    
    return _thumbImg;
}


#pragma mark Device Counts
- (NSUInteger) cameraCount
{
    NSLog(@"COUNT");
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (NSUInteger) micCount
{
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

@end


#pragma mark -
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
    
    //Upload instead of Save *TEST*
    NSLog(@"File url in Recorder: %@", outputFileURL);
    
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundRecordingID]];
    }
    
    if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingFinished:)]) {
        [[self delegate] captureManagerRecordingFinished:self];
    }
}

@end
