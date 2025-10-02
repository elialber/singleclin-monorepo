import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:singleclin_mobile/data/services/firebase_initialization_service.dart';
import 'package:singleclin_mobile/presentation/widgets/firebase_unavailable_view.dart';

class _StubFirebaseInitializationService extends FirebaseInitializationService {
  bool retried = false;

  @override
  Future<void> retry() async {
    retried = true;
  }

  @override
  Future<void> initialize() async {
    // No-op for tests.
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('FirebaseUnavailableView shows diagnostics and triggers retry', (tester) async {
    final service = _StubFirebaseInitializationService()
      ..debugSetState(
        ready: false,
        failureCount: 2,
        errorMessage: 'timeout',
        lastAttempt: DateTime(2024, 1, 1, 12, 30),
      );

    Get.put<FirebaseInitializationService>(service);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: FirebaseUnavailableView(compact: true),
        ),
      ),
    );

    expect(find.text('Serviço de autenticação indisponível'), findsOneWidget);
    expect(find.textContaining('Tentativas consecutivas falhas'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(service.retried, isTrue);
  });

  testWidgets('FirebaseUnavailableView recovery tips sheet opens', (tester) async {
    final service = _StubFirebaseInitializationService()..debugSetState(ready: false);
    Get.put<FirebaseInitializationService>(service);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: FirebaseUnavailableView(compact: true),
        ),
      ),
    );

    await tester.tap(find.text('Como resolver?'));
    await tester.pumpAndSettle();

    expect(find.text('Como reestabelecer a conexão'), findsOneWidget);
  });
}
