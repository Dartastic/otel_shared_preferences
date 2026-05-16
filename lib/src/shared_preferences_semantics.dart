// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Key-value-store attribute keys for `SharedPreferences`.
enum SharedPreferencesSemantics implements OTelSemantic {
  /// `storage.system` — constant `shared_preferences`.
  system('storage.system'),

  /// `storage.operation` — `setString` / `setInt` / `setBool` /
  /// `setDouble` / `setStringList` / `remove` / `clear`.
  operation('storage.operation'),

  /// `storage.key` — the preference key being written or removed.
  storageKey('storage.key');

  @override
  final String key;

  @override
  String toString() => key;

  const SharedPreferencesSemantics(this.key);
}
