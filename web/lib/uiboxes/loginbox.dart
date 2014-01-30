library loginbox;

import 'dart:html';

import 'uibox.dart';

import '../communication/serverproxy.dart';
import '../playerlocaldb.dart';
import '../communication/player.dart';
import '../uiboxes/flashbox.dart';

class LoginBox extends UiBox {
  final FormElement   loginForm     = querySelector('#login-form');
  final InputElement  emailInput    = querySelector('#login-email');
  final InputElement  passwordInput = querySelector('#login-password');
  final ButtonElement loginButton   = querySelector('#login-submit');
  final AnchorElement registerLink  = querySelector('#register-switch');

  final FlashBox flash;
  final ServerProxy server;

  Transition startGameTransition = NOP_TRANSITION;
  Transition switchToRegistrationTransition = NOP_TRANSITION;

  LoginBox(final String rootId, ServerProxy this.server, final PlayerLocalDb playerDb, FlashBox this.flash)
      : super(rootId) {

    registerLink.onClick.listen((event) {
      event.preventDefault();

      switchToRegistrationTransition();
    });

    loginButton.onClick.listen((_) {
      if(!loginForm.checkValidity()) {
        return;
      }

      final Player partialPlayer = new Player(0, '', emailInput.value, passwordInput.value);
      server.login(partialPlayer)
        .then((p) {
          // save password
          final Map tmp = p.values;
          tmp[Player.PASSWORD_KEY] = partialPlayer.password;
          final Player player = new Player.fromValues(tmp);

          playerDb.save(player)
            .then((_) {
              flash.info("Välkommen tillbaka, ${player.handle}!");
              startGameTransition();
            })
            .catchError((e) {
              flash.error("Välkommen tillbaka, ${player.handle}! (Det gick inte att spara användarinformation lokalt på din enhet)");
              startGameTransition();
            });
      })
      .catchError((e) => flash.error(e.toString()));
    });
  }
}