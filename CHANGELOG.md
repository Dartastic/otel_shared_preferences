# Changelog

## [0.1.0-beta.1-wip]

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
