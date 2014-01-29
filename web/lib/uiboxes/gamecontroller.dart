library gamecontroller;

import 'dart:html';
import 'dart:math';

import '../communication/serverproxy.dart';

import 'uibox.dart';

class GameController extends UiBox {
  static const int BOUNDING_CIRCLE_RADIUS = 140;
  static const int BOUNDING_CIRCLE_RADIUS_SQUARED = BOUNDING_CIRCLE_RADIUS * BOUNDING_CIRCLE_RADIUS;

  // golf ball
  static const int BALL_RADIUS = 20;
  static const int BALL_RADIUS_SQUARED = BALL_RADIUS * BALL_RADIUS;

  final ServerProxy _server;
  final CanvasElement _canvas;
  CanvasRenderingContext2D _context;

  final ButtonElement _logoutButton = querySelector('#log-out');

  bool _draggingBall = false;
  bool _waitingForServer = false;
  Point _ballPos = new Point(0, 0);

  // transitions
  var gameDoneTransition;
  var logoutTransition;

  GameController(final ServerProxy server)
      : _canvas = querySelector('#controller-canvas'),
        _server = server,
        super('#controller-box') {
    _context = _canvas.context2D;

    _canvas
      ..onTouchStart.listen((event) => onTouchStart(event))
      ..onTouchMove.listen((event)  => onTouchMove(event))
      ..onTouchEnd.listen((event)   => onTouchEnd(event));

      _canvas.onTouchCancel.listen((event) {
        event.preventDefault();
        return false;
      });

    _logoutButton.onClick.listen((_) {
      logoutTransition();
    });
  }

  void onWindowResize() {
    final int w = window.innerWidth;
    final int h = window.innerHeight;

    _canvas
      ..width =  w
      ..height = h;

    if(!_draggingBall) {
      _ballPos = _getCenter();
    }

    _draw();
  }

  void onShow() {
    onWindowResize();
  }

  void _draw() {
    _clear();
    _drawBackground();

    if(!_waitingForServer) {
      _drawBall();
    }
  }

  void _clear() {
    _context.clearRect(0, 0, _canvas.width, _canvas.height);
  }

  void _drawBackground() {
    final Point center = _getCenter();

    _context
      ..beginPath()
      ..arc(center.x, center.y, BOUNDING_CIRCLE_RADIUS, 0, 2 * PI, false)
      ..fillStyle = 'rgba(0, 0, 0, ${_waitingForServer ? 0.5 : 0.2})'
      ..lineWidth = 5
      ..strokeStyle = 'rgba(255, 255, 255, 0.8)'
      ..fill()
      ..stroke()

      ..beginPath()
      ..arc(center.x, center.y, BOUNDING_CIRCLE_RADIUS / 3, 0, 2 * PI, false)
      ..lineWidth = 1
      ..strokeStyle = 'rgba(255, 255, 255, 0.2)'
      ..stroke()

      ..beginPath()
      ..arc(center.x, center.y, BOUNDING_CIRCLE_RADIUS * 2/3, 0, 2 * PI, false)
      ..lineWidth = 1
      ..strokeStyle = 'rgba(255, 255, 255, 0.2)'
      ..stroke()

      // cross
      ..beginPath()
      ..moveTo(center.x, center.y - BOUNDING_CIRCLE_RADIUS)
      ..lineTo(center.x, center.y + BOUNDING_CIRCLE_RADIUS)
      ..lineWidth = 1
      ..strokeStyle = 'rgba(255, 255, 255, 0.2)'
      ..moveTo(center.x - BOUNDING_CIRCLE_RADIUS, center.y)
      ..lineTo(center.x + BOUNDING_CIRCLE_RADIUS, center.y)
      ..lineWidth = 1
      ..strokeStyle = 'rgba(255, 255, 255, 0.2)'
      ..stroke();

      if(!_waitingForServer) {
        _context
          // center dot
          ..beginPath()
          ..arc(center.x, center.y, 4, 0, 2 * PI, false)
          ..fillStyle = 'rgba(255, 255, 255, 0.6)'
          ..fill()

          //line
          ..beginPath()
          ..moveTo(center.x, center.y)
          ..lineTo(_ballPos.x, _ballPos.y)
          ..lineWidth = 3
          ..strokeStyle = 'rgba(255, 255, 255, 0.6)'
          ..stroke();
      } else {
        _context
        // waiting text
          ..fillStyle = 'white'
          ..font = '16px helvetica'
          ..textBaseline = 'middle'
          ..fillText('Väntar på servern!', center.x-65, center.y);
      }

  }

  void _drawBall() {
    final num x = _ballPos.x;
    final num y = _ballPos.y;

    String color;
    if(_draggingBall) {
      color = 'rgba(255, 140, 0, 1)';
    } else {
      color = 'rgba(0, 0, 0, 0.2)';
    }

    _context
      ..moveTo(x, y)
      ..beginPath()
      ..arc(x, y, BALL_RADIUS, 0, 2 * PI, false)
      ..fillStyle = color
      ..lineWidth = 3
      ..strokeStyle = 'white'
      ..fill()
      ..stroke();
  }

  void onTouchStart(final TouchEvent event) {
    event.preventDefault();

    final Point touchPos = event.touches[0].page;
    if(touchPos.squaredDistanceTo(_ballPos) < BALL_RADIUS_SQUARED) {
      _draggingBall = true;
    }
  }

  void onTouchMove(final TouchEvent event) {
    event.preventDefault();

    if(_draggingBall) {
      final Point touchPos = event.touches[0].page;
      final Point centerPos = _getCenter();

      // restrict the ball position within the bounding circle
      if(touchPos.squaredDistanceTo(centerPos) < BOUNDING_CIRCLE_RADIUS_SQUARED) {
        _ballPos = touchPos;
      } else {
        final Point centerToTouch = _vectorSubtract(touchPos, centerPos);
        final Point origoToBall = _scale(_normalize(centerToTouch), BOUNDING_CIRCLE_RADIUS);
        _ballPos = _vectorAdd(centerPos, origoToBall);
      }

      _draw();
    }
  }

  void onTouchEnd(final TouchEvent event) {
    event.preventDefault();

    if(_draggingBall) {
      final Point centerPos = _getCenter();

      final Point force = _vectorSubtract(centerPos, _ballPos);
      final Point scaledForce = _scale(force, 1/BOUNDING_CIRCLE_RADIUS);

      _shoot(scaledForce);

      _draggingBall = false;
    }
  }

  void _shoot(final Point force) {
    _server.shoot(force).then((int pos) {
      // ordinary shot
      if(pos == 0) {
        _reset();
      } else {
        gameDoneTransition(pos);
        _reset();
      }
    });

    _waitingForServer = true;
    _draw();
  }

  void _reset() {
    _draggingBall = false;
    _waitingForServer = false;

    _ballPos = _getCenter();
    _draw();
  }

  Point _getCenter() {
    return new Point(_canvas.width / 2, _canvas.height / 2);
  }

  Point _scale(final Point p, num n) {
    return new Point(p.x * n, p.y * n);
  }

  Point _normalize(final Point p) {
    final num m = p.magnitude;
    return new Point(p.x/m, p.y/m);
  }

  Point _vectorSubtract(final Point p1, final Point p2) {
    return new Point(p1.x - p2.x, p1.y - p2.y);
  }

  Point _vectorAdd(final Point p1, final Point p2) {
    return new Point(p1.x + p2.x, p1.y + p2.y);
  }
}
