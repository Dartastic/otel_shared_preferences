// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_shared_preferences/otel_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OTel SharedPreferences extensions', () {
    late _MemorySpanExporter exporter;
    late SharedPreferences prefs;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'shared-prefs-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('tracedSetString emits CLIENT span with key + storage.* attrs',
        () async {
      await prefs.tracedSetString('user.id', 'alice');

      final span = exporter.spans.single;
      expect(span.kind, equals(SpanKind.client));
      expect(span.name, equals('shared_prefs setString user.id'));
      final attrs = _attrs(span);
      expect(attrs['storage.system'], equals('shared_preferences'));
      expect(attrs['storage.operation'], equals('setString'));
      expect(attrs['storage.key'], equals('user.id'));
    });

    test('tracedSetInt / tracedSetBool / tracedSetDouble emit their spans',
        () async {
      await prefs.tracedSetInt('count', 42);
      await prefs.tracedSetBool('darkMode', true);
      await prefs.tracedSetDouble('zoom', 1.5);

      final ops =
          exporter.spans.map((s) => _attrs(s)['storage.operation']).toSet();
      expect(ops, equals({'setInt', 'setBool', 'setDouble'}));
    });

    test('tracedSetStringList emits a setStringList span', () async {
      await prefs.tracedSetStringList('tags', ['a', 'b']);
      final span = exporter.spans.single;
      expect(_attrs(span)['storage.operation'], equals('setStringList'));
    });

    test('tracedRemove + tracedClear emit their spans', () async {
      await prefs.tracedSetString('temp', 'x');
      exporter.spans.clear();

      await prefs.tracedRemove('temp');
      await prefs.tracedClear();

      expect(
        exporter.spans.map((s) => _attrs(s)['storage.operation']).toList(),
        equals(['remove', 'clear']),
      );
      // clear() has no key.
      expect(
        _attrs(exporter.spans[1]).containsKey('storage.key'),
        isFalse,
      );
    });

    test('runWithoutSharedPreferencesInstrumentationAsync bypasses spans',
        () async {
      await runWithoutSharedPreferencesInstrumentationAsync(() async {
        await prefs.tracedSetString('key', 'value');
      });
      expect(exporter.spans, isEmpty);
    });
  });
}
