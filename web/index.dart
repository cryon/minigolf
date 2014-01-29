import 'dart:html';
import 'dart:async';

import 'lib/application.dart';

void main() {
  final WebSocket socket = new WebSocket('ws://192.168.0.102:8080/ws');

  socket.onOpen.listen((_) {
    final Application app = new Application(socket);
    app.start();
  });
}


