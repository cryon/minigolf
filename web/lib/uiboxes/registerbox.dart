library registerbox;

import 'dart:html';

import 'uibox.dart';

import '../communication/serverproxy.dart';
import '../playerlocalstore.dart';
import '../communication/player.dart';
import '../uiboxes/flashbox.dart';

class RegisterBox extends UiBox {
  final FormElement   registerForm   = querySelector('#register-form');
  final InputElement  handleInput    = querySelector('#register-name');
  final InputElement  emailInput     = querySelector('#register-email');
  final InputElement  passwordInput  = querySelector('#register-password');
  final ButtonElement registerButton = querySelector('#register-submit');
  final AnchorElement loginLink      = querySelector('#login-switch');

  final FlashBox flash;
  final ServerProxy server;

  Transition startGameTransition;
  Transition switchToLoginTransition;

  RegisterBox(final String rootId, ServerProxy this.server, final PlayerLocalStore playerStore, FlashBox this.flash)
      : super(rootId) {

    loginLink.onClick.listen((event) {
      event.preventDefault();

      switchToLoginTransition();
    });

    registerButton.onClick.listen((_) {
      if(!registerForm.checkValidity()) {
        return;
      }

      final Player player = new Player(0, handleInput.value, emailInput.value, passwordInput.value);
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