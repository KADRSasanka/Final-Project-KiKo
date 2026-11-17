import 'dart:ui';

class ShopItem {
  const ShopItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.price,
    this.emoji = '',
    this.color,
  });

  final String id;
  final String slot; // 'hat' or 'background'
  final String name;
  final int price; // coins
  final String emoji; // hats
  final Color? color; // backgrounds
}

class ShopCatalog {
  ShopCatalog._();

  static const hatSlot = 'hat';
  static const backgroundSlot = 'background';

  static const all = <ShopItem>[
    // Hats
    ShopItem(id: 'hat_cap', slot: hatSlot, name: 'Cap', emoji: '🧢', price: 10),
    ShopItem(id: 'hat_bow', slot: hatSlot, name: 'Bow', emoji: '🎀', price: 10),
    ShopItem(id: 'hat_grad', slot: hatSlot, name: 'Grad Cap', emoji: '🎓', price: 20),
    ShopItem(id: 'hat_top', slot: hatSlot, name: 'Top Hat', emoji: '🎩', price: 30),
    ShopItem(id: 'hat_crown', slot: hatSlot, name: 'Crown', emoji: '👑', price: 50),
    // Backgrounds
    ShopItem(id: 'bg_sky', slot: backgroundSlot, name: 'Sky', color: Color(0xFF9AD1FF), price: 10),
    ShopItem(id: 'bg_mint', slot: backgroundSlot, name: 'Mint', color: Color(0xFF9BE8C4), price: 10),
    ShopItem(id: 'bg_lavender', slot: backgroundSlot, name: 'Lavender', color: Color(0xFFC9B8FF), price: 15),
    ShopItem(id: 'bg_sunset', slot: backgroundSlot, name: 'Sunset', color: Color(0xFFFFA07A), price: 15),
    ShopItem(id: 'bg_bubblegum', slot: backgroundSlot, name: 'Bubblegum', color: Color(0xFFFF9EC7), price: 20),
    ShopItem(id: 'bg_midnight', slot: backgroundSlot, name: 'Midnight', color: Color(0xFF3B4A7A), price: 25),
  ];

  static List<ShopItem> inSlot(String slot) => [
        for (final i in all)
          if (i.slot == slot) i,
      ];

  static ShopItem? byId(String? id) {
    if (id == null) return null;
    for (final i in all) {
      if (i.id == id) return i;
    }
    return null;
  }
}
