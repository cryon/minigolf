library registerbox;

import 'dart:html';

import 'uibox.dart';

import '../communication/serverproxy.dart';
import '../playerlocalstore.dart';
import '../communication/player.dart';
import '../uiboxes/flashbox.dart';

class RegisterBox extends UiBox {
  final FormElement   _registerForm   = querySelector('#register-form');
  final InputElement  _handleInput    = querySelector('#register-name');
  final InputElement  _emailInput     = querySelector('#register-email');
  final InputElement  _passwordInput  = querySelector('#register-password');
  final ButtonElement _registerButton = querySelector('#register-submit');
  final AnchorElement _loginLink      = querySelector('#login-switch');

  final FlashBox flash;
  final ServerProxy server;

  Transition startGameTransition;
  Transition switchToLoginTransition;

  RegisterBox(final String rootId, ServerProxy this.server, final PlayerLocalStore playerStore, FlashBox this.flash)
      : super(rootId) {

    _loginLink.onClick.listen((event) {
      event.preventDefault();

      switchToLoginTransition();
    });

    _registerButton.onClick.listen((_) {
      if(!_registerForm.checkValidity()) {
        return;
      }

      final Player player = new Player(0, _handleInput.value, _emailInput.value, _passwordInput.value);
      server.registerPlayer(player)
        .then((_){
          playerStore.savePlayerInLocalStorage(player)
            .then((_) {
              flash.info("Du är nu registrerad och kan börja spela!");
              startGameTransition();
            })
            .catchError((e) {
              flash.error("Du är nu registrerad, men din användarinformation kunde inte sparas på din enhet. Du måste logga in manuellt om du vill spela igen.");
              startGameTransition();
            });
      })
      .catchError((e) => flash.error(e));
    });
  }


}