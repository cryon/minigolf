library loginbox;

import 'dart:html';

import 'uibox.dart';

import '../communication/serverproxy.dart';
import '../playerlocalstore.dart';
import '../communication/player.dart';
import '../uiboxes/flashbox.dart';

class LoginBox extends UiBox {
  final FormElement   _loginForm     = querySelector('#login-form');
  final InputElement  _emailInput    = querySelector('#login-email');
  final InputElement  _passwordInput = querySelector('#login-password');
  final ButtonElement _loginButton   = querySelector('#login-submit');
  final AnchorElement _registerLink  = querySelector('#register-switch');

  final FlashBox _flash;
  final ServerProxy _server;

  // transitions
  var startGameTransition;
  var switchToRegistrationTransition;

  LoginBox(final ServerProxy server, final PlayerLocalStore playerStore, final FlashBox flash)
      : super('#login-box'),
        _server = server,
        _flash = flash {

    _registerLink.onClick.listen((event) {
      event.preventDefault();

      switchToRegistrationTransition();
    });

    _loginButton.onClick.listen((_) {
      if(!_loginForm.checkValidity()) {
        return;
      }

      final Player partialPlayer = new Player(0, '', _emailInput.value, _passwordInput.value);
      server.login(partialPlayer)
        .then((p) {
          // save password
          final Map tmp = p.values();
          tmp[Player.PASSWORD_KEY] = partialPlayer.password;
          final Player player = new Player.fromValues(tmp);

          playerStore.savePlayerInLocalStorage(player)
            .then((_) {
              _flash.info("Välkommen tillbaka, ${player.handle}!");
              startGameTransition();
            })
            .catchError((e) {
              _flash.error("Välkommen tillbaka, ${player.handle}! (Det gick inte att spara användarinformation lokalt på din enhet)");
              startGameTransition();
            });
      })
      .catchError((e) => _flash.error(e.toString()));
    });
  }
}