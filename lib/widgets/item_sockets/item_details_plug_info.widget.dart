import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:bungie_api/models/destiny_item_component.dart';
import 'package:bungie_api/models/destiny_item_socket_category_definition.dart';
import 'package:bungie_api/models/destiny_material_requirement_set_definition.dart';
import 'package:bungie_api/models/destiny_sandbox_perk_definition.dart';
import 'package:flutter/material.dart';
import 'package:little_light/services/profile/profile.service.dart';
import 'package:little_light/utils/destiny_data.dart';
import 'package:little_light/widgets/common/base/base_destiny_stateless_item.widget.dart';
import 'package:little_light/widgets/common/definition_provider.widget.dart';
import 'package:little_light/widgets/common/header.wiget.dart';
import 'package:little_light/widgets/common/manifest_image.widget.dart';
import 'package:little_light/widgets/common/manifest_text.widget.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';
import 'package:little_light/widgets/item_stats/base_item_stat.widget.dart';
import 'package:little_light/widgets/item_stats/details_item_stat.widget.dart';

class ItemDetailsPlugInfoWidget extends BaseDestinyStatelessItemWidget {
  ItemDetailsPlugInfoWidget(
      {DestinyItemComponent item,
      DestinyInventoryItemDefinition definition,
      DestinyItemSocketCategoryDefinition category})
      : super(definition: definition, item: item);

  @override
  Widget build(BuildContext context) {
    if (definition == null) return Container();
    return Container(
        padding: EdgeInsets.all(8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              buildSandBoxPerks(context),
              buildStats(context),
              buildEnergyCost(context),
              buildResourceCost(context)
            ]));
  }

  buildStats(BuildContext context) {
    var stats = definition.investmentStats.map((s) {
      return DetailsItemStatWidget(
        modValues: StatValues(
            equipped: s.value, selected: s.value, precalculated: s.value),
        statHash: s.statTypeHash,
      );
    }).toList();
    if ((stats?.length ?? 0) <= 0) return Container();
    return Column(children: [
      Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: HeaderWidget(
            alignment: Alignment.centerLeft,
            child: TranslatedTextWidget(
              "Stats",
              uppercase: true,
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )),
      Container(
        constraints: BoxConstraints(maxWidth: 600),
        child: Column(
          children: stats,
        ),
      )
    ]);
  }

  Widget buildEnergyCost(BuildContext context) {
    var cost = definition?.plug?.energyCost;
    if ((cost?.energyCost ?? 0) < 1) {
      return Container();
    }
    return Column(children: [
      Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: HeaderWidget(
            alignment: Alignment.centerLeft,
            child: TranslatedTextWidget(
              "Energy Cost",
              uppercase: true,
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )),
      Container(
          constraints: BoxConstraints(maxWidth: 600),
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 8),
          color: DestinyData.getEnergyTypeColor(cost.energyType).withOpacity(.6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(DestinyData.getEnergyTypeIcon(cost.energyType),
                  color: DestinyData.getEnergyTypeLightColor(cost.energyType),
                  size: 20),
              Container(
                width: 4,
              ),
              Text(
                "${cost.energyCost}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24,
                ),
              ),
              Container(
                width: 4,
              ),
              TranslatedTextWidget(
                "Energy",
                uppercase: true,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              )
            ],
          )),
      Container(
          constraints: BoxConstraints(maxWidth: 600), child: buildBars(context))
    ]);
  }

  Widget buildBars(BuildContext context) {
    var cost = definition?.plug?.energyCost;
    var total = 10;
    var used = cost.energyCost;
    List<Widget> pieces = [];
    for (var i = 0; i < 10; i++) {
      pieces.add(Expanded(child: buildEnergyPiece(context, i, total, used)));
    }
    return Container(
        padding: EdgeInsets.all(8),
        color: Colors.blueGrey.shade600,
        child: Row(
          children: pieces,
        ));
  }

  Widget buildEnergyPiece(
      BuildContext context, int index, int total, int used) {
    if (index < total) {
      Color color = Colors.transparent;
      if (index < used) {
        color = Colors.white;
      }
      return Container(
        height: 16,
        padding: EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 2, color: Colors.white), color: color),
        ),
      );
    }

    return Container(
      height: 16,
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: Container(
        color: Colors.black.withOpacity(.5),
      ),
    );
  }

  Widget buildResourceCost(BuildContext context) {
    var requirementHash = definition?.plug?.insertionMaterialRequirementHash;
    if (requirementHash == null) {
      return Container();
    }
    var inventory = ProfileService().getProfileInventory();
    var currencies = ProfileService().getProfileCurrencies();
    return Column(children: [
      Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: HeaderWidget(
            alignment: Alignment.centerLeft,
            child: TranslatedTextWidget(
              "Material Required",
              uppercase: true,
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )),
      DefinitionProviderWidget<DestinyMaterialRequirementSetDefinition>(
          requirementHash,
          (def) => Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children:
                    def.materials.where((m) => (m.count ?? 0) > 0).map((m) {
                  var items = inventory.where((i) => i.itemHash == m.itemHash);
                  var itemsTotal = items.fold<int>(0, (t, i) => t + i.quantity);
                  var currency =
                      currencies.where((curr) => curr.itemHash == m.itemHash);
                  var total = currency.fold<int>(
                      itemsTotal, (t, curr) => t + curr.quantity);
                  bool isEnough = total >= m.count;
                  return Row(
                    children: <Widget>[
                      Container(
                          width: 20,
                          height: 20,
                          child: ManifestImageWidget<
                              DestinyInventoryItemDefinition>(m.itemHash)),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(left: 8),
                          child: ManifestText<DestinyInventoryItemDefinition>(
                            m.itemHash,
                            style: TextStyle(fontWeight: FontWeight.w300),
                          ),
                        ),
                      ),
                      Text("${m.count}/$total",
                          style: TextStyle(fontWeight: FontWeight.w300, color:isEnough ? Colors.grey.shade300 : DestinyData.negativeFeedback))
                    ],
                  );
                }).toList(),
              )),
          key: Key("material_requirements_$requirementHash"))
    ]);
  }

  Widget buildSandBoxPerks(BuildContext context) {
    var perks = definition?.perks;
    if ((perks?.length ?? 0) == 0) return Container();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: perks
          ?.map(
            (p) => DefinitionProviderWidget<DestinySandboxPerkDefinition>(
                p.perkHash,
                (def) => def?.displayProperties?.description != null
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        child: Text(
                          def?.displayProperties?.description,
                          style: TextStyle(fontSize: 14),
                        ))
                    : Container()),
          )
          ?.toList(),
    );
  }
}
