import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:little_light/services/bungie-api/bungie-api.service.dart';
import 'package:little_light/services/manifest/manifest.service.dart';
import 'package:little_light/utils/shimmer-helper.dart';
import 'package:shimmer/shimmer.dart';

typedef String ExtractUrlFromData(dynamic data);

class ManifestImageWidget extends StatefulWidget {
  final String tableName;
  final int hash;
  final ExtractUrlFromData urlExtractor;
  final ManifestService _manifest = new ManifestService();

  ManifestImageWidget(this.tableName, this.hash,
      {Key key,
      this.urlExtractor})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ManifestImageState();
  }
}

class ManifestImageState extends State<ManifestImageWidget> {
  dynamic definition;

  @override
  void initState() {
    super.initState();
    loadDefinition();
  }

  Future<void> loadDefinition() async {
    definition =
        await widget._manifest.getDefinition(widget.tableName, widget.hash);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Shimmer shimmer = ShimmerHelper.getDefaultShimmer(context);
    String url = "";
    try {
      if (widget.urlExtractor == null) {
        url = definition.displayProperties.icon;
      } else {
        url = widget.urlExtractor(definition);
      }
    } catch (e) {}
    if(url == null){
      return shimmer;
    }
    return CachedNetworkImage(
      imageUrl: "${BungieApiService.baseUrl}$url",
      placeholder: shimmer,
    );
  }
}
