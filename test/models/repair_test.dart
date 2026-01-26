import 'package:flutter_test/flutter_test.dart';
import 'package:irritrack_mobile/models/repair.dart';

void main() {
  group('Repair Model', () {
    group('Constructor', () {
      test('should create repair with all required fields', () {
        // Arrange & Act
        final repair = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
          notes: 'Replaced damaged heads',
        );

        // Assert
        expect(repair.zoneNumber, 1);
        expect(repair.itemName, '4_inch_head');
        expect(repair.quantity, 5);
        expect(repair.price, 10.0);
        expect(repair.notes, 'Replaced damaged heads');
      });

      test('should create repair with default empty notes', () {
        // Arrange & Act
        final repair = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
        );

        // Assert
        expect(repair.notes, '');
      });

      test('should create repair with zero price', () {
        // Arrange & Act
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'free_item',
          quantity: 10,
          price: 0.0,
        );

        // Assert
        expect(repair.price, 0.0);
        expect(repair.totalCost, 0.0);
      });

      test('should create repair with quantity of 1', () {
        // Arrange & Act
        final repair = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 1,
          price: 10.0,
        );

        // Assert
        expect(repair.quantity, 1);
        expect(repair.totalCost, 10.0);
      });
    });

    group('totalCost Calculation', () {
      test('should calculate total cost correctly', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
        );

        // Act & Assert
        expect(repair.totalCost, 50.0);
      });

      test('should calculate total cost with decimal price', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'valve',
          quantity: 3,
          price: 12.99,
        );

        // Act & Assert
        expect(repair.totalCost, closeTo(38.97, 0.001));
      });

      test('should calculate total cost with zero price', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'free_item',
          quantity: 100,
          price: 0.0,
        );

        // Act & Assert
        expect(repair.totalCost, 0.0);
      });

      test('should calculate total cost with quantity of 1', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'item',
          quantity: 1,
          price: 25.50,
        );

        // Act & Assert
        expect(repair.totalCost, 25.50);
      });

      test('should calculate total cost with large quantity', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'bulk_item',
          quantity: 1000,
          price: 2.50,
        );

        // Act & Assert
        expect(repair.totalCost, 2500.0);
      });

      test('should handle very small prices', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'small_item',
          quantity: 10,
          price: 0.01,
        );

        // Act & Assert
        expect(repair.totalCost, closeTo(0.10, 0.001));
      });
    });

    group('toJson', () {
      test('should serialize repair to JSON correctly', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
          notes: 'Test note',
        );

        // Act
        final json = repair.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['zone_number'], 1);
        expect(json['item_name'], '4_inch_head');
        expect(json['quantity'], 5);
        expect(json['price'], 10.0);
        expect(json['notes'], 'Test note');
      });

      test('should serialize repair with empty notes', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
        );

        // Act
        final json = repair.toJson();

        // Assert
        expect(json['notes'], '');
      });

      test('should serialize repair with special characters', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'valve_1.5_inch_replace',
          quantity: 2,
          price: 25.50,
          notes: "O'Brien's repair #1 (urgent!)",
        );

        // Act
        final json = repair.toJson();

        // Assert
        expect(json['item_name'], 'valve_1.5_inch_replace');
        expect(json['notes'], "O'Brien's repair #1 (urgent!)");
      });

      test('should serialize decimal prices correctly', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'item',
          quantity: 3,
          price: 12.99,
        );

        // Act
        final json = repair.toJson();

        // Assert
        expect(json['price'], 12.99);
      });
    });

    group('fromJson', () {
      test('should deserialize repair from JSON correctly', () {
        // Arrange
        final json = {
          'zone_number': 1,
          'item_name': '4_inch_head',
          'quantity': 5,
          'price': 10.0,
          'notes': 'Test note',
        };

        // Act
        final repair = Repair.fromJson(json);

        // Assert
        expect(repair.zoneNumber, 1);
        expect(repair.itemName, '4_inch_head');
        expect(repair.quantity, 5);
        expect(repair.price, 10.0);
        expect(repair.notes, 'Test note');
      });

      test('should use default values for missing fields', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final repair = Repair.fromJson(json);

        // Assert
        expect(repair.zoneNumber, 0);
        expect(repair.itemName, '');
        expect(repair.quantity, 1);
        expect(repair.price, 0.0);
        expect(repair.notes, '');
      });

      test('should handle null values with defaults', () {
        // Arrange
        final json = {
          'zone_number': null,
          'item_name': null,
          'quantity': null,
          'price': null,
          'notes': null,
        };

        // Act
        final repair = Repair.fromJson(json);

        // Assert
        expect(repair.zoneNumber, 0);
        expect(repair.itemName, '');
        expect(repair.quantity, 1);
        expect(repair.price, 0.0);
        expect(repair.notes, '');
      });

      test('should handle integer price and convert to double', () {
        // Arrange
        final json = {
          'zone_number': 1,
          'item_name': '4_inch_head',
          'quantity': 5,
          'price': 10, // integer instead of double
          'notes': '',
        };

        // Act
        final repair = Repair.fromJson(json);

        // Assert
        expect(repair.price, 10.0);
        expect(repair.price, isA<double>());
      });

      test('should preserve special characters', () {
        // Arrange
        final json = {
          'zone_number': 1,
          'item_name': 'valve_1.5_inch_replace',
          'quantity': 2,
          'price': 25.50,
          'notes': "Special chars: é, ñ, ü, O'Brien & Sons",
        };

        // Act
        final repair = Repair.fromJson(json);

        // Assert
        expect(repair.itemName, 'valve_1.5_inch_replace');
        expect(repair.notes, "Special chars: é, ñ, ü, O'Brien & Sons");
      });
    });

    group('copyWith', () {
      test('should create copy with updated zone number', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
          notes: 'Original note',
        );

        // Act
        final updated = original.copyWith(zoneNumber: 2);

        // Assert
        expect(updated.zoneNumber, 2);
        expect(updated.itemName, original.itemName);
        expect(updated.quantity, original.quantity);
        expect(updated.price, original.price);
        expect(updated.notes, original.notes);
      });

      test('should create copy with updated item name', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
        );

        // Act
        final updated = original.copyWith(itemName: '6_inch_head');

        // Assert
        expect(updated.itemName, '6_inch_head');
        expect(updated.zoneNumber, original.zoneNumber);
      });

      test('should create copy with updated quantity', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
        );

        // Act
        final updated = original.copyWith(quantity: 10);

        // Assert
        expect(updated.quantity, 10);
        expect(updated.totalCost, 100.0); // Recalculated
      });

      test('should create copy with updated price', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
        );

        // Act
        final updated = original.copyWith(price: 15.0);

        // Assert
        expect(updated.price, 15.0);
        expect(updated.totalCost, 75.0); // Recalculated
      });

      test('should create copy with updated notes', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
          notes: 'Old note',
        );

        // Act
        final updated = original.copyWith(notes: 'New note');

        // Assert
        expect(updated.notes, 'New note');
        expect(updated.zoneNumber, original.zoneNumber);
      });

      test('should create copy with multiple updated fields', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
          notes: 'Old',
        );

        // Act
        final updated = original.copyWith(
          zoneNumber: 2,
          quantity: 10,
          price: 12.0,
          notes: 'New',
        );

        // Assert
        expect(updated.zoneNumber, 2);
        expect(updated.quantity, 10);
        expect(updated.price, 12.0);
        expect(updated.notes, 'New');
        expect(updated.totalCost, 120.0);
      });

      test('should not modify original object', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
          notes: 'Original',
        );

        // Act
        final updated = original.copyWith(
          quantity: 10,
          notes: 'Updated',
        );

        // Assert
        expect(original.quantity, 5);
        expect(original.notes, 'Original');
        expect(original.totalCost, 50.0);
        expect(updated.quantity, 10);
        expect(updated.notes, 'Updated');
        expect(updated.totalCost, 100.0);
      });

      test('should create copy with no changes when no parameters provided', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
          notes: 'Note',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.zoneNumber, original.zoneNumber);
        expect(copy.itemName, original.itemName);
        expect(copy.quantity, original.quantity);
        expect(copy.price, original.price);
        expect(copy.notes, original.notes);
      });
    });

    group('Serialization Round-Trip', () {
      test('should maintain data integrity through serialization cycle', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
          notes: 'Test note',
        );

        // Act
        final json = original.toJson();
        final deserialized = Repair.fromJson(json);

        // Assert
        expect(deserialized.zoneNumber, original.zoneNumber);
        expect(deserialized.itemName, original.itemName);
        expect(deserialized.quantity, original.quantity);
        expect(deserialized.price, original.price);
        expect(deserialized.notes, original.notes);
        expect(deserialized.totalCost, original.totalCost);
      });

      test('should handle complex characters through serialization cycle', () {
        // Arrange
        final original = Repair(
          zoneNumber: 1,
          itemName: 'valve_1.5_inch_replace',
          quantity: 3,
          price: 12.99,
          notes: "Complex: é, ñ, ü, O'Brien's & Sons (urgent!) #1",
        );

        // Act
        final json = original.toJson();
        final deserialized = Repair.fromJson(json);

        // Assert
        expect(deserialized.itemName, original.itemName);
        expect(deserialized.notes, original.notes);
        expect(deserialized.price, original.price);
      });
    });

    group('Edge Cases', () {
      test('should handle very long notes', () {
        // Arrange
        final longNotes = 'A' * 1000;
        final repair = Repair(
          zoneNumber: 1,
          itemName: '4_inch_head',
          quantity: 5,
          price: 10.0,
          notes: longNotes,
        );

        // Assert
        expect(repair.notes.length, 1000);
      });

      test('should handle zone number 0', () {
        // Arrange & Act
        final repair = Repair(
          zoneNumber: 0,
          itemName: 'general_item',
          quantity: 1,
          price: 10.0,
        );

        // Assert
        expect(repair.zoneNumber, 0);
      });

      test('should handle very large zone numbers', () {
        // Arrange & Act
        final repair = Repair(
          zoneNumber: 9999,
          itemName: '4_inch_head',
          quantity: 1,
          price: 10.0,
        );

        // Assert
        expect(repair.zoneNumber, 9999);
      });

      test('should handle empty item name', () {
        // Arrange & Act
        final repair = Repair(
          zoneNumber: 1,
          itemName: '',
          quantity: 1,
          price: 10.0,
        );

        // Assert
        expect(repair.itemName, '');
      });

      test('should handle very large quantities', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'bulk_item',
          quantity: 1000000,
          price: 1.0,
        );

        // Assert
        expect(repair.quantity, 1000000);
        expect(repair.totalCost, 1000000.0);
      });

      test('should handle very precise decimal prices', () {
        // Arrange
        final repair = Repair(
          zoneNumber: 1,
          itemName: 'item',
          quantity: 1,
          price: 12.345678,
        );

        // Assert
        expect(repair.price, 12.345678);
        expect(repair.totalCost, 12.345678);
      });
    });
  });
}
