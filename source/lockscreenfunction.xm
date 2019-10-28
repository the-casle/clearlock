#import "headers.h"

// Data required for the isOnLockscreen() function. Before anyone says this is overly complicated, it also knows when the iPX is dismissing (hence the sliding controller).
BOOL isUILocked() {
    if(MSHookIvar<NSUInteger>([objc_getClass("SBLockStateAggregator") sharedInstance], "_lockState") == 3) return YES;
    else return NO;
}

static BOOL isOnCoverSheet; // the data that needs to be analyzed
BOOL isOnLockscreen() {
    if(isUILocked()){
        isOnCoverSheet = YES; // This is used to catch an exception where it was locked, but it the isOnCoverSheet didnt update to reflect.
        return YES;
    }
    else if(!isUILocked() && isOnCoverSheet == YES) return YES;
    else if(!isUILocked() && isOnCoverSheet == NO) return NO;
    else return NO;
}

// Setting isOnCoverSheet properly, actually works perfectly
%hook SBCoverSheetSlidingViewController
- (void)_finishTransitionToPresented:(_Bool)arg1 animated:(_Bool)arg2 withCompletion:(id)arg3 {
    if((arg1 == 0) && ([self dismissalSlidingMode] == 1)){
        if(!isUILocked()) isOnCoverSheet = NO;
    } else if ((arg1 == 1) && ([self dismissalSlidingMode] == 1)){
        if(isUILocked()) isOnCoverSheet = YES;
    }
    %orig;
}
%end
