SpeechBlinker
=============

![screenshot](/screenshots/SpeechBlinker.PNG)

A small iOS app that uses Open Ears to manipulate UI elements and an Arduino over BLE.

To get started, try saying 'Connect' or 'Red On'. This should connect to an Arduino with a BLE shield and [this sketch](http://github.com/daveecker/BluetoothLights) or turn the LED indicator on at the top of the screen. Other available commands include:
* 'Lights on'
* 'Lights off'
* 'Toggle flashlight'
* 'Blue on/off'
* 'Green on/off'

Note that this project requires the OpenEars framework, SLT voice framework, and the English accoustical model. These files can be found at [Politepix.com](http://www.politepix.com/openears/).
