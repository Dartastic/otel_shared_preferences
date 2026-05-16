# otel_shared_preferences

OpenTelemetry instrumentation for
[`package:shared_preferences`](https://pub.dev/packages/shared_preferences).

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.tracedSetString('user.id', 'alice');
await prefs.tracedSetBool('darkMode', true);
await prefs.tracedRemove('temp');
await prefs.tracedClear();
```

Each call emits a `CLIENT` span:
- name: `shared_prefs setString user.id`
- `storage.system = shared_preferences`
- `storage.operation = setString`
- `storage.key = user.id`

Reads (`getString`, `getInt`, …) are synchronous and not wrapped
— wrapping every read would generate a lot of low-value spans.
Open an issue if you have a use case that needs read spans.

Suppression: `runWithoutSharedPreferencesInstrumentationAsync`.

## License

Apache 2.0
