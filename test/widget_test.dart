// Tests for TaskMapFlowApp: localization, shell navigation, and setup required states.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/app/app.dart';
import 'package:task_map_flow/app/router.dart';

void main() {
  group('Setup Required Screen Tests', () {
    testWidgets('renders setup-required screen in English when locale is en',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TaskMapFlowApp(
            firebaseReady: false,
            locale: Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Firebase Setup Required'), findsOneWidget);
      expect(
        find.textContaining('No Firebase project is configured yet.'),
        findsOneWidget,
      );
    });

    testWidgets('renders setup-required screen in Turkish when locale is tr',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TaskMapFlowApp(
            firebaseReady: false,
            locale: Locale('tr'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Firebase Kurulumu Gerekli'), findsOneWidget);
      expect(
        find.textContaining('Henüz Firebase projesi yapılandırılmamış.'),
        findsOneWidget,
      );
    });
  });

  group('3-Tab App Shell Navigation & Localization Tests', () {
    testWidgets(
        'renders tabs in order [Profile, Home, Manage] with Home selected by default (en)',
        (tester) async {
      router.go('/home');
      await tester.pumpWidget(
        const ProviderScope(
          child: TaskMapFlowApp(
            firebaseReady: true,
            locale: Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab labels verified
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);

      // Default selected screen is Home (center tab)
      expect(find.text('TaskMapFlow'), findsOneWidget);
      expect(
        find.text('Map canvas will be added in a future phase.'),
        findsOneWidget,
      );

      // Navigate to Profile tab (left)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(
        find.text('Profile content will be added in a future phase.'),
        findsOneWidget,
      );

      // Navigate to Manage tab (right)
      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();
      expect(
        find.text('Workspace management will be added in a future phase.'),
        findsOneWidget,
      );
    });

    testWidgets('renders tabs in order [Profil, Ana Sayfa, Yönet] in Turkish',
        (tester) async {
      router.go('/home');
      await tester.pumpWidget(
        const ProviderScope(
          child: TaskMapFlowApp(
            firebaseReady: true,
            locale: Locale('tr'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab labels verified in Turkish
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.text('Yönet'), findsOneWidget);

      // Default selected screen is Home in Turkish
      expect(
        find.text('Harita görünümü bir sonraki aşamada eklenecek.'),
        findsOneWidget,
      );

      // Navigate to Profil tab
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(
        find.text('Profil içeriği bir sonraki aşamada eklenecek.'),
        findsOneWidget,
      );

      // Navigate to Yönet tab
      await tester.tap(find.text('Yönet'));
      await tester.pumpAndSettle();
      expect(
        find.text('Çalışma alanı yönetimi bir sonraki aşamada eklenecek.'),
        findsOneWidget,
      );
    });
  });
}
