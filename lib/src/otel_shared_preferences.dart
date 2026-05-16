// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_semantics.dart';
import 'shared_preferences_suppression.dart';

const _tracerName = 'otel_shared_preferences';
const _storageSystem = 'shared_preferences';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

Attributes _attrs(String operation, [String? key]) =>
    OTel.attributesFromMap(<String, Object>{
      SharedPreferencesSemantics.system.key: _storageSystem,
      SharedPreferencesSemantics.operation.key: operation,
      if (key != null) SharedPreferencesSemantics.storageKey.key: key,
    });

Future<R> _traced<R>({
  required String operation,
  String? key,
  required Future<R> Function() invoke,
}) async {
  if (sharedPreferencesInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    key == null ? 'shared_prefs $operation' : 'shared_prefs $operation $key',
    kind: SpanKind.client,
    attributes: _attrs(operation, key),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Traced write/remove/clear operations on [SharedPreferences].
///
/// Reads are synchronous and very fast, so they're intentionally
/// **not** wrapped here — wrapping every `getString` would
/// generate excessive spans for minimal observability value.
/// Open an issue if you have a use case that needs read-side
/// spans.
extension OTelSharedPreferences on SharedPreferences {
  /// Traced `setString`.
  Future<bool> tracedSetString(String key, String value) {
    return _traced<bool>(
      operation: 'setString',
      key: key,
      invoke: () => setString(key, value),
    );
  }

  /// Traced `setInt`.
  Future<bool> tracedSetInt(String key, int value) {
    return _traced<bool>(
      operation: 'setInt',
      key: key,
      invoke: () => setInt(key, value),
    );
  }

  /// Traced `setDouble`.
  Future<bool> tracedSetDouble(String key, double value) {
    return _traced<bool>(
      operation: 'setDouble',
      key: key,
      invoke: () => setDouble(key, value),
    );
  }

  /// Traced `setBool`.
  Future<bool> tracedSetBool(String key, bool value) {
    return _traced<bool>(
      operation: 'setBool',
      key: key,
      invoke: () => setBool(key, value),
    );
  }

  /// Traced `setStringList`.
  Future<bool> tracedSetStringList(String key, List<String> value) {
    return _traced<bool>(
      operation: 'setStringList',
      key: key,
      invoke: () => setStringList(key, value),
    );
  }

  /// Traced `remove`.
  Future<bool> tracedRemove(String key) {
    return _traced<bool>(
      operation: 'remove',
      key: key,
      invoke: () => remove(key),
    );
  }

  /// Traced `clear`. No key attribute since it wipes everything.
  Future<bool> tracedClear() {
    return _traced<bool>(operation: 'clear', invoke: clear);
  }
}
