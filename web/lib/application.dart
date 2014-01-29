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
  ServerProxy      _server;
  RegisterBox      _registrationBox;
  LoginBox         _loginBox;
  GameController   _controller;

  PlayerLocalStore _playerStore = new PlayerLocalStore();
  FlashBox         _flash = new FlashBox();
  ScoreBox         _scoreBox = new ScoreBox();

  Application(final WebSocket socket) {
    _server          = new ServerProxy(socket);
    _registrationBox = new RegisterBox(_server, _playerStore, _flash);
    _loginBox        = new LoginBox(_server, _playerStore, _flash);
    _controller      = new GameController(_server);
  }

  void start() {
    _setupTransitions();

    // if the player information is stored in local storage, login immediatly!
    _playerStore.getPlayerFromLocalStorage()
      .then((player) {
        if(player != null) {
          _server.login(player)
            .then((_) {
              _flash.info('Välkommen tillbaka ${player.handle}!');
              _controller.show();
            })
            .catchError((e) {
              _flash.error("Försökte logga in med informationen sparad i din enhet. Misslyckades!");

              // if the stored information is faulty somehow, purge the local store
              _playerStore.nuke().then((_) => _registrationBox.show());
            });
        } else {
          _registrationBox.show();
        }
     });
  }

  void _setupTransitions() {
    // start the game after registration is done
    _registrationBox.startGameTransition = () {
      _registrationBox.hide();
      _controller.show();
    };

    // start the game after login is done
    _loginBox.startGameTransition = () {
      _loginBox.hide();
      _controller.show();
    };

    // switch from registration to login
    _registrationBox.switchToLoginTransition = () {
      _registrationBox.hide();
      _loginBox.show();
    };

    // switch from login to registration
    _loginBox.switchToRegistrationTransition = () {
      _loginBox.hide();
      _registrationBox.show();
    };

    // show score after a game is done
    _controller.gameDoneTransition = () {
      _controller.hide();
      _scoreBox.position = _controller.position;
      _scoreBox.show();
    };

    // let a player start a new game
    _scoreBox.retryTransition = () {
      _scoreBox.hide();
      _controller.show();
    };

    // let a player logout
   _controller.logoutTransition = () {
      _controller.hide();
      _playerStore.nuke().then((_) => _loginBox.show());
    };
  }
}