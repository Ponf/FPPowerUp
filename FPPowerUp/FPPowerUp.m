//
// Created by Filipp Panfilov on 02/02/15.
// Copyright (c) 2015 Corso Software. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "FPPowerUp.h"


NSString *const kPowerUpControlServiceUUID = @"86C3810E-F171-40D9-A117-26B300768CD6";
NSString *const kPowerUpRudderCharacteristicUUID = @"86C3810E-0021-40D9-A117-26B300768CD6";
NSString *const kPowerUpSpeedCharacteristicUUID = @"86C3810E-0010-40D9-A117-26B300768CD6";
NSString *const kPowerUpChargerCharacteristicUUID = @"86C3810E-0040-40D9-A117-26B300768CD6";

NSString *const kPowerUpBatteryServiceUUID = @"180F";
NSString *const kPowerUpBatteryLevelCharacteristicUUID = @"2A19";

NSString *const kPowerUpDeviceInformationService = @"180A";


@interface FPPowerUp () <CBCentralManagerDelegate, CBPeripheralDelegate>
@end

@implementation FPPowerUp {
    CBCentralManager *_centralManager;
    CBPeripheral *_peripheral;

    CBCharacteristic *_speedCharacteristic;
    CBCharacteristic *_rudderCharacteristic;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //TODO: move to another dispatch queue?
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _state = PowerUpConnectionState_Disconnected;
    }

    return self;
}

#pragma mark -- Public
- (void)connect {
    if ([self isLECapableHardware]) {
        [self discoverPlane];
    }
}

- (void)setSpeed:(NSUInteger)speed {
    BOOL correctValue = (speed >= 0) && (speed <= 254);
    NSCAssert(correctValue, @"Speed value must be in [0 ... 254] range");
    if (!correctValue)
        return;

    _speed = speed;
    int8_t val = (int8_t) speed;
    NSData* valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
    if (_state == PowerUpConnectionState_Connected) {
        [_peripheral writeValue:valData forCharacteristic:_speedCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (void)setRudder:(NSInteger)rudder {
    BOOL correctValue = (rudder >= -128) && (rudder <= 127);
    NSCAssert(correctValue, @"Rudder value must be in [-128 ... 127] range");
    if (!correctValue)
        return;

    _rudder = rudder;
    int8_t val = (int8_t) rudder;
    NSData* valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
    if (_state == PowerUpConnectionState_Connected) {
        [_peripheral writeValue:valData forCharacteristic:_rudderCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}


#pragma mark -- CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

}


- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    [_centralManager retrievePeripheralsWithIdentifiers:@[(id) aPeripheral.UUID]];
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    [_centralManager stopScan];
    [self setState:PowerUpConnectionState_Connecting];
    _peripheral = [peripherals firstObject];
    [_centralManager connectPeripheral:_peripheral
                               options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey : @(YES)}];
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral {
    [self setState:PowerUpConnectionState_DiscoveringServices];
    [aPeripheral setDelegate:self];
    //TODO: specify services
    [aPeripheral discoverServices:nil];

}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    peripheral.delegate = nil;
    [self setState:PowerUpConnectionState_Disconnected];
    if ([_delegate respondsToSelector:@selector(powerUp:didDisconnectWithError:)]) {
        [_delegate powerUp:self didDisconnectWithError:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error {
    [self setState:PowerUpConnectionState_ConnectionFailed];
    if ([_delegate respondsToSelector:@selector(powerUp:didFailToConnectWithError:)]){
        [_delegate powerUp:self didFailToConnectWithError:error];
    }
}


#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *aService in peripheral.services) {
        /* Control Services */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:kPowerUpControlServiceUUID]]) {
            //TODO: specify characteristics
            [peripheral discoverCharacteristics:nil forService:aService];
        }

        /* Battery Services */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:kPowerUpBatteryServiceUUID]]) {
            //TODO: specify characteristics
            [peripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kPowerUpControlServiceUUID]]) {
        for (CBCharacteristic *aChar in service.characteristics) {

            //Speed Characteristic
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:kPowerUpSpeedCharacteristicUUID]]) {
                [_peripheral setNotifyValue:NO forCharacteristic:aChar];
                _speedCharacteristic = aChar;
            }
            //Rudder Characteristic
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:kPowerUpRudderCharacteristicUUID]]) {
                [_peripheral setNotifyValue:NO forCharacteristic:aChar];
                _rudderCharacteristic = aChar;
            }

            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:kPowerUpChargerCharacteristicUUID]]) {
                //TODO: implement charging indication
            }
        }
        [self setState:PowerUpConnectionState_Connected];
        if ([_delegate respondsToSelector:@selector(powerUpDidConnect:)]) {
            [_delegate powerUpDidConnect:self];
        }
    }

    if ([service.UUID isEqual:[CBUUID UUIDWithString:kPowerUpBatteryServiceUUID]]) {
        for (CBCharacteristic *aChar in service.characteristics) {
            //Battery Level
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:kPowerUpBatteryLevelCharacteristicUUID]]) {
                [_peripheral setNotifyValue:YES forCharacteristic:aChar];
            }
        }
    }

    //TODO: implement device info service
}

- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kPowerUpBatteryLevelCharacteristicUUID]]) {
        if (characteristic.value) {
            //TODO: implement battery level
        }
    }

    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kPowerUpChargerCharacteristicUUID]]) {
        if (characteristic.value) {
            //TODO: implement battery level
        }
    }
}


#pragma mark -- Private
- (BOOL) isLECapableHardware {
    NSString * state = nil;

    switch ([_centralManager state]) {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return YES;
        case CBCentralManagerStateUnknown:
        default:
            return NO;
    }

    NSLog(@"Central manager state: %@", state);
    return NO;
}

- (void)discoverPlane {
    [_centralManager stopScan];
    [self setState:PowerUpConnectionState_Scanning];
    //TODO: specify UUIDs?
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kPowerUpControlServiceUUID]] options:nil];
}

- (void)setState:(PowerUpConnectionState)state {
    _state = state;
    if ([_delegate respondsToSelector:@selector(powerUp:didChangeState:)]){
        [_delegate powerUp:self didChangeState:_state];
    }
}


@end