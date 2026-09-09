import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nestroutine/main.dart';
import 'package:nestroutine/models/adapters/adapters.dart';
import 'package:nestroutine/utils/storage_service.dart';

class _InMemoryGotrueAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> getItem({required String key}) async => _store[key];

  @override
  Future<void> removeItem({required String key}) async => _store.remove(key);

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _store[key] = value;
}

void _mockMethodChannel(String name, Map<String, Object?> responses) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(MethodChannel(name), (call) async {
    return responses[call.method];
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => switch (call.method) {
            'initialize' => true,
            'areNotificationsEnabled' => true,
            _ => null,
          },
    );
    AndroidFlutterLocalNotificationsPlugin.registerWith();

    _mockMethodChannel('dev.fluttercommunity.plus/package_info', {
      'getAll': <String, Object?>{
        'appName': 'NestRoutine',
        'packageName': 'com.nestroutine.app',
        'version': '1.6.0',
        'buildNumber': '9',
      },
    });

    await dotenv.load();

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(
        detectSessionInUri: false,
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _InMemoryGotrueAsyncStorage(),
      ),
    );

    final directory = await Directory.systemTemp.createTemp('nestroutine_test');
    Hive.init(directory.path);
    Hive.registerAdapter(BabyAdapter());
    Hive.registerAdapter(BabyEventAdapter());
    Hive.registerAdapter(EventTypeAdapter());
    Hive.registerAdapter(FeedTypeAdapter());
    Hive.registerAdapter(FeedSideAdapter());
    Hive.registerAdapter(DiaperTextureAdapter());
    await StorageService.init();
  });

  tearDownAll(() async {
    await Supabase.instance.dispose();
  });

  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const NestRoutineApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
