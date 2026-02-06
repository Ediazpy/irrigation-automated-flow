import 'package:flutter_test/flutter_test.dart';
import 'package:irritrack_mobile/models/property.dart';
import 'package:irritrack_mobile/models/zone.dart';

void main() {
  group('Property Model', () {
    group('Constructor', () {
      test('should create property with all required fields', () {
        // Arrange & Act
        final property = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [],
        );

        // Assert
        expect(property.id, 1);
        expect(property.address, '123 Main St');
        expect(property.meterLocation, 'Front yard');
        expect(property.backflowLocation, 'Side yard');
        expect(property.backflowSize, '3/4"');
        expect(property.backflowSerial, 'BF12345');
        expect(property.numControllers, 2);
        expect(property.controllerLocation, 'Garage');
        expect(property.zones, isEmpty);
      });

      test('should create property with zones', () {
        // Arrange & Act
        final zones = [
          Zone(
            zoneNumber: 1,
            description: 'Front lawn',
            headType: 'spray',
            headCount: 10,
          ),
          Zone(
            zoneNumber: 2,
            description: 'Back lawn',
            headType: 'rotor',
            headCount: 8,
          ),
        ];

        final property = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: zones,
        );

        // Assert
        expect(property.zones.length, 2);
        expect(property.zones[0].zoneNumber, 1);
        expect(property.zones[1].zoneNumber, 2);
      });

      test('should create property with zero controllers', () {
        // Arrange & Act
        final property = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 0,
          controllerLocation: 'N/A',
          zones: [],
        );

        // Assert
        expect(property.numControllers, 0);
      });
    });

    group('toJson', () {
      test('should serialize property to JSON correctly', () {
        // Arrange
        final property = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [],
        );

        // Act
        final json = property.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['address'], '123 Main St');
        expect(json['meter_location'], 'Front yard');
        expect(json['backflow_location'], 'Side yard');
        expect(json['backflow_size'], '3/4"');
        expect(json['backflow_serial'], 'BF12345');
        expect(json['num_controllers'], 2);
        expect(json['controller_location'], 'Garage');
        expect(json['zones'], isA<List>());
        expect(json.containsKey('id'), false); // ID is stored as key
      });

      test('should serialize property with zones to JSON', () {
        // Arrange
        final zones = [
          Zone(
            zoneNumber: 1,
            description: 'Front lawn',
            headType: 'spray',
            headCount: 10,
          ),
        ];

        final property = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 1,
          controllerLocation: 'Garage',
          zones: zones,
        );

        // Act
        final json = property.toJson();

        // Assert
        expect(json['zones'], isA<List>());
        expect(json['zones'].length, 1);
        expect(json['zones'][0]['zone_number'], 1);
        expect(json['zones'][0]['description'], 'Front lawn');
      });

      test('should handle special characters in address', () {
        // Arrange
        final property = Property(
          id: 1,
          address: "123 O'Brien St. Apt #5",
          meterLocation: 'Front & Side',
          backflowLocation: 'Back (near fence)',
          backflowSize: '1"',
          backflowSerial: 'BF-2024-001',
          numControllers: 1,
          controllerLocation: 'Garage/Storage',
          zones: [],
        );

        // Act
        final json = property.toJson();

        // Assert
        expect(json['address'], "123 O'Brien St. Apt #5");
        expect(json['meter_location'], 'Front & Side');
        expect(json['backflow_location'], 'Back (near fence)');
      });
    });

    group('fromJson', () {
      test('should deserialize property from JSON correctly', () {
        // Arrange
        final json = {
          'address': '123 Main St',
          'meter_location': 'Front yard',
          'backflow_location': 'Side yard',
          'backflow_size': '3/4"',
          'backflow_serial': 'BF12345',
          'num_controllers': 2,
          'controller_location': 'Garage',
          'zones': [],
        };

        // Act
        final property = Property.fromJson(1, json);

        // Assert
        expect(property.id, 1);
        expect(property.address, '123 Main St');
        expect(property.meterLocation, 'Front yard');
        expect(property.backflowLocation, 'Side yard');
        expect(property.backflowSize, '3/4"');
        expect(property.backflowSerial, 'BF12345');
        expect(property.numControllers, 2);
        expect(property.controllerLocation, 'Garage');
        expect(property.zones, isEmpty);
      });

      test('should deserialize property with zones from JSON', () {
        // Arrange
        final json = {
          'address': '123 Main St',
          'meter_location': 'Front yard',
          'backflow_location': 'Side yard',
          'backflow_size': '3/4"',
          'backflow_serial': 'BF12345',
          'num_controllers': 1,
          'controller_location': 'Garage',
          'zones': [
            {
              'zone_number': 1,
              'description': 'Front lawn',
              'head_type': 'spray',
              'head_count': 10,
            },
          ],
        };

        // Act
        final property = Property.fromJson(1, json);

        // Assert
        expect(property.zones.length, 1);
        expect(property.zones[0].zoneNumber, 1);
        expect(property.zones[0].description, 'Front lawn');
      });

      test('should use default values for missing fields', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final property = Property.fromJson(1, json);

        // Assert
        expect(property.id, 1);
        expect(property.address, '');
        expect(property.meterLocation, '');
        expect(property.backflowLocation, '');
        expect(property.backflowSize, '');
        expect(property.backflowSerial, '');
        expect(property.numControllers, 0);
        expect(property.controllerLocation, '');
        expect(property.zones, isEmpty);
      });

      test('should handle null zones list', () {
        // Arrange
        final json = {
          'address': '123 Main St',
          'meter_location': 'Front yard',
          'backflow_location': 'Side yard',
          'backflow_size': '3/4"',
          'backflow_serial': 'BF12345',
          'num_controllers': 2,
          'controller_location': 'Garage',
          'zones': null,
        };

        // Act
        final property = Property.fromJson(1, json);

        // Assert
        expect(property.zones, isEmpty);
      });

      test('should handle null values with defaults', () {
        // Arrange
        final json = {
          'address': null,
          'meter_location': null,
          'backflow_location': null,
          'backflow_size': null,
          'backflow_serial': null,
          'num_controllers': null,
          'controller_location': null,
          'zones': null,
        };

        // Act
        final property = Property.fromJson(1, json);

        // Assert
        expect(property.address, '');
        expect(property.meterLocation, '');
        expect(property.backflowLocation, '');
        expect(property.backflowSize, '');
        expect(property.backflowSerial, '');
        expect(property.numControllers, 0);
        expect(property.controllerLocation, '');
        expect(property.zones, isEmpty);
      });
    });

    group('copyWith', () {
      test('should create copy with updated address', () {
        // Arrange
        final original = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [],
        );

        // Act
        final updated = original.copyWith(address: '456 Oak Ave');

        // Assert
        expect(updated.address, '456 Oak Ave');
        expect(updated.id, original.id);
        expect(updated.meterLocation, original.meterLocation);
      });

      test('should create copy with updated zones', () {
        // Arrange
        final original = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [],
        );

        final newZones = [
          Zone(
            zoneNumber: 1,
            description: 'New zone',
            headType: 'spray',
            headCount: 5,
          ),
        ];

        // Act
        final updated = original.copyWith(zones: newZones);

        // Assert
        expect(updated.zones.length, 1);
        expect(updated.zones[0].description, 'New zone');
        expect(original.zones, isEmpty); // Original unchanged
      });

      test('should create copy with multiple updated fields', () {
        // Arrange
        final original = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [],
        );

        // Act
        final updated = original.copyWith(
          address: '456 Oak Ave',
          numControllers: 3,
          backflowSize: '1"',
        );

        // Assert
        expect(updated.address, '456 Oak Ave');
        expect(updated.numControllers, 3);
        expect(updated.backflowSize, '1"');
        expect(updated.meterLocation, original.meterLocation);
      });

      test('should create copy with updated ID', () {
        // Arrange
        final original = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [],
        );

        // Act
        final updated = original.copyWith(id: 100);

        // Assert
        expect(updated.id, 100);
        expect(updated.address, original.address);
      });

      test('should not modify original object', () {
        // Arrange
        final original = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [],
        );

        // Act
        final updated = original.copyWith(address: '456 Oak Ave');

        // Assert
        expect(original.address, '123 Main St');
        expect(updated.address, '456 Oak Ave');
      });

      test('should create copy with no changes when no parameters provided', () {
        // Arrange
        final original = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [],
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.address, original.address);
        expect(copy.meterLocation, original.meterLocation);
        expect(copy.numControllers, original.numControllers);
      });
    });

    group('Serialization Round-Trip', () {
      test('should maintain data integrity through serialization cycle', () {
        // Arrange
        final original = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [
            Zone(
              zoneNumber: 1,
              description: 'Front lawn',
              headType: 'spray',
              headCount: 10,
            ),
          ],
        );

        // Act
        final json = original.toJson();
        final deserialized = Property.fromJson(1, json);

        // Assert
        expect(deserialized.id, original.id);
        expect(deserialized.address, original.address);
        expect(deserialized.meterLocation, original.meterLocation);
        expect(deserialized.backflowLocation, original.backflowLocation);
        expect(deserialized.backflowSize, original.backflowSize);
        expect(deserialized.backflowSerial, original.backflowSerial);
        expect(deserialized.numControllers, original.numControllers);
        expect(deserialized.controllerLocation, original.controllerLocation);
        expect(deserialized.zones.length, original.zones.length);
      });

      test('should handle complex characters through serialization cycle', () {
        // Arrange
        final original = Property(
          id: 1,
          address: "O'Malley's Property #123-A",
          meterLocation: 'Front & center',
          backflowLocation: 'Side (near tree)',
          backflowSize: '1-1/4"',
          backflowSerial: 'BF-2024/001',
          numControllers: 2,
          controllerLocation: 'Garage/Storage area',
          zones: [],
        );

        // Act
        final json = original.toJson();
        final deserialized = Property.fromJson(1, json);

        // Assert
        expect(deserialized.address, original.address);
        expect(deserialized.meterLocation, original.meterLocation);
        expect(deserialized.backflowLocation, original.backflowLocation);
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings', () {
        // Arrange & Act
        final property = Property(
          id: 1,
          address: '',
          meterLocation: '',
          backflowLocation: '',
          backflowSize: '',
          backflowSerial: '',
          numControllers: 0,
          controllerLocation: '',
          zones: [],
        );

        // Assert
        expect(property.address, '');
        expect(property.meterLocation, '');
      });

      test('should handle large number of zones', () {
        // Arrange
        final zones = List.generate(
          50,
          (i) => Zone(
            zoneNumber: i + 1,
            description: 'Zone ${i + 1}',
            headType: 'spray',
            headCount: 10,
          ),
        );

        final property = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 5,
          controllerLocation: 'Garage',
          zones: zones,
        );

        // Assert
        expect(property.zones.length, 50);
        expect(property.zones.first.zoneNumber, 1);
        expect(property.zones.last.zoneNumber, 50);
      });

      test('should handle very long address', () {
        // Arrange
        final longAddress = 'A' * 500;
        final property = Property(
          id: 1,
          address: longAddress,
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowSize: '3/4"',
          backflowSerial: 'BF12345',
          numControllers: 2,
          controllerLocation: 'Garage',
          zones: [],
        );

        // Assert
        expect(property.address.length, 500);
      });
    });
  });
}
