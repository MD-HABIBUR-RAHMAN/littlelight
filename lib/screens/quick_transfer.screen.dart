import 'package:bungie_api/enums/bucket_scope.dart';
import 'package:bungie_api/enums/destiny_class.dart';
import 'package:bungie_api/models/destiny_inventory_bucket_definition.dart';
import 'package:flutter/material.dart';
import 'package:little_light/screens/search.screen.dart';
import 'package:little_light/services/bungie_api/enums/inventory_bucket_hash.enum.dart';
import 'package:little_light/services/profile/profile.service.dart';
import 'package:little_light/services/user_settings/user_settings.service.dart';
import 'package:little_light/utils/item_filters/class_type_filter.dart';
import 'package:little_light/utils/item_filters/item_bucket_filter.dart';
import 'package:little_light/utils/item_filters/item_owner_filter.dart';
import 'package:little_light/utils/item_with_owner.dart';
import 'package:little_light/widgets/search/quick_transfer_list.widget.dart';
import 'package:little_light/widgets/search/search.controller.dart';

Set<String> _characterIdsExcept(
    String characterId, DestinyInventoryBucketDefinition bucketDef) {
  Set<String> all =
      ProfileService().getCharacters().map((c) => c.characterId).toSet();
  all.add(ItemWithOwner.OWNER_VAULT);
  all.add(ItemWithOwner.OWNER_PROFILE);
  if (bucketDef.scope == BucketScope.Account) {
    if (bucketDef.hash == InventoryBucket.general) {
      characterId = ItemWithOwner.OWNER_VAULT;
    } else {
      characterId = ItemWithOwner.OWNER_PROFILE;
    }
  }
  all.remove(characterId);
  return all;
}

class QuickTransferScreen extends SearchScreen {
  final UserSettingsService settings = UserSettingsService();
  final DestinyInventoryBucketDefinition bucketDefinition;
  final String characterId;
  final DestinyClass classType;

  QuickTransferScreen({this.bucketDefinition, this.classType, this.characterId})
      : super(
            controller: SearchController.withDefaultFilters(firstRunFilters: [
          ItemBucketFilter(
              selected: [bucketDefinition.hash].toSet(), enabled: true),
          ClassTypeFilter(
              selected: [
                InventoryBucket.armorBucketHashes
                        .contains(bucketDefinition.hash)
                    ? classType
                    : null
              ].where((i)=>i!=null).toSet(),
              enabled: true),
          ItemOwnerFilter(_characterIdsExcept(characterId, bucketDefinition),
              enabled: true)
        ]));

  @override
  QuickTransferScreenState createState() => new QuickTransferScreenState();
}

class QuickTransferScreenState extends SearchScreenState<QuickTransferScreen> {
  @override
  buildList(BuildContext context) {
    return QuickTransferListWidget(controller: controller);
  }
}
