library serverproxy;

import 'dart:async';

import 'package:force/force_browser.dart';

import '../vec2.dart';
import 'player.dart';
import 'protocolconstants.dart';

typedef void ResponseHandler(final int response, final Map data, final Completer completer);

class ServerProxy {
  ForceClient fc = new ForceClient();

  ServerProxy() {
   fc.connect();
  }

  Future register(final Player p) {
    var c = new Completer();

    fc.on(REGISTRATION_OK, (e, s) => c.complete());
    fc.on(REGISTRATION_FAILED_EMAIL, (e, s) => c.completeError('En användare finns redan registrerad med e-postadressen "${p.email}"'));
    fc.on(REGISTRATION_FAILED_HANDLE, (e, s) => c.completeError('En användare finns redan registrerad med användarnamnet "${p.handle}"'));
    fc.on(REGISTRATION_FAILED_UNKNOWN, (e, s) => c.completeError('Ett okänt fel inträffade vid registrering.'));
    fc.send(REQUEST_REGISTRATION, p.values);

    return c.future;
  }

  Future<Player> login(final Player partial) {
    var c = new Completer();

    fc.on(LOGIN_OK, (e, s) => c.complete(new Player.fromValues(e.json)));
    fc.on(LOGIN_FAILED, (e, s) => c.completeError('Inloggningen mysslyckades. Dubbelkolla att du skrev rätt epost och lösenord!'));
    fc.send(REQUEST_LOGIN, partial.values);

    return c.future;
  }

  Future logout() {
    var c = new Completer();

    fc.send(REQUEST_LOGOUT, {});
    c.complete();

    return c.future;
  }

  Future<int> shoot(final Vec2 v) {
    var c = new Completer();

    fc.on(SHOOT_DONE, (e, s) => c.complete(0));
    fc.on(GAME_COMPLETE, (e, s) => c.complete(e.json['pos']));
    fc.send(SHOOT, v.values);

    return c.future;
  }
}
