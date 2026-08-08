# otel_shared_preferences example

```dart
// example/lib/main.dart

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/material.dart';
import 'package:otel_shared_preferences/otel_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Bring up OTel before the first preference write so trace
  //    context is already flowing.
  await OTel.initialize(
    serviceName: 'shared-prefs-demo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SettingsPage());
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // ✨ Span: `shared_prefs setString user.id`
    //    storage.system    = shared_preferences
    //    storage.operation = setString
    //    storage.key       = user.id
    await prefs.tracedSetString('user.id', 'alice');

    // ✨ Span: `shared_prefs setBool darkMode`
    await prefs.tracedSetBool('darkMode', true);

    // ✨ Span: `shared_prefs remove temp`
    await prefs.tracedRemove('temp');

    // Reads stay untraced on purpose — they're synchronous and
    // cheap, so wrapping them would flood traces with low-value
    // spans.
    final theme = prefs.getBool('darkMode');
    debugPrint('darkMode: $theme');
  }

  Future<void> _resetEverything() async {
    final prefs = await SharedPreferences.getInstance();

    // ✨ Span: `shared_prefs clear` (no storage.key — it wipes all)
    await prefs.tracedClear();

    // Need a write to stay OUT of the trace? Suppress the
    // instrumentation for a scope:
    await runWithoutSharedPreferencesInstrumentationAsync(() async {
      await prefs.tracedSetString('internal.migration', 'done');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save settings'),
            ),
            ElevatedButton(
              onPressed: _resetEverything,
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Trace shape

```
tap "Save settings"
  shared_prefs setString user.id     (CLIENT)
  shared_prefs setBool darkMode      (CLIENT)
  shared_prefs remove temp           (CLIENT)

tap "Reset"
  shared_prefs clear                 (CLIENT)
  (suppressed write emits no span)
```

On failure the span records the exception, sets `error.type`, and
ends with status `Error` before the error is rethrown.
