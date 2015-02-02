# FPPowerUp
FPPowerUp - simple Objective-C library, providing control for [PowerUp 3.0](http://www.poweruptoys.com) paperplane controller.

Supported platforms: OS X (10.7+) and iOS (5.0+)

#Current status
**Done:**

* Connection to PowerUp
* Controlling Speed
* Controlling Rudder

**TODO:**

* Battery Status
* Replace deprecated CoreBluetooth APIs
* Specify services UUIDs

#Usage

```objc
- (void)viewDidLoad {     
    [super viewDidLoad];     
    _powerUp = [FPPowerUp new];     
    _powerUp.delegate = self;      
}

- (IBAction)connect:(id)sender {
     [_powerUp connect]; 
}

- (void)powerUpDidConnect:(FPPowerUp *) powerUp {     
	_powerUp.speed = 200;   //Accepting values between [0 ... 254]
	_powerUp.rudder = 100;  //Accepting values between [-128 ... 127]
 }
```
