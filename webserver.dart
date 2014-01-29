import 'dart:io';

import 'package:route/server.dart';
import 'package:http_server/http_server.dart';

import 'package:logging/logging.dart';

final Logger log = new Logger('Webserver');

final InternetAddress address = InternetAddress.ANY_IP_V4;
const int port = 8080;
final String documentRootPath = Platform.script.resolve('web/').toFilePath();

void startServer(websocketHandler) {
  log.info('Starting server...');
  HttpServer.bind(address, port).then((final HttpServer server) {
      final Router router = new Router(server);

      log.info('Serving static files from \'${documentRootPath}\'');
      final VirtualDirectory virtualDirectory = new VirtualDirectory(documentRootPath);

      // pub packages used by the client are provided as symlinks leading outside the root
      // i don't like it.
      virtualDirectory.jailRoot = false;

      // resolve directories to dir/index.html
      virtualDirectory.allowDirectoryListing = true;
      virtualDirectory.directoryHandler = (final Directory dir, final HttpRequest request) {
        final Uri indexUri = new Uri.file(dir.path).resolve('index.html');
        virtualDirectory.serveFile(new File(indexUri.toFilePath()), request);
      };

      // serve content
      virtualDirectory.serve(router.defaultStream);

      // upgrade websockets
      router.serve('/ws').transform(new WebSocketTransformer()).listen(websocketHandler);

      // log errors
      virtualDirectory.errorPageHandler = (final HttpRequest request) {
        final response = request.response;
        log.warning('Error ${response.statusCode} for \'${request.uri.path}\'');
        response.close();
      };

      log.info('Server started at ${address.address}:${port}');
  });
}