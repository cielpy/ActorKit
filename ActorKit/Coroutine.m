//
//  Coroutine.m
//  CoroutineKit
//
//  Created by Steve Dekorte on 20110830.
//  Copyright 2011 Steve Dekorte. All rights reserved.

#import "Coroutine.h"

static Coroutine *mainCoroutine = nil;
static Coroutine *currentCoroutine = nil;
static NSMutableArray *scheduledCoroutines = nil;

@implementation Coroutine

@synthesize target;
@synthesize action;
@synthesize hasStarted;
@synthesize next;
@synthesize previous;
@synthesize waitingOnFuture;

- (Coro *)coro
{
	return coro;
}

+ (Coroutine *)currentCoroutine
{
	return currentCoroutine;
}

+ (Coroutine *)mainCoroutine
{
	if(!mainCoroutine)
	{
		mainCoroutine = [Coroutine alloc];
		Coro_initializeMainCoro([mainCoroutine coro]);
		currentCoroutine = mainCoroutine;
		scheduledCoroutines = [[NSMutableArray alloc] init];
	}
	
	return mainCoroutine;
}

- (id)init
{
    self = [super init];
	
    if (self) 
	{
		[Coroutine mainCoroutine];
		coro = Coro_new();
    }
    
    return self;
}

- (void)dealloc
{
	Coro_free(coro);
	[super dealloc];
}

- (size_t)stackSize
{
	return Coro_stackSize(coro);
}

- (void)setStackSize:(size_t)size
{
	Coro_setStackSize_(coro, size);
}

- (size_t)bytesLeftOnStack
{
	return Coro_bytesLeftOnStack(coro);
}

//typedef void (CoroStartCallback)(void *);

- (void)startup
{
	[target performSelector:action];
}

static void callback(void *aCoroutine)
{
	Coroutine *self = (Coroutine *)aCoroutine;
	[self startup];
}

- (void)start 
{
	if(hasStarted)
	{
		hasStarted = YES;		
		Coroutine *lastCoroutine = currentCoroutine;
		currentCoroutine = self;
		Coro_startCoro_([lastCoroutine coro], [self coro], (void *)self, callback);
	}
	else
	{
		[NSException raise:@"Coroutine" format:@"attempt to start a Coroutine twice"];
	}
}

- (void)resume
{
	if(!hasStarted)
	{
		[self start];
	}
	else
	{
		Coroutine *lastCoroutine = currentCoroutine;
		currentCoroutine = self;
		Coro_switchTo_([lastCoroutine coro], [self coro]);
	}
}

- (void)remove
{
	[previous setNext:next];
	[self setNext:nil];
	[self setPrevious:nil];
}

- (void)insertFirst:(Coroutine *)aCoroutine
{
	if(aCoroutine == self) return;
	
	[aCoroutine remove];
	[aCoroutine setNext:next];
	[aCoroutine setPrevious:self];	
	[next setPrevious:aCoroutine];
	[self setNext:aCoroutine];
	
}

- (void)insertLast:(Coroutine *)aCoroutine
{
	if(aCoroutine == self) return;
	
	[aCoroutine remove];
	[aCoroutine setNext:self];
	[aCoroutine setPrevious:previous];	
	[previous setNext:aCoroutine];
	[self setPrevious:aCoroutine];
	
}

- (void)scheduleFirst
{
	[currentCoroutine insertFirst:self];
}

- (void)scheduleLast
{
	[currentCoroutine insertLast:self];
}

- (void)yield
{
	[[currentCoroutine next] resume];
}

- (void)unschedule
{
	[self remove];
}

@end