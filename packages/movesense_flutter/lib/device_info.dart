part of 'movesense_flutter.dart';

/// Device info returned from the Movesense `/Info` endpoint.
class MovesenseDeviceInfo {
  final String manufacturerName;
  final String? brandName;
  final String productName;
  final String variant;
  final String design;
  final String hwCompatibilityId;
  final String serial;
  final String pcbaSerial;
  final String sw;
  final String hw;
  final String? additionalVersionInfo;
  final List<MovesenseAddressInfo> addressInfo;
  final String apiLevel;

  const MovesenseDeviceInfo({
    required this.manufacturerName,
    required this.brandName,
    required this.productName,
    required this.variant,
    required this.design,
    required this.hwCompatibilityId,
    required this.serial,
    required this.pcbaSerial,
    required this.sw,
    required this.hw,
    required this.additionalVersionInfo,
    required this.addressInfo,
    required this.apiLevel,
  });

  /// Build from the raw JSON string returned by the device.
  factory MovesenseDeviceInfo.fromJsonString(String jsonString) {
    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Device info JSON must be an object');
    }
    final dynamic content = decoded['Content'];
    if (content is! Map<String, dynamic>) {
      throw const FormatException('Device info JSON missing Content object');
    }
    return MovesenseDeviceInfo.fromMap(content);
  }

  /// Build from a JSON map.
  factory MovesenseDeviceInfo.fromMap(Map<String, dynamic> map) {
    final dynamic addresses = map['addressInfo'];
    if (addresses is! List) {
      throw const FormatException('Device info missing addressInfo list');
    }

    return MovesenseDeviceInfo(
      manufacturerName: map['manufacturerName'] as String? ?? '',
      brandName: map['brandName'] as String?,
      productName: map['productName'] as String? ?? '',
      variant: map['variant'] as String? ?? '',
      design: map['design'] as String? ?? '',
      hwCompatibilityId: map['hwCompatibilityId'] as String? ?? '',
      serial: map['serial'] as String? ?? '',
      pcbaSerial: map['pcbaSerial'] as String? ?? '',
      sw: map['sw'] as String? ?? '',
      hw: map['hw'] as String? ?? '',
      additionalVersionInfo: map['additionalVersionInfo'] as String?,
      addressInfo: addresses
          .map(
            (entry) => MovesenseAddressInfo.fromMap(
              entry is Map<String, dynamic> ? entry : <String, dynamic>{},
            ),
          )
          .toList(growable: false),
      apiLevel: map['apiLevel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'manufacturerName': manufacturerName,
    'brandName': brandName,
    'productName': productName,
    'variant': variant,
    'design': design,
    'hwCompatibilityId': hwCompatibilityId,
    'serial': serial,
    'pcbaSerial': pcbaSerial,
    'sw': sw,
    'hw': hw,
    'additionalVersionInfo': additionalVersionInfo,
    'addressInfo': addressInfo.map((a) => a.toMap()).toList(growable: false),
    'apiLevel': apiLevel,
  };

  /// Serialize to JSON string with the original Content wrapper.
  String toJsonString() => json.encode(<String, dynamic>{'Content': toMap()});
}

/// Address info entry in the Movesense device info.
class MovesenseAddressInfo {
  final String name;
  final String address;

  const MovesenseAddressInfo({required this.name, required this.address});

  factory MovesenseAddressInfo.fromMap(Map<String, dynamic> map) {
    return MovesenseAddressInfo(
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'address': address,
  };
}
