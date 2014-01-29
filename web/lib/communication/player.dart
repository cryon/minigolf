library player;

class Player {
  static const String ID_KEY       = 'id';
  static const String HANDLE_KEY   = 'handle';
  static const String EMAIL_KEY    = 'email';
  static const String PASSWORD_KEY = 'password';

  final int id;
  final String handle;
  final String email;
  final String password;

  Player(int this.id, String this.handle, String this.email, String this.password);

  Player.fromValues(final Map values)
      : id = values[ID_KEY],
        email = values[EMAIL_KEY],
        handle = values[HANDLE_KEY],
        password = values[PASSWORD_KEY];

  Map<String, String> values() {
    return {
      ID_KEY       : id,
      HANDLE_KEY   : handle,
      EMAIL_KEY    : email,
      PASSWORD_KEY : password
    };
  }
}
