import 'dart:ui';

/// A sorting-game bin: recycle, compost, or trash.
class BinInfo {
  const BinInfo(this.id, this.label, this.emoji, this.color);

  final String id;
  final String label;
  final String emoji;
  final Color color;
}

class BinCatalog {
  BinCatalog._();

  static const _all = <String, BinInfo>{
    'recycle': BinInfo('recycle', 'Recycle', '♻️', Color(0xFF3A86FF)),
    'compost': BinInfo('compost', 'Compost', '🍂', Color(0xFFB5834C)),
    'trash': BinInfo('trash', 'Trash', '🗑️', Color(0xFF8D99AE)),
  };

  static BinInfo byId(String id) =>
      _all[id] ?? const BinInfo('trash', 'Trash', '🗑️', Color(0xFF8D99AE));
}
