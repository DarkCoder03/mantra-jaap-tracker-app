/// The drawn symbols in the app's icon set (see `MantraSymbolPainter`).
enum MantraSymbol {
  lotus,
  bow,
  tripundra,
  morPankh,
  gada,
  trishul,
  diya,
  custom,
}

/// A symbol a person can attach to a counter.
class MantraIcon {
  final String id;
  final String label;
  final MantraSymbol symbol;

  const MantraIcon({
    required this.id,
    required this.label,
    required this.symbol,
  });

  bool get isCustom => symbol == MantraSymbol.custom;
}

abstract final class MantraIcons {
  static const String fallbackId = 'shri';
  static const String customId = 'custom';

  static const List<MantraIcon> all = [
    MantraIcon(id: 'shri', label: 'Shri', symbol: MantraSymbol.lotus),
    MantraIcon(id: 'ram', label: 'Ram', symbol: MantraSymbol.bow),
    MantraIcon(id: 'shiv', label: 'Shiv', symbol: MantraSymbol.tripundra),
    MantraIcon(id: 'krishna', label: 'Krishna', symbol: MantraSymbol.morPankh),
    MantraIcon(id: 'hanuman', label: 'Hanuman', symbol: MantraSymbol.gada),
    MantraIcon(id: 'durga', label: 'Durga', symbol: MantraSymbol.trishul),
    MantraIcon(id: 'kali', label: 'Kali', symbol: MantraSymbol.diya),
    MantraIcon(id: customId, label: 'Custom', symbol: MantraSymbol.custom),
  ];

  static final Map<String, MantraIcon> _byId = {for (final i in all) i.id: i};

  static bool exists(String id) => _byId.containsKey(id);

  static MantraIcon byId(String? id) => _byId[id] ?? _byId[fallbackId]!;

  /// Earlier symbol ids that map directly onto a current one.
  static const Map<String, String> legacyIds = {
    'shiva': 'shiv',
    'ram': 'raam',
    'rama': 'raam',
  };

  /// Earlier symbols that were removed. Counters that used them become
  /// "Custom" with the same character, so they look the same as before.
  static const Map<String, String> legacyGlyphs = {
    'om': 'ॐ',
    'ganesha': '🐘',
    'lakshmi': '🌺',
    'vishnu': '🐚',
    'saraswati': '🦢',
    'surya': '☀️',
    'chandra': '🌙',
    'agni': '🔥',
    'diya': '🪔',
  };
}
