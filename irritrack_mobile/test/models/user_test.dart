import 'package:flutter_test/flutter_test.dart';
import 'package:irritrack_mobile/models/user.dart';

void main() {
  group('User Model', () {
    group('Constructor', () {
      test('should create user with all required fields', () {
        // Arrange & Act
        final user = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'manager',
          name: 'Test User',
        );

        // Assert
        expect(user.email, 'test@example.com');
        expect(user.password, 'password123');
        expect(user.role, 'manager');
        expect(user.name, 'Test User');
      });

      test('should create user with technician role', () {
        // Arrange & Act
        final user = User(
          email: 'tech@example.com',
          password: 'tech123',
          role: 'technician',
          name: 'Tech User',
        );

        // Assert
        expect(user.role, 'technician');
      });
    });

    group('toJson', () {
      test('should serialize user to JSON correctly', () {
        // Arrange
        final user = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'manager',
          name: 'Test User',
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['password'], 'password123');
        expect(json['role'], 'manager');
        expect(json['name'], 'Test User');
        expect(json.containsKey('email'), false); // Email should not be in JSON
      });

      test('should serialize special characters correctly', () {
        // Arrange
        final user = User(
          email: 'test@example.com',
          password: 'P@ssw0rd!#$',
          role: 'manager',
          name: "O'Brien",
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['password'], 'P@ssw0rd!#$');
        expect(json['name'], "O'Brien");
      });

      test('should handle empty strings', () {
        // Arrange
        final user = User(
          email: '',
          password: '',
          role: '',
          name: '',
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['password'], '');
        expect(json['role'], '');
        expect(json['name'], '');
      });
    });

    group('fromJson', () {
      test('should deserialize user from JSON correctly', () {
        // Arrange
        final json = {
          'password': 'password123',
          'role': 'manager',
          'name': 'Test User',
        };

        // Act
        final user = User.fromJson('test@example.com', json);

        // Assert
        expect(user.email, 'test@example.com');
        expect(user.password, 'password123');
        expect(user.role, 'manager');
        expect(user.name, 'Test User');
      });

      test('should use default values for missing fields', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final user = User.fromJson('test@example.com', json);

        // Assert
        expect(user.email, 'test@example.com');
        expect(user.password, '');
        expect(user.role, 'technician'); // Default role
        expect(user.name, '');
      });

      test('should handle null values with defaults', () {
        // Arrange
        final json = {
          'password': null,
          'role': null,
          'name': null,
        };

        // Act
        final user = User.fromJson('test@example.com', json);

        // Assert
        expect(user.password, '');
        expect(user.role, 'technician');
        expect(user.name, '');
      });

      test('should preserve special characters', () {
        // Arrange
        final json = {
          'password': 'P@ssw0rd!#$',
          'role': 'manager',
          'name': "O'Brien & Sons",
        };

        // Act
        final user = User.fromJson('special@example.com', json);

        // Assert
        expect(user.password, 'P@ssw0rd!#$');
        expect(user.name, "O'Brien & Sons");
      });
    });

    group('copyWith', () {
      test('should create copy with updated email', () {
        // Arrange
        final original = User(
          email: 'old@example.com',
          password: 'password123',
          role: 'manager',
          name: 'Test User',
        );

        // Act
        final updated = original.copyWith(email: 'new@example.com');

        // Assert
        expect(updated.email, 'new@example.com');
        expect(updated.password, 'password123');
        expect(updated.role, 'manager');
        expect(updated.name, 'Test User');
      });

      test('should create copy with updated password', () {
        // Arrange
        final original = User(
          email: 'test@example.com',
          password: 'oldpass',
          role: 'manager',
          name: 'Test User',
        );

        // Act
        final updated = original.copyWith(password: 'newpass');

        // Assert
        expect(updated.email, 'test@example.com');
        expect(updated.password, 'newpass');
        expect(updated.role, 'manager');
        expect(updated.name, 'Test User');
      });

      test('should create copy with updated role', () {
        // Arrange
        final original = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'technician',
          name: 'Test User',
        );

        // Act
        final updated = original.copyWith(role: 'manager');

        // Assert
        expect(updated.email, 'test@example.com');
        expect(updated.role, 'manager');
      });

      test('should create copy with updated name', () {
        // Arrange
        final original = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'manager',
          name: 'Old Name',
        );

        // Act
        final updated = original.copyWith(name: 'New Name');

        // Assert
        expect(updated.email, 'test@example.com');
        expect(updated.name, 'New Name');
      });

      test('should create copy with multiple updated fields', () {
        // Arrange
        final original = User(
          email: 'old@example.com',
          password: 'oldpass',
          role: 'technician',
          name: 'Old Name',
        );

        // Act
        final updated = original.copyWith(
          email: 'new@example.com',
          password: 'newpass',
          role: 'manager',
          name: 'New Name',
        );

        // Assert
        expect(updated.email, 'new@example.com');
        expect(updated.password, 'newpass');
        expect(updated.role, 'manager');
        expect(updated.name, 'New Name');
      });

      test('should create copy with no changes when no parameters provided', () {
        // Arrange
        final original = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'manager',
          name: 'Test User',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.email, original.email);
        expect(copy.password, original.password);
        expect(copy.role, original.role);
        expect(copy.name, original.name);
      });

      test('should not modify original object', () {
        // Arrange
        final original = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'manager',
          name: 'Test User',
        );

        // Act
        final updated = original.copyWith(name: 'Updated Name');

        // Assert
        expect(original.name, 'Test User');
        expect(updated.name, 'Updated Name');
      });
    });

    group('Serialization Round-Trip', () {
      test('should maintain data integrity through serialization cycle', () {
        // Arrange
        final original = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'manager',
          name: 'Test User',
        );

        // Act
        final json = original.toJson();
        final deserialized = User.fromJson('test@example.com', json);

        // Assert
        expect(deserialized.email, original.email);
        expect(deserialized.password, original.password);
        expect(deserialized.role, original.role);
        expect(deserialized.name, original.name);
      });

      test('should handle complex characters through serialization cycle', () {
        // Arrange
        final original = User(
          email: 'test+tag@example.com',
          password: 'P@$$w0rd!@#$%^&*()',
          role: 'manager',
          name: 'Tëst Üsér with Áccents',
        );

        // Act
        final json = original.toJson();
        final deserialized = User.fromJson('test+tag@example.com', json);

        // Assert
        expect(deserialized.email, original.email);
        expect(deserialized.password, original.password);
        expect(deserialized.role, original.role);
        expect(deserialized.name, original.name);
      });
    });

    group('Role Validation', () {
      test('should accept manager role', () {
        // Arrange & Act
        final user = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'manager',
          name: 'Test User',
        );

        // Assert
        expect(user.role, 'manager');
      });

      test('should accept technician role', () {
        // Arrange & Act
        final user = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'technician',
          name: 'Test User',
        );

        // Assert
        expect(user.role, 'technician');
      });

      test('should allow any string as role', () {
        // Arrange & Act
        final user = User(
          email: 'test@example.com',
          password: 'password123',
          role: 'invalid_role',
          name: 'Test User',
        );

        // Assert
        expect(user.role, 'invalid_role');
      });
    });
  });
}
