/// `app_config` 한 행 — key/value(jsonb)/설명.
class ConfigEntry {
  ConfigEntry(this.key, this.value, this.description);

  factory ConfigEntry.fromRow(Map<String, dynamic> r) =>
      ConfigEntry(r['key'] as String, r['value'], r['description'] as String?);

  final String key;
  final Object? value;
  final String? description;
}
