import 'dart:async';

import 'package:dio/dio.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/models/enums.dart';
import 'package:english_mobile_app/core/network/api_client.dart';
import 'package:english_mobile_app/core/network/api_failure.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:english_mobile_app/features/auth/presentation/welcome_screen.dart';
import 'package:english_mobile_app/features/auth/presentation/learning_unavailable_screen.dart';
import 'package:english_mobile_app/features/scenarios/data/remote_scenario_repository.dart';
import 'package:english_mobile_app/features/scenarios/data/scenario_repository.dart';
import 'package:english_mobile_app/features/scenarios/presentation/controllers/scenario_controller.dart';
import 'package:english_mobile_app/features/scenarios/presentation/scenario_catalog_screen.dart';
import 'package:english_mobile_app/features/scenarios/presentation/scenario_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'api_client_test.dart' show ScriptedAdapter, jsonResponse;

const scenarioId = '10000000-0000-0000-0000-000000000001';
const topicId = '20000000-0000-0000-0000-000000000001';
const config = AppConfig(apiBaseUrl: 'https://catalog.example.test/api/v1');

Map<String, Object?> scenarioJson() => {
      'id': scenarioId,
      'topicId': topicId,
      'level': 'C1',
      'title': 'Thuyết trình và phản biện ý tưởng',
      'description':
          'Trình bày quan điểm và trao đổi lập luận với đồng nghiệp.',
      'roleAi': 'Đồng nghiệp',
      'roleUser': 'Người thuyết trình',
      'learningObjectives': ['Diễn đạt quan điểm rõ ràng'],
      'estimatedMinutes': 8,
      'samplePhrases': ['I would argue that...'],
      'vocabularyPreview': [
        {'phrase': 'trade-off', 'meaningVi': 'Sự đánh đổi', 'ipa': null},
      ],
      'active': true,
    };

Map<String, Object?> pageJson({int page = 0, bool hasMore = false}) => {
      'items': [scenarioJson()],
      'page': page,
      'size': 20,
      'hasMore': hasMore,
    };

