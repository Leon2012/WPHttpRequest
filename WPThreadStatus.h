//
//  WPThreadStatus.h
//  WPHelper
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#ifndef WPHelper_WPThreadStatus_h
#define WPHelper_WPThreadStatus_h

typedef enum _THREAD_STATUS{
    THREAD_WAITTING,
    THREAD_EXECUTING,
    THREAD_FINISHED,
    THREAD_SUSPENDED,
    THREAD_FAILED,
    THREAD_CANCELED
} THREAD_STATUS;

#endif
