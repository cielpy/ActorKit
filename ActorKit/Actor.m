//
//  Actor.m
//  ActorKit
//
//  Created by Steve Dekorte on 20110830.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Actor.h"
#import "Coroutine.h"

@implementation Actor

@synthesize firstFuture;
@synthesize coroutine;

- (id)init
{
    self = [super init];
    
	if (self) 
	{
		[self setCoroutine:[[[Coroutine alloc] init] autorelease]];
		[coroutine setTarget:self];
		[coroutine setAction:@selector(runLoop)];
    }
    
    return self;
}

- (void)dealloc
{
	// coros retain the Future's they are waiting on, which retains the actor
	// so dealloc shouldn't only occur when it's safe of dependencies 
	[self setFirstFuture:nil];
	[self setCoroutine:nil];
	[super dealloc];
}

- (void)asyncPerformSelector:(SEL)selector withObject:anObject
{
	[self futurePerformSelector:selector withObject:anObject];
}

- (Future *)futurePerformSelector:(SEL)selector withObject:anObject
{
	Future *future = [[[Future alloc] init] autorelease];
	
	[future setSelector:selector];
	[future setArgument:anObject];
	[firstFuture append:future];
	[coroutine scheduleLast];
	
	return future;
}

- (void)runLoop
{
	while(YES)
	{	
		while (firstFuture)
		{
			[firstFuture send];
			[self setFirstFuture:[firstFuture nextFuture]];
			[coroutine yield];
		}
		
		[coroutine unschedule];
	}
}

@end