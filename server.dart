import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';

import 'playerbackendstore.dart' as PS;
import 'web/lib/communication/player.dart' as P;
import 'web/lib/communication/protocolconstants.dart';

import 'webserver.dart' as WS;

final Logger log = new Logger('Server');

final PS.PlayerStore playerStore = new PS.PlayerStore();

void clientMessage(final WebSocket socket, final int message, [Map values]) {
  if(values == null) {
    values = {};
  }

  var messageMap = {
    'm': message,
    'd': values
  };

  final String json = JSON.encode(messageMap);
  socket.add(json);
}

void handleRegistration(final WebSocket socket, final Map messageData) {
  final String email = messageData[P.Player.EMAIL_KEY];
  final String handle = messageData[P.Player.HANDLE_KEY];
  final String password = messageData[P.Player.PASSWORD_KEY];

  log.info('A user (handle: ${handle}, email: ${email}) requests registration...');

  playerStore.isEmailFree(email).then((final bool emailFree) {
    if(!emailFree) {
      log.info('A user (handle: ${handle}, email: ${email}) failed to register (duplicate email).');
      clientMessage(socket, REGISTRATION_FAILED_EMAIL);
      return;
    }

    playerStore.isHandleFree(handle).then((final bool handleFree) {
      if(!handleFree) {
        log.info('A user (handle: ${handle}, email: ${email}) failed to register (duplicate handle).');
        clientMessage(socket, REGISTRATION_FAILED_HANDLE);
        return;
      }

      final P.Player player = new P.Player(-1, handle, email, password);
      playerStore.register(player).then((final bool registered) {
        if(!registered) {
          log.info('A user (handle: ${handle}, email: ${email}) failed to register (unknown error).');
          clientMessage(socket, REGISTRATION_FAILED_UNKNOWN);
          return;
        }

        log.info('User (handle: ${handle}, email: ${email}) successfully registered!');
        clientMessage(socket, REGISTRATION_OK);
      });
    });
  });
}

void handleLogin(final WebSocket socket, Map data) {
  final P.Player partialPlayer = new P.Player.fromValues(data);
  playerStore.checkCredentials(partialPlayer).then((player) {
    if(player != null) {
      log.info('User (handle: ${player.handle}, email: ${player.email}) logged in!');
      clientMessage(socket, LOGIN_OK, player.values());
    } else {
      log.info('User (email: ${partialPlayer.email}) failed to login!');
      clientMessage(socket, LOGIN_FAILED);
    }
  });
}

// test code
void handleShot(final WebSocket socket, Map data) {
  // ignoring the actual data for testing...
  new Timer(new Duration(seconds: 1), () {
    var r = new Random();
    if(2 == r.nextInt(3)) {
      Map map = {'pos' : r.nextInt(10)};
      clientMessage(socket, GAME_COMPLETE, map);
    } else {
      clientMessage(socket, SHOOT_DONE);
    }
  });
}

void handleLogout(final WebSocket socket, Map data) {
  clientMessage(socket, LOGOUT_OK);
}

String filterPasswordFromJsonStringNaive(final String input) {
  // will fuck up if a user's password contains '}'
  return input.replaceAll(new RegExp(r'password:[^\}]*'), 'password: ...');
}

void handleWebsocket(final WebSocket socket) {
  log.info('New websocket client... ');

  socket.listen((jsonData) {
    final Map data = JSON.decode(jsonData);
    log.info('Revieved message: ${filterPasswordFromJsonStringNaive(data.toString())}');

    final int message = data['m'];
    final Map messageData = data['d'];

    switch(message) {
      case REQUEST_REGISTRATION:
        handleRegistration(socket, messageData);
        break;
      case REQUEST_LOGIN:
        handleLogin(socket, messageData);
        break;
      case SHOOT:
        handleShot(socket, messageData);
        break;
      case REQUEST_LOGOUT:
        handleLogout(socket, messageData);
        break;
    }

  }, onError: (error) {
    log.severe ('Got error: ${error}');
  }, onDone: () {
    log.info ('on done');
  }, cancelOnError: false);
}

void main() {
  // configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((final LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  WS.startServer(handleWebsocket);
}
