import 'package:flutter_test/flutter_test.dart';
import 'package:irritrack_mobile/models/inspection.dart';
import 'package:irritrack_mobile/models/repair.dart';

void main() {
  group('Inspection Model', () {
    group('Constructor', () {
      test('should create inspection with all required fields', () {
        // Arrange & Act
        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'assigned',
          repairs: [],
          totalCost: 0.0,
        );

        // Assert
        expect(inspection.id, 1);
        expect(inspection.propertyId, 100);
        expect(inspection.technician, 'tech@example.com');
        expect(inspection.date, '2024-01-15');
        expect(inspection.status, 'assigned');
        expect(inspection.repairs, isEmpty);
        expect(inspection.totalCost, 0.0);
      });

      test('should create inspection with repairs', () {
        // Arrange & Act
        final repairs = [
          Repair(
            zoneNumber: 1,
            itemName: '4_inch_head',
            quantity: 5,
            price: 10.0,
          ),
        ];

        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'in_progress',
          repairs: repairs,
          totalCost: 50.0,
        );

        // Assert
        expect(inspection.repairs.length, 1);
        expect(inspection.totalCost, 50.0);
      });
    });

    group('calculateTotalCost', () {
      test('should return 0.0 for inspection with no repairs', () {
        // Arrange
        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'assigned',
          repairs: [],
          totalCost: 0.0,
        );

        // Act
        final cost = inspection.calculateTotalCost();

        // Assert
        expect(cost, 0.0);
      });

      test('should calculate total cost for single repair', () {
        // Arrange
        final repairs = [
          Repair(
            zoneNumber: 1,
            itemName: '4_inch_head',
            quantity: 5,
            price: 10.0,
            notes: '',
          ),
        ];

        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'completed',
          repairs: repairs,
          totalCost: 0.0,
        );

        // Act
        final cost = inspection.calculateTotalCost();

        // Assert
        expect(cost, 50.0); // 5 * 10.0
      });

      test('should calculate total cost for multiple repairs', () {
        // Arrange
        final repairs = [
          Repair(
            zoneNumber: 1,
            itemName: '4_inch_head',
            quantity: 5,
            price: 10.0,
          ),
          Repair(
            zoneNumber: 2,
            itemName: 'rotor',
            quantity: 3,
            price: 15.0,
          ),
          Repair(
            zoneNumber: 3,
            itemName: 'valve_1_inch_repair',
            quantity: 2,
            price: 25.0,
          ),
        ];

        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'completed',
          repairs: repairs,
          totalCost: 0.0,
        );

        // Act
        final cost = inspection.calculateTotalCost();

        // Assert
        // (5 * 10.0) + (3 * 15.0) + (2 * 25.0) = 50 + 45 + 50 = 145.0
        expect(cost, 145.0);
      });

      test('should handle decimal prices correctly', () {
        // Arrange
        final repairs = [
          Repair(
            zoneNumber: 1,
            itemName: 'item1',
            quantity: 3,
            price: 12.99,
          ),
          Repair(
            zoneNumber: 2,
            itemName: 'item2',
            quantity: 2,
            price: 7.50,
          ),
        ];

        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'completed',
          repairs: repairs,
          totalCost: 0.0,
        );

        // Act
        final cost = inspection.calculateTotalCost();

        // Assert
        // (3 * 12.99) + (2 * 7.50) = 38.97 + 15.00 = 53.97
        expect(cost, closeTo(53.97, 0.001));
      });

      test('should handle zero-cost repairs', () {
        // Arrange
        final repairs = [
          Repair(
            zoneNumber: 1,
            itemName: 'free_item',
            quantity: 10,
            price: 0.0,
          ),
          Repair(
            zoneNumber: 2,
            itemName: 'paid_item',
            quantity: 2,
            price: 25.0,
          ),
        ];

        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'completed',
          repairs: repairs,
          totalCost: 0.0,
        );

        // Act
        final cost = inspection.calculateTotalCost();

        // Assert
        expect(cost, 50.0); // Only the paid item counts
      });

      test('should handle large quantities', () {
        // Arrange
        final repairs = [
          Repair(
            zoneNumber: 1,
            itemName: 'bulk_item',
            quantity: 1000,
            price: 2.50,
          ),
        ];

        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'completed',
          repairs: repairs,
          totalCost: 0.0,
        );

        // Act
        final cost = inspection.calculateTotalCost();

        // Assert
        expect(cost, 2500.0);
      });
    });

    group('toJson', () {
      test('should serialize inspection to JSON correctly', () {
        // Arrange
        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'completed',
          repairs: [],
          totalCost: 150.0,
        );

        // Act
        final json = inspection.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['property_id'], 100);
        expect(json['technician'], 'tech@example.com');
        expect(json['date'], '2024-01-15');
        expect(json['status'], 'completed');
        expect(json['repairs'], isA<List>());
        expect(json['total_cost'], 150.0);
        expect(json.containsKey('id'), false); // ID is stored as key
      });

      test('should serialize inspection with repairs', () {
        // Arrange
        final repairs = [
          Repair(
            zoneNumber: 1,
            itemName: '4_inch_head',
            quantity: 5,
            price: 10.0,
            notes: 'Test note',
          ),
        ];

        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'completed',
          repairs: repairs,
          totalCost: 50.0,
        );

        // Act
        final json = inspection.toJson();

        // Assert
        expect(json['repairs'], isA<List>());
        expect(json['repairs'].length, 1);
        expect(json['repairs'][0]['zone_number'], 1);
        expect(json['repairs'][0]['item_name'], '4_inch_head');
        expect(json['repairs'][0]['quantity'], 5);
        expect(json['repairs'][0]['price'], 10.0);
      });
    });

    group('fromJson', () {
      test('should deserialize inspection from JSON correctly', () {
        // Arrange
        final json = {
          'property_id': 100,
          'technician': 'tech@example.com',
          'date': '2024-01-15',
          'status': 'completed',
          'repairs': [],
          'total_cost': 150.0,
        };

        // Act
        final inspection = Inspection.fromJson(1, json);

        // Assert
        expect(inspection.id, 1);
        expect(inspection.propertyId, 100);
        expect(inspection.technician, 'tech@example.com');
        expect(inspection.date, '2024-01-15');
        expect(inspection.status, 'completed');
        expect(inspection.repairs, isEmpty);
        expect(inspection.totalCost, 150.0);
      });

      test('should deserialize inspection with repairs', () {
        // Arrange
        final json = {
          'property_id': 100,
          'technician': 'tech@example.com',
          'date': '2024-01-15',
          'status': 'completed',
          'repairs': [
            {
              'zone_number': 1,
              'item_name': '4_inch_head',
              'quantity': 5,
              'price': 10.0,
              'notes': 'Test note',
            },
          ],
          'total_cost': 50.0,
        };

        // Act
        final inspection = Inspection.fromJson(1, json);

        // Assert
        expect(inspection.repairs.length, 1);
        expect(inspection.repairs[0].zoneNumber, 1);
        expect(inspection.repairs[0].itemName, '4_inch_head');
        expect(inspection.repairs[0].quantity, 5);
        expect(inspection.repairs[0].price, 10.0);
      });

      test('should use default values for missing fields', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final inspection = Inspection.fromJson(1, json);

        // Assert
        expect(inspection.id, 1);
        expect(inspection.propertyId, 0);
        expect(inspection.technician, '');
        expect(inspection.date, '');
        expect(inspection.status, 'assigned');
        expect(inspection.repairs, isEmpty);
        expect(inspection.totalCost, 0.0);
      });

      test('should handle null repairs list', () {
        // Arrange
        final json = {
          'property_id': 100,
          'technician': 'tech@example.com',
          'date': '2024-01-15',
          'status': 'assigned',
          'repairs': null,
          'total_cost': 0.0,
        };

        // Act
        final inspection = Inspection.fromJson(1, json);

        // Assert
        expect(inspection.repairs, isEmpty);
      });
    });

    group('copyWith', () {
      test('should create copy with updated status', () {
        // Arrange
        final original = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'assigned',
          repairs: [],
          totalCost: 0.0,
        );

        // Act
        final updated = original.copyWith(status: 'completed');

        // Assert
        expect(updated.status, 'completed');
        expect(updated.id, original.id);
        expect(updated.propertyId, original.propertyId);
      });

      test('should create copy with updated repairs and totalCost', () {
        // Arrange
        final original = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'in_progress',
          repairs: [],
          totalCost: 0.0,
        );

        final newRepairs = [
          Repair(
            zoneNumber: 1,
            itemName: '4_inch_head',
            quantity: 5,
            price: 10.0,
          ),
        ];

        // Act
        final updated = original.copyWith(
          repairs: newRepairs,
          totalCost: 50.0,
        );

        // Assert
        expect(updated.repairs.length, 1);
        expect(updated.totalCost, 50.0);
        expect(original.repairs, isEmpty); // Original unchanged
      });

      test('should create copy with multiple updated fields', () {
        // Arrange
        final original = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech1@example.com',
          date: '2024-01-15',
          status: 'assigned',
          repairs: [],
          totalCost: 0.0,
        );

        // Act
        final updated = original.copyWith(
          technician: 'tech2@example.com',
          status: 'in_progress',
          date: '2024-01-16',
        );

        // Assert
        expect(updated.technician, 'tech2@example.com');
        expect(updated.status, 'in_progress');
        expect(updated.date, '2024-01-16');
      });

      test('should not modify original object', () {
        // Arrange
        final original = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'assigned',
          repairs: [],
          totalCost: 0.0,
        );

        // Act
        final updated = original.copyWith(status: 'completed');

        // Assert
        expect(original.status, 'assigned');
        expect(updated.status, 'completed');
      });
    });

    group('Status Values', () {
      test('should handle assigned status', () {
        // Arrange & Act
        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'assigned',
          repairs: [],
          totalCost: 0.0,
        );

        // Assert
        expect(inspection.status, 'assigned');
      });

      test('should handle in_progress status', () {
        // Arrange & Act
        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'in_progress',
          repairs: [],
          totalCost: 0.0,
        );

        // Assert
        expect(inspection.status, 'in_progress');
      });

      test('should handle completed status', () {
        // Arrange & Act
        final inspection = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'completed',
          repairs: [],
          totalCost: 0.0,
        );

        // Assert
        expect(inspection.status, 'completed');
      });
    });

    group('Serialization Round-Trip', () {
      test('should maintain data integrity through serialization cycle', () {
        // Arrange
        final original = Inspection(
          id: 1,
          propertyId: 100,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'completed',
          repairs: [
            Repair(
              zoneNumber: 1,
              itemName: '4_inch_head',
              quantity: 5,
              price: 10.0,
              notes: 'Replaced damaged heads',
            ),
          ],
          totalCost: 50.0,
        );

        // Act
        final json = original.toJson();
        final deserialized = Inspection.fromJson(1, json);

        // Assert
        expect(deserialized.id, original.id);
        expect(deserialized.propertyId, original.propertyId);
        expect(deserialized.technician, original.technician);
        expect(deserialized.date, original.date);
        expect(deserialized.status, original.status);
        expect(deserialized.repairs.length, original.repairs.length);
        expect(deserialized.totalCost, original.totalCost);
      });
    });
  });
}