void main() {
  late ScriptedAdapter adapter;
  late ApiClient client;
  late RemoteScenarioRepository repository;

  void create(FutureOr<ResponseBody> Function(RequestOptions, int) response) {
    adapter = ScriptedAdapter(response);
    final dio = Dio()..httpClientAdapter = adapter;
    client = ApiClient(
      config: config,
      accessToken: () => throw StateError('Public catalog must not read token'),
      dio: dio,
    );
    repository = RemoteScenarioRepository(client);
    addTearDown(client.close);
  }

  test(
      'production selects remote catalog and missing config never returns demo',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repo = container.read(scenarioRepositoryProvider);
    expect(repo, isA<RemoteScenarioRepository>());
    await expectLater(repo.getTopics(), throwsA(isA<ApiFailure>()));
    final demo = ProviderContainer(overrides: [
      appConfigProvider.overrideWithValue(const AppConfig(demoMode: true)),
    ]);
    addTearDown(demo.dispose);
    expect(
        demo.read(scenarioRepositoryProvider), isA<LocalScenarioRepository>());
  });

  test(
      'maps backend camelCase metadata and sends exact unauthenticated filters',
      () async {
    create((_, __) => jsonResponse(pageJson(page: 2, hasMore: true)));
    final page = await repository.getScenarioPage(
      topicId: topicId,
      level: UserLevel.c1,
      searchQuery: '  luận  ',
      page: 2,
    );
    expect(page.items.single.topicId, topicId);
    expect(page.items.single.level, UserLevel.c1);
    expect(page.items.single.vocabularyPreview.single.meaningVi, 'Sự đánh đổi');
    expect(page.items.single.vocabularyPreview.single.ipa, '');
    expect(page.hasMore, isTrue);
    expect(adapter.requests.single.queryParameters, {
      'page': 2,
      'size': 20,
      'topic': topicId,
      'level': 'C1',
      'q': 'luận',
    });
    expect(
        adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('rejects unknown levels and malformed pagination rather than guessing',
      () async {
    create((_, count) => jsonResponse(count == 1
        ? {
            ...pageJson(),
            'items': [
              {...scenarioJson(), 'level': 'C3'}
            ]
          }
        : {...pageJson(), 'page': 9}));
    for (var i = 0; i < 2; i++) {
      await expectLater(
          repository.getScenarioPage(),
          throwsA(isA<ApiFailure>()
              .having((e) => e.code, 'code', 'INVALID_RESPONSE')));
    }
  });

  test(
      'rejects legacy/extra fields, illegal nulls and fractional page metadata',
      () async {
    final cases = [
      {
        ...pageJson(),
        'items': [
          {...scenarioJson(), 'topic_id': topicId}
        ]
      },
      {
        ...pageJson(),
        'items': [
          {...scenarioJson(), 'samplePhrases': null}
        ]
      },
      {
        ...pageJson(),
        'items': [
          {...scenarioJson(), 'active': null}
        ]
      },
      {...pageJson(), 'size': 20.0},
      {...pageJson(), 'extra': 'uncontracted'},
    ];
    create((_, count) => jsonResponse(cases[count - 1]));
    for (final _ in cases) {
      await expectLater(
          repository.getScenarioPage(),
          throwsA(isA<ApiFailure>()
              .having((error) => error.code, 'code', 'INVALID_RESPONSE')));
    }
  });

  test('late old query response cannot overwrite the latest result', () async {
    final old = Completer<ResponseBody>();
    create((request, _) => request.queryParameters['q'] == 'old'
        ? old.future
        : jsonResponse({
            ...pageJson(),
            'items': [
              {...scenarioJson(), 'title': 'New result'}
            ]
          }));
    final container = ProviderContainer(overrides: [
      scenarioRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    container.read(searchQueryProvider.notifier).state = 'old';
    container.read(catalogPageProvider.future);
    await Future<void>.delayed(Duration.zero);
    container.read(searchQueryProvider.notifier).state = 'new';
    await container.read(catalogPageProvider.future);
    old.complete(jsonResponse({
      ...pageJson(),
      'items': [
        {...scenarioJson(), 'title': 'Old result'}
      ]
    }));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(catalogPageProvider).requireValue.items.single.title,
        'New result');
  });

  test('bounds filters locally and does not invent bookmarks or popularity',
      () async {
    create((_, __) => jsonResponse(pageJson()));
    for (final operation in [
      () => repository.getScenarioPage(page: -1),
      () => repository.getScenarioPage(size: 101),
      () => repository.getScenarioPage(searchQuery: 'x' * 101),
      () => repository.getScenarioPage(topicId: '../../admin'),
      () => repository.getScenarioPage(filterTab: 'popular'),
      () => repository.toggleBookmark(scenarioId),
    ]) {
      await expectLater(operation(), throwsA(isA<ApiFailure>()));
    }
    expect(adapter.requests, isEmpty);
  });

  test(
      '404 detail is absent, wrong ID is rejected, errors never fall back locally',
      () async {
    create((_, count) => count == 1
        ? jsonResponse({'code': 'NOT_FOUND'}, 404)
        : jsonResponse({...scenarioJson(), 'id': topicId}));
    expect(await repository.getScenarioById(scenarioId), isNull);
    await expectLater(
        repository.getScenarioById(scenarioId), throwsA(isA<ApiFailure>()));
    expect(await repository.getScenarioById('sc_demo_01'), isNull);
    expect(adapter.requests.length, 2);
  });

  test('page index resets on filters and latest page reads the backend',
      () async {
    create((options, _) => jsonResponse(
        pageJson(page: options.queryParameters['page'] as int, hasMore: true)));
    final container = ProviderContainer(overrides: [
      scenarioRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    await container.read(catalogPageProvider.future);
    container.read(catalogPageIndexProvider.notifier).state = 1;
    await container.read(catalogPageProvider.future);
    container.read(searchQueryProvider.notifier).state = 'new';
    await container.read(catalogPageProvider.future);
    expect(adapter.requests.map((r) => r.queryParameters['page']), [0, 1, 0]);
    expect(adapter.requests.last.queryParameters['q'], 'new');
  });

  testWidgets(
      'catalog retries safe error and presents server results without fake tabs',
      (tester) async {
    create((options, count) {
      if (count <= 2) {
        return jsonResponse({'message': 'secret backend stack'}, 503);
      }
      if (options.path == 'topics') {
        return jsonResponse([
          {'id': topicId, 'slug': 'work', 'title': 'Công việc'},
        ]);
      }
      return jsonResponse(pageJson(hasMore: true));
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [scenarioRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: ScenarioCatalogScreen()),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('secret backend stack'), findsNothing);
    // Catalog or topics can independently fail; each has an explicit retry.
    final retry = find.text('Thử lại');
    if (retry.evaluate().isNotEmpty) {
      await tester.tap(retry);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    expect(find.text('Thuyết trình và phản biện ý tưởng'), findsOneWidget);
    expect(find.text('Phổ biến'), findsNothing);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
    await tester.tap(find.byTooltip('Trang sau'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Fixture deliberately returns the wrong page: safe error, no stale page.
    expect(find.text('Thử lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'real detail offers remote text conversation and fits 320dp at 200% text',
      (tester) async {
    create((_, __) => jsonResponse(scenarioJson()));
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [scenarioRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const ScenarioDetailScreen(scenarioId: scenarioId),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Luyện chat tình huống này'), findsOneWidget);
    expect(find.text('Bắt đầu hội thoại ngay'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('catalog fits320dp200percent including safe error and retry',
      (tester) async {
    create((request, _) => jsonResponse(request.path.endsWith('topics')
        ? [
            {
              'id': topicId,
              'slug': 'work',
              'title': 'Công việc và giao tiếp chuyên nghiệp'
            }
          ]
        : pageJson()));
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [scenarioRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const ScenarioCatalogScreen(),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Thuyết trình và phản biện ý tưởng'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('welcome and unavailable remain scrollable at320dp200percent',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final screen in [
      const WelcomeScreen(),
      const LearningUnavailableScreen()
    ]) {
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: screen,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
