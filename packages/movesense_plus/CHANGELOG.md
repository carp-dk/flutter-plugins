## 1.2.1

* update of example app to run on iOS incl. docs

## 1.2.0

* connect and disconnect method not async
* update to docs

## 1.1.1

Update of docs to highlight that the `address` format is platform dependent:

* on Android, the address is the Bluetooth MAC address (e.g. `0C:8C:DC:1B:23:BF`).
* on iOS, the address is the UUID of the device (e.g. `00000000-0000-0000-0000-000000000000`).

## 1.1.0

Added R-R interval to HR reading

## 1.0.0

Initial release supporting:

* scan for Movesense devices (and stop scanning again)
* connect and disconnect to a device
* get device and state information
* get a stream of the following data from a device:
  * heart rate
  * ECG
  * IMU
  * temperature
  * state events (movement, battery, connectors, double tap, tap, free fall)
