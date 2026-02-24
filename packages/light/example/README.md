# Light Plugin Example

Demonstrates how to use the `light` plugin.

## iOS signing and entitlement notes

The iOS example is configured with:

- iOS deployment target `14.0`
- `Runner/Runner.entitlements` containing:
  - `com.apple.developer.sensorkit.reader.allow = [ambient-light-sensor]`

To run on a physical iPhone, open `example/ios/Runner.xcworkspace` in Xcode and:

1. Select your Apple Developer Team under Signing.
2. Keep Signing set to Automatic.
3. Use a unique bundle identifier.
4. Ensure your provisioning profile has Apple-approved SensorKit access for `ambient-light-sensor`.

Certificates/profiles are Apple-account specific and are not stored in this repository.
