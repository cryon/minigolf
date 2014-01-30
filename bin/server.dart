import 'dart:async';

import 'package:logging/logging.dart';
import 'package:force/force_serverside.dart';

import 'lib/playerdb.dart';
import 'lib/game.dart';

final Logger log = new Logger('Server');

void main() {
  // log to stdout
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) => print('${rec.level.name}: ${rec.time}: ${rec.message}'));

  PlayerDb playerDb = new PlayerDb();

  ForceServer fs = new ForceServer(port : 8080, startPage : 'index.html');
  fs.register(new Game(playerDb));
  fs.start();
}