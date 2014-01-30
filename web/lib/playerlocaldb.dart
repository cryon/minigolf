library playerlocaldb;

import 'dart:convert';
import 'dart:async';

import 'package:lawndart/lawndart.dart';

import 'communication/player.dart';

class PlayerLocalDb {
  static const String DB_NAME    = 'minigolf';
  static const String STORE_NAME = 'player';
  static const String PLAYER_KEY = 'player';

  final Store<String> store = new Store(DB_NAME, STORE_NAME);

  Future save(final Player p) => store.open().then((_) => store.save(JSON.encode(p.values), PLAYER_KEY));

  Future<Player> load() {
    return store.open()
        .then((_) => store.getByKey(PLAYER_KEY))
        .then((json) => new Player.fromValues(JSON.decode(json)))
        .catchError((_)    => nuke()
            .then((_)       => null)
            .catchError((_) => null));
  }

  Future nuke() => store.open()
      .then((_) => store.nuke());
}

