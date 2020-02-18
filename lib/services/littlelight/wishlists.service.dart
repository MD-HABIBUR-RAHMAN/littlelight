import 'package:bungie_api/models/destiny_item_component.dart';
import 'package:http/http.dart' as http;
import 'package:little_light/models/wish_list.dart';
import 'package:little_light/services/littlelight/parsers/dim_wishlist.parser.dart';
import 'package:little_light/services/profile/profile.service.dart';
import 'package:little_light/services/storage/storage.service.dart';

class WishlistsService {
  static final WishlistsService _singleton = new WishlistsService._internal();
  StorageService storage = StorageService.global();
  factory WishlistsService() {
    return _singleton;
  }
  WishlistsService._internal();

  Map<int, WishlistItem> _items = Map();

  List<Wishlist> _wishlists;

  Set<String> _buildIds = Set();

  init() async {
    var items = await _loadPreParsed();
    this._wishlists = await _loadFromStorage(items == null);
    if(items != null){
      _items = items;
    }
    this._save();
    this.updateWishlists();
  }

  Future<Map<int, WishlistItem>> _loadPreParsed() async{
    Map<String, dynamic> json = await storage.getJson(StorageKeys.parsedWishlists);
    if(json == null) return null;
    var items = json.map<int, WishlistItem>((key, value) => MapEntry(int.parse(key), WishlistItem.fromJson(value)));
    return items;
  }

  Future<List<Wishlist>> _loadFromStorage(bool forceParse) async{
    List<dynamic> json = await storage.getJson(StorageKeys.wishlists);
    var wishlists = json != null
        ? json.map((item) => Wishlist.fromJson(item)).toList()
        : [Wishlist.defaults()];
    if(forceParse){
      wishlists = await _parseWishlists(wishlists);
    }
    return wishlists;
  }

  Future<void> updateWishlists() async{
    DateTime minimumDate = DateTime.now().subtract(Duration(days: 7));
    bool needsParsing = false;
    for(var wishlist in _wishlists){
      bool needUpdate = wishlist.updatedAt.isBefore(minimumDate);

      //TODO: remove this temporary fix to replace default wishlist to the tagged one
      if(wishlist.url == "https://raw.githubusercontent.com/48klocs/dim-wish-list-sources/master/voltron.txt"){
        wishlist.url = "https://raw.githubusercontent.com/LittleLightForDestiny/dim-wish-list-sources/master/voltron.txt";
        wishlist.isDefault = true;
        needUpdate = true;
      }

      if(needUpdate){
        await _downloadWishlist(wishlist);
      }
      needsParsing = needsParsing || needUpdate;
    }
    if(needsParsing){
      await _parseWishlists(_wishlists);
    }
  }

  List<Wishlist> getWishlists() {
    return _wishlists;
  }

  Future<List<Wishlist>> addWishlist(Wishlist wishlist) async {
    var existing =
        _wishlists.firstWhere((w) => w.url == wishlist.url, orElse: () => null);
    if (existing == null) {
      _wishlists.add(wishlist);
    } else {
      wishlist = existing;
    }
    var contents = await _downloadWishlist(wishlist);
    await _parseWishlist(wishlist, contents);
    this._save();
    return _wishlists;
  }

  Future<List<Wishlist>> removeWishlist(Wishlist wishlist) async {
    _wishlists.remove(wishlist);
    await storage.deleteFile(StorageKeys.rawWishlists, wishlist.filename);
    _items = Map();
    _wishlists = await _parseWishlists(_wishlists);
    this._save();
    return _wishlists;
  }

  Future<List<Wishlist>> _parseWishlists(List<Wishlist> wishlists) async {
    for (var wishlist in wishlists) {
      var filename = wishlist.filename;
      var contents =
          await storage.getRawFile(StorageKeys.rawWishlists, filename);
      if (contents == null) {
        contents = await _downloadWishlist(wishlist);
      }
      await _parseWishlist(wishlist, contents);
    }
    return wishlists;
  }

  Future<void> _parseWishlist(Wishlist wishlist, String contents) async {
    var parser = DimWishlistParser();
    parser.parse(contents);
  }

  Future<void> _save() async {
    var json = this._wishlists.map((w) => w.toJson()).toList();
    await storage.setJson(StorageKeys.wishlists, json);
    var parsed = this._items.map<String, dynamic>((k, v)=>MapEntry(k.toString(), v.toJson()));
    await storage.setJson(StorageKeys.parsedWishlists, parsed);
  }

  Future<String> _downloadWishlist(Wishlist wishlist) async {
    var res = await http.get(wishlist.url);
    storage.saveRawFile(StorageKeys.rawWishlists, wishlist.filename, res.body);
    wishlist.updatedAt = DateTime.now();
    return res.body;
  }

  Set<WishlistTag> getPerkTags(int itemHash, int plugItemHash) {
    var wishlist = _items[itemHash];
    if (wishlist?.perks == null) return Set();
    return _items[itemHash]?.perks[plugItemHash] ?? Set();
  }

  Set<WishlistTag> getWishlistBuildTags(DestinyItemComponent item) {
    if (item == null) return null;
    var reusable = ProfileService().getItemReusablePlugs(item.itemInstanceId);
    var sockets = ProfileService().getItemSockets(item.itemInstanceId);
    Set<int> availablePlugs = Set();
    reusable?.values?.forEach((plugs) =>
        plugs.forEach((plug) => availablePlugs.add(plug.plugItemHash)));
    sockets?.map((plug) => availablePlugs.add(plug.plugHash))?.toSet();
    if (availablePlugs?.length == 0) return null;
    var wish = _items[item?.itemHash];

    var builds = wish?.builds?.values?.where((build) {
      return availablePlugs.containsAll(build.perks);
    });
    if ((builds?.length ?? 0) == 0) return null;
    Set<WishlistTag> tags = Set();
    builds.forEach((b) {
      tags.addAll(b.tags);
    });
    return tags;
  }

  Set<String> getWishlistBuildNotes(DestinyItemComponent item) {
    if (item == null) return null;
    var reusable = ProfileService().getItemReusablePlugs(item.itemInstanceId);
    var sockets = ProfileService().getItemSockets(item.itemInstanceId);
    Set<int> availablePlugs = Set();
    reusable?.values?.forEach((plugs) =>
        plugs.forEach((plug) => availablePlugs.add(plug.plugItemHash)));
    sockets?.map((plug) => availablePlugs.add(plug.plugHash))?.toSet();
    if (availablePlugs?.length == 0) return null;
    var wish = _items[item?.itemHash];

    var builds = wish?.builds?.values?.where((build) {
      return availablePlugs.containsAll(build.perks);
    });
    if ((builds?.length ?? 0) == 0) return null;
    Set<String> notes = Set();
    builds.forEach((b) {
      notes.addAll(b.notes);
    });
    return notes;
  }

  addToWishList(
      int hash, List<int> perks, Set<WishlistTag> specialties, Set<String> notes) {
    perks?.sort();
    var buildId = perks.join('_');
    var wishlist =
        _items[hash] = _items[hash] ?? WishlistItem.builder(itemHash: hash);
    var build = wishlist.builds[buildId] = wishlist.builds[buildId] ??
        WishlistBuild.builder(identifier: buildId, perks: perks.toSet());
    build.notes.addAll(notes.where((n)=>(n?.length ?? 0) > 0));
    build.tags.addAll(specialties.where((s)=>s != null));
    for (var i in perks) {
      var perk = wishlist.perks[i] = wishlist.perks[i] ?? Set();
      perk.addAll(specialties);
    }
    _buildIds.add("$hash#$buildId");
  }
}