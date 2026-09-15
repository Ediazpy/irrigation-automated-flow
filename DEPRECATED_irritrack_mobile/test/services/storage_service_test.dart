import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:irritrack_mobile/services/storage_service.dart';
import 'package:irritrack_mobile/models/user.dart';
import 'package:irritrack_mobile/models/property.dart';
import 'package:irritrack_mobile/models/inspection.dart';
import 'package:irritrack_mobile/models/repair_item.dart';
import 'package:irritrack_mobile/models/repair.dart';
import 'package:irritrack_mobile/models/zone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    late StorageService storage;

    setUp(() {
      storage = StorageService();
    });

    group('Initialization', () {
      test('should initialize with default admin user', () {
        // Assert
        expect(storage.users.containsKey('admin@thriveoutdoor.com'), true);
        final admin = storage.users['admin@thriveoutdoor.com']!;
        expect(admin.email, 'admin@thriveoutdoor.com');
        expect(admin.password, 'temp1234');
        expect(admin.role, 'manager');
        expect(admin.name, 'Admin');
      });

      test('should initialize with predefined repair items', () {
        // Assert
        expect(storage.repairItems.isNotEmpty, true);
        expect(storage.repairItems.length, greaterThan(30));

        // Check specific items exist
        expect(storage.repairItems.containsKey('4_inch_head'), true);
        expect(storage.repairItems.containsKey('rotor'), true);
        expect(storage.repairItems.containsKey('valve_1_inch_repair'), true);
        expect(storage.repairItems.containsKey('controller_replacement'), true);
        expect(storage.repairItems.containsKey('winterize_system'), true);
      });

      test('should initialize with empty properties map', () {
        // Assert
        expect(storage.properties, isEmpty);
      });

      test('should initialize with empty inspections map', () {
        // Assert
        expect(storage.inspections, isEmpty);
      });

      test('should initialize ID counters to 1', () {
        // Assert
        expect(storage.nextPropertyId, 1);
        expect(storage.nextInspectionId, 1);
      });

      test('should initialize with empty failed attempts', () {
        // Assert
        expect(storage.failedAttempts, isEmpty);
      });
    });

    group('Repair Items', () {
      test('should have correct repair item structure', () {
        // Arrange
        final item = storage.repairItems['4_inch_head']!;

        // Assert
        expect(item.name, '4_inch_head');
        expect(item.price, 0.00);
        expect(item.category, 'heads');
        expect(item.requiresNotes, false);
      });

      test('should have items with notes requirement', () {
        // Assert
        final controllerItem = storage.repairItems['controller_replacement']!;
        expect(controllerItem.requiresNotes, true);

        final wireItem = storage.repairItems['wire_repair_manual']!;
        expect(wireItem.requiresNotes, true);
      });

      test('should organize items into correct categories', () {
        // Assert
        expect(storage.repairItems['4_inch_head']!.category, 'heads');
        expect(storage.repairItems['4_inch_stem']!.category, 'stems');
        expect(storage.repairItems['fixed_nozzle']!.category, 'nozzles');
        expect(storage.repairItems['drip_break']!.category, 'drip');
        expect(storage.repairItems['lateral_under_1ft']!.category, 'pipe_lateral');
        expect(storage.repairItems['mainline_under_1ft']!.category, 'pipe_mainline');
        expect(storage.repairItems['valve_1_inch_repair']!.category, 'valves');
        expect(storage.repairItems['controller_replacement']!.category, 'controller');
        expect(storage.repairItems['rain_sensor']!.category, 'sensor');
        expect(storage.repairItems['troubleshoot']!.category, 'service');
        expect(storage.repairItems['wire_repair_minimal']!.category, 'wire');
        expect(storage.repairItems['winterize_system']!.category, 'winterize');
        expect(storage.repairItems['backflow_repair']!.category, 'backflow');
        expect(storage.repairItems['ball_valve_replacement']!.category, 'ball_valve');
      });

      test('should get all categories', () {
        // Act
        final categories = storage.getCategories();

        // Assert
        expect(categories, isNotEmpty);
        expect(categories, contains('heads'));
        expect(categories, contains('valves'));
        expect(categories, contains('controller'));
        expect(categories, isSorted);
      });

      test('should get items by category', () {
        // Act
        final headItems = storage.getItemsByCategory('heads');
        final valveItems = storage.getItemsByCategory('valves');

        // Assert
        expect(headItems.isNotEmpty, true);
        expect(headItems.every((item) => item.category == 'heads'), true);
        expect(headItems.length, 4); // 4_inch, 6_inch, 12_inch, rotor

        expect(valveItems.isNotEmpty, true);
        expect(valveItems.every((item) => item.category == 'valves'), true);
        expect(valveItems.length, 6); // 1", 1.5", 2" repair/replace
      });

      test('should return empty list for non-existent category', () {
        // Act
        final items = storage.getItemsByCategory('nonexistent');

        // Assert
        expect(items, isEmpty);
      });
    });

    group('User Management', () {
      test('should add new user', () {
        // Arrange
        final newUser = User(
          email: 'tech@example.com',
          password: 'pass123',
          role: 'technician',
          name: 'Tech User',
        );

        // Act
        storage.users[newUser.email] = newUser;

        // Assert
        expect(storage.users.containsKey('tech@example.com'), true);
        expect(storage.users['tech@example.com'], newUser);
      });

      test('should update existing user', () {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final originalUser = storage.users[email]!;
        final updatedUser = originalUser.copyWith(name: 'Updated Admin');

        // Act
        storage.users[email] = updatedUser;

        // Assert
        expect(storage.users[email]!.name, 'Updated Admin');
      });

      test('should remove user', () {
        // Arrange
        final email = 'temp@example.com';
        storage.users[email] = User(
          email: email,
          password: 'temp',
          role: 'technician',
          name: 'Temp',
        );

        // Act
        storage.users.remove(email);

        // Assert
        expect(storage.users.containsKey(email), false);
      });
    });

    group('Property Management', () {
      test('should add new property with incremented ID', () {
        // Arrange
        final initialId = storage.nextPropertyId;
        final property = Property(
          id: storage.nextPropertyId++,
          address: '123 Main St',
          meterLocation: 'Front yard',
          backflowLocation: 'Side yard',
          backflowNumber: 'BF001',
          controllers: [],
          zones: [],
        );

        // Act
        storage.properties[property.id] = property;

        // Assert
        expect(storage.properties.containsKey(initialId), true);
        expect(storage.properties[initialId]!.address, '123 Main St');
        expect(storage.nextPropertyId, initialId + 1);
      });

      test('should update existing property', () {
        // Arrange
        final propertyId = storage.nextPropertyId++;
        storage.properties[propertyId] = Property(
          id: propertyId,
          address: '123 Main St',
          meterLocation: 'Front',
          backflowLocation: 'Side',
          backflowNumber: 'BF001',
          controllers: [],
          zones: [],
        );

        // Act
        final updated = storage.properties[propertyId]!.copyWith(
          address: '456 Oak Ave',
        );
        storage.properties[propertyId] = updated;

        // Assert
        expect(storage.properties[propertyId]!.address, '456 Oak Ave');
        expect(storage.properties[propertyId]!.meterLocation, 'Front');
      });
    });

    group('Inspection Management', () {
      test('should add new inspection with incremented ID', () {
        // Arrange
        final initialId = storage.nextInspectionId;
        final inspection = Inspection(
          id: storage.nextInspectionId++,
          propertyId: 1,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'assigned',
          repairs: [],
          totalCost: 0.0,
        );

        // Act
        storage.inspections[inspection.id] = inspection;

        // Assert
        expect(storage.inspections.containsKey(initialId), true);
        expect(storage.inspections[initialId]!.technician, 'tech@example.com');
        expect(storage.nextInspectionId, initialId + 1);
      });

      test('should update inspection status', () {
        // Arrange
        final inspectionId = storage.nextInspectionId++;
        storage.inspections[inspectionId] = Inspection(
          id: inspectionId,
          propertyId: 1,
          technician: 'tech@example.com',
          date: '2024-01-15',
          status: 'assigned',
          repairs: [],
          totalCost: 0.0,
        );

        // Act
        final updated = storage.inspections[inspectionId]!.copyWith(
          status: 'completed',
        );
        storage.inspections[inspectionId] = updated;

        // Assert
        expect(storage.inspections[inspectionId]!.status, 'completed');
      });
    });

    group('Failed Attempts Tracking', () {
      test('should track failed login attempts', () {
        // Arrange
        final email = 'test@example.com';

        // Act
        storage.failedAttempts[email] = 1;

        // Assert
        expect(storage.failedAttempts[email], 1);
      });

      test('should increment failed attempts', () {
        // Arrange
        final email = 'test@example.com';
        storage.failedAttempts[email] = 1;

        // Act
        storage.failedAttempts[email] = storage.failedAttempts[email]! + 1;

        // Assert
        expect(storage.failedAttempts[email], 2);
      });

      test('should reset failed attempts', () {
        // Arrange
        final email = 'test@example.com';
        storage.failedAttempts[email] = 3;

        // Act
        storage.failedAttempts[email] = 0;

        // Assert
        expect(storage.failedAttempts[email], 0);
      });
    });

    group('Data Serialization', () {
      test('should serialize user to JSON correctly', () {
        // Arrange
        final user = storage.users['admin@thriveoutdoor.com']!;

        // Act
        final json = user.toJson();

        // Assert
        expect(json['password'], 'temp1234');
        expect(json['role'], 'manager');
        expect(json['name'], 'Admin');
        expect(json.containsKey('email'), false); // Email is the key, not in JSON
      });

      test('should deserialize user from JSON correctly', () {
        // Arrange
        final json = {
          'password': 'test123',
          'role': 'technician',
          'name': 'Test User',
        };

        // Act
        final user = User.fromJson('test@example.com', json);

        // Assert
        expect(user.email, 'test@example.com');
        expect(user.password, 'test123');
        expect(user.role, 'technician');
        expect(user.name, 'Test User');
      });

      test('should serialize repair item to JSON correctly', () {
        // Arrange
        final item = storage.repairItems['4_inch_head']!;

        // Act
        final json = item.toJson();

        // Assert
        expect(json['price'], 0.00);
        expect(json['category'], 'heads');
        expect(json['requires_notes'], false);
      });

      test('should deserialize repair item from JSON correctly', () {
        // Arrange
        final json = {
          'price': 25.50,
          'category': 'heads',
          'requires_notes': false,
        };

        // Act
        final item = RepairItem.fromJson('test_head', json);

        // Assert
        expect(item.name, 'test_head');
        expect(item.price, 25.50);
        expect(item.category, 'heads');
        expect(item.requiresNotes, false);
      });

      test('should handle missing JSON fields with defaults', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final user = User.fromJson('test@example.com', json);

        // Assert
        expect(user.email, 'test@example.com');
        expect(user.password, '');
        expect(user.role, 'technician');
        expect(user.name, '');
      });
    });

    group('Complex Object Serialization', () {
      test('should serialize and deserialize property with zones', () {
        // Arrange
        final property = Property(
          id: 1,
          address: '123 Main St',
          meterLocation: 'Front',
          backflowLocation: 'Side',
          backflowNumber: 'BF001',
          controllers: ['Controller 1'],
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
        final json = property.toJson();
        final deserialized = Property.fromJson(1, json);

        // Assert
        expect(deserialized.id, property.id);
        expect(deserialized.address, property.address);
        expect(deserialized.zones.length, 1);
        expect(deserialized.zones[0].zoneNumber, 1);
        expect(deserialized.zones[0].description, 'Front lawn');
      });

      test('should serialize and deserialize inspection with repairs', () {
        // Arrange
        final inspection = Inspection(
          id: 1,
          propertyId: 1,
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
            Repair(
              zoneNumber: 2,
              itemName: 'rotor',
              quantity: 3,
              price: 15.0,
            ),
          ],
          totalCost: 95.0,
        );

        // Act
        final json = inspection.toJson();
        final deserialized = Inspection.fromJson(1, json);

        // Assert
        expect(deserialized.id, inspection.id);
        expect(deserialized.repairs.length, 2);
        expect(deserialized.repairs[0].itemName, '4_inch_head');
        expect(deserialized.repairs[0].quantity, 5);
        expect(deserialized.repairs[1].itemName, 'rotor');
        expect(deserialized.totalCost, 95.0);
      });
    });

    group('ID Counter Management', () {
      test('should increment property ID counter', () {
        // Arrange
        final initialId = storage.nextPropertyId;

        // Act
        storage.nextPropertyId++;

        // Assert
        expect(storage.nextPropertyId, initialId + 1);
      });

      test('should increment inspection ID counter', () {
        // Arrange
        final initialId = storage.nextInspectionId;

        // Act
        storage.nextInspectionId++;

        // Assert
        expect(storage.nextInspectionId, initialId + 1);
      });

      test('should maintain separate counters for properties and inspections', () {
        // Act
        storage.nextPropertyId += 5;
        storage.nextInspectionId += 3;

        // Assert
        expect(storage.nextPropertyId, 6);
        expect(storage.nextInspectionId, 4);
      });
    });
  });
}

extension on List {
  bool get isSorted {
    for (int i = 0; i < length - 1; i++) {
      if (this[i].toString().compareTo(this[i + 1].toString()) > 0) {
        return false;
      }
    }
    return true;
  }
}
