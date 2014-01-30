library application;

import 'uiboxes/flashbox.dart';
import 'uiboxes/registerbox.dart';
import 'uiboxes/loginbox.dart';
import 'uiboxes/scorebox.dart';
import 'communication/serverproxy.dart';
import 'uiboxes/gamecontroller.dart';
import 'playerlocaldb.dart';

import 'uiboxes/uibox.dart';

class Application {
  RegisterBox      registrationBox;
  LoginBox         loginBox;
  GameController   controller;

  ServerProxy      server      = new ServerProxy();
  PlayerLocalDb    playerDb    = new PlayerLocalDb();
  FlashBox         flash       = new FlashBox('#flash');
  ScoreBox         scoreBox    = new ScoreBox('#score-box');

  Application() {
    registrationBox = new RegisterBox('#register-box', server, playerDb, flash);
    loginBox        = new LoginBox('#login-box', server, playerDb, flash);
    controller      = new GameController('#controller-box', server);
  }

  void start() {
    _setupTransitions();

    // if the player information is stored in local storage, login immediatly!
    playerDb.load()
      .then((player) {
        if(player != null) {
          server.login(player)
            .then((_) {
              flash.info('Välkommen tillbaka, ${player.handle}!');
              controller.show();
            })
            .catchError((e) {
              flash.error("Försökte logga in med informationen sparad i din enhet. Misslyckades!");
              playerDb.nuke().then((_) => registrationBox.show());
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

      playerDb.nuke().then((_) =>
        server.logout().then((_) =>
          loginBox.show()));
    };
  }
}