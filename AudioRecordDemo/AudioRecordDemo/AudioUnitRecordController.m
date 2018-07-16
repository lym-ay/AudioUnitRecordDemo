//
//  AudioUnitRecordController.m
//  AudioRecordDemo
//
//  Created by olami on 2018/7/16.
//  Copyright © 2018年 VIA Technologies, Inc. & OLAMI Team. All rights reserved.
//

#import "AudioUnitRecordController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioUnitRecordController(){
    AudioUnit recordUnit;
    AudioBufferList *bufferList;
    NSMutableData *pcmData;
    
}
@end


@implementation AudioUnitRecordController



- (id)init{
    if (self = [super init]) {
        pcmData = [[NSMutableData alloc] init];
    }
    
    return self;
}


- (void)setupOutputUnit{
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:0.022 error:&error];
    if (error) {
        NSLog(@"audiosession error is %@",error.localizedDescription);
        return;
    }
    
    AudioComponentDescription recordDesc;
    recordDesc.componentType = kAudioUnitType_Output;
    recordDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    recordDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    recordDesc.componentFlags = 0;
    recordDesc.componentFlagsMask = 0;
    
    AudioComponent recordComponent = AudioComponentFindNext(NULL, &recordDesc);
    OSStatus status;
    status = AudioComponentInstanceNew(recordComponent, &recordUnit);
    if (status != noErr) {
        NSLog(@"AudioComponentInstanceNew status is %d",(int)status);
    }
    
    AudioStreamBasicDescription recordFormat;
    recordFormat.mSampleRate = 44100;
    recordFormat.mFormatID = kAudioFormatLinearPCM;
    recordFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger;
    recordFormat.mFramesPerPacket = 1;
    recordFormat.mChannelsPerFrame = 1;
    recordFormat.mBitsPerChannel = 16;
    recordFormat.mBytesPerFrame = recordFormat.mBytesPerPacket = 2;
    status = AudioUnitSetProperty(recordUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &recordFormat, sizeof(recordFormat));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty status is %d",(int)status);
    }
    
    // enable record
    UInt32 flag = 1;
    status = AudioUnitSetProperty(recordUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  1,
                                  &flag,
                                  sizeof(flag));
    if (status != noErr) {
        NSLog(@"AudioUnitGetProperty error, ret: %d", status);
    }
    
    AURenderCallbackStruct recordCallback;
    recordCallback.inputProcRefCon = (__bridge void * _Nullable)(self);
    recordCallback.inputProc = RecordCallback;
    status = AudioUnitSetProperty(recordUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Output, 1, &recordCallback, sizeof(recordCallback));
    if (status != noErr) {
        NSLog(@"AURenderCallbackStruct error, ret: %d", status);
    }
    
    
    uint32_t numberBuffers = 1;
    UInt32 bufferSize = 2048;
    bufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList));
    
    bufferList->mNumberBuffers = numberBuffers;
    bufferList->mBuffers[0].mData = malloc(bufferSize);
    bufferList->mBuffers[0].mDataByteSize = bufferSize;
    bufferList->mBuffers[0].mNumberChannels = 1;
    
    
    OSStatus result = AudioUnitInitialize(recordUnit);
    NSLog(@"result %d", result);
    
}

static OSStatus RecordCallback(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *ioData){
    AudioUnitRecordController *self = (__bridge AudioUnitRecordController*)inRefCon;
    if (inNumberFrames > 0) {
        self->bufferList->mNumberBuffers = 1;
        OSStatus stauts = AudioUnitRender(self->recordUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, self->bufferList);
        if (stauts != noErr) {
            NSLog(@"recordcallback error is %d",stauts);
        }
        
        [self->pcmData appendBytes:self->bufferList->mBuffers[0].mData length:self->bufferList->mBuffers[0].mDataByteSize];
        
    }
    return noErr;
}



- (NSString*)creatFilePath{
    NSString *folderPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"wav"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager createDirectoryAtPath:folderPath
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
    
    NSString *filePath = [folderPath stringByAppendingPathComponent:@"record.pcm"];
    [fileManager createFileAtPath:filePath contents:nil
                       attributes:nil];
    NSLog(@"filePath is %@",filePath);
    return filePath;
}

- (void)writeFile{
    NSString *path = [self creatFilePath];
    [self->pcmData writeToFile:path options:NSDataWritingAtomic error:nil];
}

- (void)recordAction{
    [self setupOutputUnit];
    AudioOutputUnitStart(recordUnit);
}

- (void)stopRecord{
    AudioOutputUnitStop(recordUnit);
    AudioUnitUninitialize(recordUnit);
    
    if (bufferList != NULL) {
        if (bufferList->mBuffers[0].mData) {
            free(bufferList->mBuffers[0].mData);
            bufferList->mBuffers[0].mData = NULL;
        }
        free(bufferList);
        bufferList = NULL;
    }
    
     AudioComponentInstanceDispose(recordUnit);
    [self writeFile];
}
@end
