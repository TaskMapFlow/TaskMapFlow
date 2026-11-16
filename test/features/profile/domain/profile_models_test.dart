import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/features/profile/domain/models/user_profile.dart';

void main() {
  group('UserProfile model', () {
    test('initials computation handles various name formats', () {
      final now = DateTime.now();

      final p1 = UserProfile(
        id: 'u1',
        displayName: 'Doğukan Şendoğan',
        createdAt: now,
        updatedAt: now,
      );
      expect(p1.initials, 'DŞ');

      final p2 = UserProfile(
        id: 'u2',
        displayName: 'Alice',
        createdAt: now,
        updatedAt: now,
      );
      expect(p2.initials, 'A');

      final p3 = UserProfile(
        id: 'u3',
        displayName: '   John   Middle   Doe   ',
        createdAt: now,
        updatedAt: now,
      );
      expect(p3.initials, 'JD');

      final p4 = UserProfile(
        id: 'u4',
        displayName: '',
        createdAt: now,
        updatedAt: now,
      );
      expect(p4.initials, '?');
    });

    test('isValidGithubUrl validates strict github.com URLs', () {
      // Valid URLs
      expect(UserProfile.isValidGithubUrl(''), isTrue);
      expect(UserProfile.isValidGithubUrl('   '), isTrue);
      expect(UserProfile.isValidGithubUrl('https://github.com/dogukansendogan'),
          isTrue);
      expect(
          UserProfile.isValidGithubUrl(
              'https://www.github.com/dogukansendogan'),
          isTrue);
      expect(UserProfile.isValidGithubUrl('https://github.com/user-name/repo'),
          isTrue);

      // Invalid schemes or evil phishing hosts
      expect(UserProfile.isValidGithubUrl('http://github.com/user'), isFalse);
      expect(UserProfile.isValidGithubUrl('https://github.com.evil.com/user'),
          isFalse);
      expect(UserProfile.isValidGithubUrl('https://evil-github.com/user'),
          isFalse);
      expect(UserProfile.isValidGithubUrl('ftp://github.com/user'), isFalse);
      expect(UserProfile.isValidGithubUrl('javascript:alert(1)'), isFalse);

      // Missing username or invalid characters
      expect(UserProfile.isValidGithubUrl('https://github.com'), isFalse);
      expect(UserProfile.isValidGithubUrl('https://github.com/'), isFalse);
    });

    test('copyWith works correctly', () {
      final now = DateTime.now();
      final p = UserProfile(
        id: 'u1',
        displayName: 'Old Name',
        bio: 'Old Bio',
        githubUrl: 'https://github.com/old',
        createdAt: now,
        updatedAt: now,
      );

      final updated = p.copyWith(
        displayName: 'New Name',
        bio: 'New Bio',
      );

      expect(updated.displayName, 'New Name');
      expect(updated.bio, 'New Bio');
      expect(updated.githubUrl, 'https://github.com/old');
      expect(updated.id, 'u1');
    });
  });
}
