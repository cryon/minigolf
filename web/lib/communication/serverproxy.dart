library serverproxy;

import 'dart:html';
import 'dart:convert';
import 'dart:async';

import '../vec2.dart';

import 'player.dart';
import 'protocolconstants.dart';

class ServerProxy {
  final WebSocket socket;

  ServerProxy(WebSocket this.socket);

  Future<bool> registerPlayer(final Player player) {
    return _serverMessage(REQUEST_REGISTRATION, player.values(), (int response, Map data, Completer completer) {
      switch(response) {
        case REGISTRATION_OK:
          completer.complete(true);
          break;
        case REGISTRATION_FAILED_EMAIL:
          completer.completeError('En användare finns redan registrerad med e-postadressen "${player.email}"');
          break;
        case REGISTRATION_FAILED_HANDLE:
          completer.completeError('En användare finns redan registrerad med användarnamnet "${player.handle}"');
          break;
        case REGISTRATION_FAILED_UNKNOWN:
          completer.completeError("Ett okänt fel inträffade vid registrering.");
          break;
      }
    });
  }

  Future<Player> login(final Player partialPlayer) {
    return _serverMessage(REQUEST_LOGIN, partialPlayer.values(), (int response, Map data, Completer completer) {
      switch(response) {
        case LOGIN_OK:
          completer.complete(new Player.fromValues(data));
          break;
        case LOGIN_FAILED:
          completer.completeError("Inloggningen mysslyckades. Dubbelkolla att du skrev rätt epost och lösenord!");
          break;
      }
    });
  }

  Future<bool> logout() {
    return _serverMessage(REQUEST_LOGOUT, null, (int response, Map data, Completer completer) {
      switch(response) {
        case LOGOUT_OK:
          completer.complete(true);
          break;
      }
    });
  }

  Future<int> shoot(final Vec2 v) {

    return _serverMessage(SHOOT, v.values, (int response, Map data, Completer completer) {
      switch(response) {
        case SHOOT_DONE:
          completer.complete(0);
          break;
        case GAME_COMPLETE:
          final int position = data['pos'];
          completer.complete(position);
          break;
      }
    });
  }

  Future _serverMessage(final int message, Map data, void responseHandler(int response, Map data, Completer completer)) {
     if(data == null) {
       data = {};
     }

     _sendServerMessage(message, data);
     final Completer completer = new Completer();
     final StreamSubscription subscription = socket.onMessage.listen(null);

     subscription.onData((event) {
       final Map data = JSON.decode(event.data);
       final int message = data['m'];

       Map payload = {};
       if(data['d'] != null) {
         payload = data['d'];
       }

       responseHandler(message, payload, completer);
       if(completer.isCompleted) {
          subscription.cancel();
       }
     });

     return completer.future;
  }

  String _sendServerMessage(final int message, Map values) {
    var messageMap = {
        'm' : message,
        'd' : values
    };

    final String json = JSON.encode(messageMap);
    socket.send(json);
  }
}
