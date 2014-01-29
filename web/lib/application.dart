library application;

import 'dart:html';

import 'uiboxes/flashbox.dart';
import 'uiboxes/registerbox.dart';
import 'uiboxes/loginbox.dart';
import 'uiboxes/scorebox.dart';
import 'communication/serverproxy.dart';
import 'uiboxes/gamecontroller.dart';
import 'playerlocalstore.dart';

import 'uiboxes/uibox.dart';

class Application {
  ServerProxy      server;
  RegisterBox      registrationBox;
  LoginBox         loginBox;
  GameController   controller;

  PlayerLocalStore playerStore = new PlayerLocalStore();
  FlashBox         flash = new FlashBox('#flash');
  ScoreBox         scoreBox = new ScoreBox('#score-box');

  Application(final WebSocket socket) {
    server          = new ServerProxy(socket);
    registrationBox = new RegisterBox('#register-box', server, playerStore, flash);
    loginBox        = new LoginBox('#login-box', server, playerStore, flash);
    controller      = new GameController('#controller-box', server);
  }

  void start() {
    _setupTransitions();

    // if the player information is stored in local storage, login immediatly!
    playerStore.getPlayerFromLocalStorage()
      .then((player) {
        if(player != null) {
          server.login(player)
            .then((_) {
              flash.info('Välkommen tillbaka ${player.handle}!');
              controller.show();
            })
            .catchError((e) {
              flash.error("Försökte logga in med informationen sparad i din enhet. Misslyckades!");

              // if the stored information is faulty somehow, purge the local store
              playerStore.nuke().then((_) => registrationBox.show());
            });
        } else {
          registrationBox.show();
        }
     });
  }

  void _setupTransitions() {
    // start the game after registration is done
    registrationBox.startGameTransition = () {
      registrationBox.hide();
      controller.show();
    };

    // start the game after login is done
    loginBox.startGameTransition = () {
      loginBox.hide();
      controller.show();
    };

    // switch from registration to login
    registrationBox.switchToLoginTransition = () {
      registrationBox.hide();
      loginBox.show();
    };

    // switch from login to registration
    loginBox.switchToRegistrationTransition = () {
      loginBox.hide();
      registrationBox.show();
    };

    // show score after a game is done
    controller.gameDoneTransition = () {
      controller.hide();
      scoreBox.position = controller.position;
      scoreBox.show();
    };

    // let a player start a new game
    scoreBox.retryTransition = () {
      scoreBox.hide();
      controller.show();
    };

    // let a player logout
   controller.logoutTransition = () {
      controller.hide();
      playerStore.nuke().then((_) => loginBox.show());
    };
  }
}