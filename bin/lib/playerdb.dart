library playerdb;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:postgresql/postgresql_pool.dart';
import 'package:dbcrypt/dbcrypt.dart';

import '../../web/lib/communication/player.dart';

final Logger log = new Logger('PlayerStore');

String hashPassword(final String plainTextPassword) {
  return new DBCrypt().hashpw(plainTextPassword, new DBCrypt().gensalt());
}

class PlayerDb {
  static const String _CONNECTION_STRING = 'postgres://minigolf:golf@localhost:5432/minigolf';

  static const String _selectAllQuery = 'select id, handle, email, password from minigolf.users';
  static const String _selectPlayerFromEmailQuery = 'select * from minigolf.users where email = @email';
  static const String _selectPlayerFromHandleQuery = 'select * from minigolf.users where handle = @handle';
  static const String _insertPlayerQuery = 'insert into minigolf.users (handle, email, password) values (@handle, @email, @password)';

  var pool = new Pool(_CONNECTION_STRING, min: 2, max: 5);

  PlayerDb() {
    pool.start().then((_) {
      log.info('Connection pool started!');
    });
  }

  Future<bool> isHandleFree(final String handle) {
    return pool.connect().then((conn) {
      return conn.query(_selectPlayerFromHandleQuery, {'handle': handle}).toList()
          .then((result) {
            conn.close();
            return result.isEmpty;
          });
    }).catchError((e) {
      log.info("Error while checking if handle is free", e);
      return false;
    });
  }

  Future<bool> isEmailFree(final String email) {
    return pool.connect().then((conn) {
      return conn.query(_selectPlayerFromEmailQuery, {'email': email}).toList()
          .then((result) {
            conn.close();
            return result.isEmpty;
          });
    }).catchError((e) {
      log.info("Error while checking if email is free", e);
      return false;
    });
  }

  Future<bool> register(final Player player) {
    return pool.connect().then((conn) {
      Map playerValues = player.values;
      playerValues['password'] = hashPassword(playerValues['password']);

      conn.execute(_insertPlayerQuery, playerValues);
      conn.close();
      return true;
    }).catchError((e) {
      log.info("Error while registering player", e);
      return false;
    });
  }

  Future<Player> checkCredentials(final Player partialPlayer) {
    return pool.connect().then((conn) {
      return conn.query(_selectPlayerFromEmailQuery, {'email': partialPlayer.email}).toList()
        .then((rows){
          conn.close();

          if(rows.isEmpty) {
            return null;
          }

          if(new DBCrypt().checkpw(partialPlayer.password, rows[0].password)) {
            return new Player(rows[0].id, rows[0].handle, rows[0].email, '');
          } else {
            return null;
          }
        }).catchError((e) {
          log.info("Error while checking credentials", e);
          return false;
        });
    });
  }

  Future<List<Player>> getAllPlayers() {
    return pool.connect().then((conn) {
      return conn.query(_selectAllQuery).toList().then((rows) {
          conn.close();
          return rows.map((row) => new Player(row.id, row.handle, row.email, row.password));
      }).catchError((e) {
        log.info("Error while getting all players", e);
      });
    });
  }
}