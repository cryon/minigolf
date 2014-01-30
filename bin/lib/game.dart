library game;

import 'dart:math';
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:force/force_serverside.dart';

import 'playerdb.dart';
import '../../web/lib/communication/protocolconstants.dart';
import '../../web/lib/communication/player.dart';

final Logger log = new Logger('Game');

class Game {
  final PlayerDb playerDb;

  Game(this.playerDb);

  @Receiver(REQUEST_REGISTRATION)
  void onRequestRegistration(e, s) {
    var p = new Player.fromValues(e.json);

    log.info('A user (handle: ${p.handle}, email: ${p.email}) requests registration...');

    playerDb.isEmailFree(p.email).then((emailFree) {
      if(!emailFree) {
        log.info('A user (handle: ${p.handle}, email: ${p.email}) failed to register (duplicate email).');
        s.send(REGISTRATION_FAILED_EMAIL, {});
        return;
      }

      playerDb.isHandleFree(p.handle).then((handleFree) {
        if(!handleFree) {
          log.info('A user (handle: ${p.handle}, email: ${p.email}) failed to register (duplicate handle).');
          s.send(REGISTRATION_FAILED_HANDLE, {});
          return;
        }

        playerDb.register(p).then((registered) {
          if(!registered) {
            log.info('A user (handle: ${p.handle}, email: ${p.email}) failed to register (unknown error).');
            s.send(REGISTRATION_FAILED_UNKNOWN, {});
            return;
          }

          log.info('User (handle: ${p.handle}, email: ${p.email}) successfully registered!');
          s.send(REGISTRATION_OK, {});
        });
      });
    });
  }

  @Receiver(REQUEST_LOGIN)
  void onRequestLogin(e, s) {
    var partial = new Player.fromValues(e.json);
    playerDb.checkCredentials(partial).then((player) {
      if(player != null) {
        log.info('User (handle: ${player.handle}, email: ${player.email}) logged in!');
        s.send(LOGIN_OK, player.values);
      } else {
        log.info('User (email: ${partial.email}) failed to login!');
        s.send(LOGIN_FAILED, {});
      }
    });
  }

  @Receiver(REQUEST_LOGOUT)
  void onRequestLogout(e, s) => s.send(LOGOUT_OK, {});

  @Receiver(SHOOT)
  void onShoot(e, s) {
    // ignoring the actual data for testing...
    new Timer(new Duration(seconds: 1), () {
      var r = new Random();
      if(2 == r.nextInt(3)) {
        Map map = {'pos' : r.nextInt(10)};
        s.send(GAME_COMPLETE, map);
      } else {
        s.send(SHOOT_DONE, {});
      }
    });
  }
}