//
//  FaceDetectionThread.m
//  VampireDetector
//
//  Created by Michael Bruno on 9/23/15.
//  Copyright (c) 2015 Apollonarius. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <assert.h>
#import <pthread.h>

void *PosixThreadMainRoutine(void *data){
    
    
    return NULL;
}

void LaunchThread(){
    
    pthread_attr_t attr;
    pthread_t posixThreadId;
    int r;
    
    r = pthread_attr_init(&attr);
    assert(!r);
    r = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!r);
    
    int threadError = pthread_create(&posixThreadId, &attr, &PosixThreadMainRoutine, NULL);
    
    r = pthread_attr_destroy(&attr);
    assert(!r);
    
    if(threadError != 0){
        // whatever
    }
    
}