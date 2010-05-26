//
//  MKStoreObserver.m
//
//  Created by Mugunth Kumar on 17-Oct-09.
//  Copyright 2009 Mugunth Kumar. All rights reserved.
//

#import "MKStoreObserver.h"
#import "MKStoreManager.h"
#import "AlienBlueAppDelegate.h"

@implementation MKStoreObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	NSLog(@"paymentQueue in()");		
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				
                [self completeTransaction:transaction];
				
                break;
				
            case SKPaymentTransactionStateFailed:
				
                [self failedTransaction:transaction];
				
                break;
				
            case SKPaymentTransactionStateRestored:
				
                [self restoreTransaction:transaction];
				
            default:
				
                break;
		}			
	}
}

- (void) upgradeError
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to complete your purchase" message:@"Please check your connection and iTunes username and password before trying again."
												   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert setTag:55];
	[alert show];
	[alert release];
	[(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] stopPurchaseIndicator];
}


- (void) failedTransaction: (SKPaymentTransaction *)transaction
{	
	NSLog(@"failedTransaction in()");
    if (transaction.error.code != SKErrorPaymentCancelled)		
    {		

		if (transaction.error.code == SKErrorClientInvalid)
			NSLog(@"client invalid");			
		else if (transaction.error.code == SKErrorPaymentCancelled)
			NSLog(@"payment cancelled");			
		else if (transaction.error.code == SKErrorPaymentInvalid)
			NSLog(@"payment invalid");			
		else if (transaction.error.code == SKErrorPaymentNotAllowed)
			NSLog(@"payment not allowed");				
		else if (transaction.error.code == SKErrorUnknown)
			NSLog(@"unknown error");		
        // Optionally, display an error here.		
    }	
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];	
	[self upgradeError];
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{		
	NSLog(@"completeTransaction in()");
    [[MKStoreManager sharedManager] provideContent: transaction.payment.productIdentifier shouldSerialize:YES];	
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];	
	[(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] proVersionUpgraded];

}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{	
	NSLog(@"restoreTransaction in()");	
    [[MKStoreManager sharedManager] provideContent: transaction.originalTransaction.payment.productIdentifier shouldSerialize:YES];	
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];	
}

@end
