//
// Created by Filipp Panfilov on 02/02/15.
// Copyright (c) 2015 Corso Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FPPowerUp;

typedef NS_ENUM(NSInteger, PowerUpConnectionState){
    PowerUpConnectionState_Disconnected,
    PowerUpConnectionState_Scanning,
    PowerUpConnectionState_Connecting,
    PowerUpConnectionState_DiscoveringServices,
    PowerUpConnectionState_Connected,
    PowerUpConnectionState_ConnectionFailed
};

@protocol FPPowerUpDelegate <NSObject>

@optional
- (void)powerUp:(FPPowerUp *)powerUp didChangeState:(PowerUpConnectionState)newState;
- (void)powerUpDidConnect:(FPPowerUp *)powerUp;
- (void)powerUp:(FPPowerUp *)powerUp didDisconnectWithError:(NSError *)error;
- (void)powerUp:(FPPowerUp *)powerUp didFailToConnectWithError:(NSError *)error;
@end

@interface FPPowerUp : NSObject

@property (nonatomic, readonly, assign) PowerUpConnectionState state;
@property (nonatomic, strong) id<FPPowerUpDelegate> delegate;
@property (nonatomic, assign) NSUInteger speed;
@property (nonatomic, assign) NSInteger rudder;

- (void)connect;


@end