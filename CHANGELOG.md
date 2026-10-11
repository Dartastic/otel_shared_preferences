# Changelog

## [0.2.1-wip]

## [0.2.0] - 2026-10-11

### Changed

- Requires `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- **Breaking:** depends on `dartastic_opentelemetry_api` only, no
  longer on the SDK. The application chooses and initializes the
  OpenTelemetry SDK. Parameters and fields typed with SDK classes
  now use the API types (`APITracer`, `APISpan`, `APILogger`, ...);
  SDK instances are still accepted wherever an API type is expected.

## [0.1.0] - 2026-08-10

### Added

- Extension methods on `SharedPreferences`: `tracedSetString`,
  `tracedSetInt`, `tracedSetBool`, `tracedSetDouble`,
  `tracedSetStringList`, `tracedRemove`, `tracedClear`. Each
  opens a `CLIENT` span named `shared_prefs <op> <key>` with
  `storage.system=shared_preferences`, `storage.operation`,
  `storage.key`.
- Reads (`getString`, `getInt`, etc.) are intentionally NOT
  wrapped — they're synchronous and very fast, so the overhead
  isn't worth it for typical apps. File an issue if you need
  them.
- Zone-scoped suppression helpers
  (`runWithoutSharedPreferencesInstrumentation` and the async
  variant) mirroring the rest of the OSS wrappers.
- Tests use `SharedPreferences.setMockInitialValues`; no real
  preferences backend needed.
