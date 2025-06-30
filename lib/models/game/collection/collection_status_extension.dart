// lib/models/game/collection/collection_status_extension.dart

import 'package:suxingchahui/models/game/collection/collection_item.dart';
import 'package:suxingchahui/models/game/collection/enrich_collection_status.dart';

extension CollectionStatusExtension on CollectionItem {
  bool get isPlayed => status == CollectionItem.statusPlayed;
  bool get isPlaying => status == CollectionItem.statusPlaying;
  bool get isWantToPlay => status == CollectionItem.statusWantToPlay;
  EnrichCollectionStatus get enrichCollectionStatus =>
      EnrichCollectionStatus.fromStatus(status);
}
