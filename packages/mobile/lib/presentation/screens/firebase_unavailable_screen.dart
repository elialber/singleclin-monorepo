import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:singleclin_mobile/data/services/firebase_initialization_service.dart';
import 'package:singleclin_mobile/presentation/widgets/firebase_unavailable_view.dart';

/// Full-screen fallback shown when Firebase initialization is not available.
class FirebaseUnavailableScreen extends StatefulWidget {
  const FirebaseUnavailableScreen({super.key});

  @override
  State<FirebaseUnavailableScreen> createState() =>
      _FirebaseUnavailableScreenState();
}

class _FirebaseUnavailableScreenState extends State<FirebaseUnavailableScreen> {
  late final FirebaseInitializationService _firebaseService;
  StreamSubscription<bool>? _firebaseReadySubscription;

  @override
  void initState() {
    super.initState();
    _firebaseService = Get.find<FirebaseInitializationService>();
    _firebaseReadySubscription = _firebaseService.firebaseReadyStream.listen((
      isReady,
    ) {
      if (isReady && mounted) {
        Get.offAllNamed('/splash');
      }
    });
  }

  @override
  void dispose() {
    _firebaseReadySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Conexão necessária'),
        ),
        body: const FirebaseUnavailableView(),
      ),
    );
  }
}
