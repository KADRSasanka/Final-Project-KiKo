import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/shop_repository.dart';
import '../../profile/providers/profile_providers.dart';

final shopRepositoryProvider = Provider<ShopRepository>(
  (ref) => ShopRepository(ref.watch(firestoreProvider)),
);
