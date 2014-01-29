library playerlocalstore;

import 'dart:convert';
import 'dart:async';

import 'package:lawndart/lawndart.dart';

import 'communication/player.dart';

class PlayerLocalStore {
  static const String DB_NAME = 'minigolf';
  static const String STORE_NAME = 'player';

  static const String PLAYER_KEY = 'player';

  final Store<String> _store = new Store(DB_NAME, STORE_NAME);

  Future savePlayerInLocalStorage(final Player player) {
    return _store.save(JSON.encode(player.values()), PLAYER_KEY);
  }

  Future<Player> getPlayerFromLocalStorage() {
    return _store.open()
      .then((_) => _store.getByKey(PLAYER_KEY))
      .then((playerJson) => new Player.fromValues(JSON.decode(playerJson)))
      .catchError((_)    => _store.nuke()
        .then((_)       => null)
        .catchError((_) => null));
  }

  Future nuke() {
    return _store.open()
      .then((_) => _store.nuke());
  }
}

