library gamecontroller;

import 'dart:html';
import 'dart:math';

import '../communication/serverproxy.dart';
import '../vec2.dart';

import 'uibox.dart';

class GameController extends UiBox {
  static const int CIRCLE_RADIUS = 140;
  static const int BALL_RADIUS = 20;

  final ServerProxy server;
  final CanvasElement canvas;

  CanvasRenderingContext2D get context => canvas.context2D;

  final ButtonElement logoutButton = querySelector('#log-out');

  bool isAiming = false;
  bool waitingForServer = false;

  Vec2 ballPosition = new Vec2(0, 0);

  int position = 0;

  Transition gameDoneTransition = NOP_TRANSITION;
  Transition logoutTransition = NOP_TRANSITION;

  GameController(final String rootId, ServerProxy this.server)
      : canvas = querySelector('#controller-canvas'),
        super(rootId) {

    canvas
      ..onTouchStart.listen(onTouchStart)
      ..onTouchMove.listen(onTouchMove)
      ..onTouchEnd.listen(onTouchEnd);

    logoutButton.onClick.listen((_) => logoutTransition());
  }

  Vec2 get center => new Vec2(canvas.width / 2, canvas.height / 2);
  Point pointFromVector(final Vec2 v) => new Point(v.x, v.y);
  Vec2 vectorFromPoint(final Point p) => new Vec2(p.x, p.y);

  void onWindowResize() {
    canvas
      ..width =  window.innerWidth
      ..height = window.innerHeight;

    if(!isAiming) {
      ballPosition = center;
    }

    draw();
  }

  void draw() {
    clear();
    drawBackground();

    if(!waitingForServer) {
      drawBall();
    }
  }

  void clear() => context.clearRect(0, 0, canvas.width, canvas.height);

  void drawBackground() {
    final Vec2 c = center;

    const String guideColor = 'rgba(255, 255, 255, 0.2)';

    context
      // bounding cicle
      ..beginPath()
      ..arc(c.x, c.y, CIRCLE_RADIUS, 0, 2 * PI, false)
      ..fillStyle = 'rgba(0, 0, 0, ${waitingForServer ? 0.5 : 0.2})'
      ..lineWidth = 5
      ..strokeStyle = 'white'
      ..fill()
      ..stroke()

      // outer guide circle
      ..beginPath()
      ..arc(c.x, c.y, CIRCLE_RADIUS * 2/3, 0, 2 * PI, false)
      ..lineWidth = 1
      ..strokeStyle = guideColor
      ..stroke()

      // inner guide circle
      ..beginPath()
      ..arc(c.x, c.y, CIRCLE_RADIUS / 3, 0, 2 * PI, false)
      ..lineWidth = 1
      ..strokeStyle = guideColor
      ..stroke()

      // cross guide
      ..beginPath()
      ..lineWidth = 1
      ..strokeStyle = guideColor
      ..moveTo(c.x, c.y - CIRCLE_RADIUS)
      ..lineTo(c.x, c.y + CIRCLE_RADIUS)
      ..moveTo(c.x - CIRCLE_RADIUS, c.y)
      ..lineTo(c.x + CIRCLE_RADIUS, c.y)
      ..stroke();

      if(!waitingForServer) {
        context
          // center dot
          ..beginPath()
          ..arc(c.x, c.y, 4, 0, 2 * PI, false)
          ..fillStyle = 'rgba(255, 255, 255, 0.6)'
          ..fill()

          //line
          ..beginPath()
          ..moveTo(c.x, c.y)
          ..lineTo(ballPosition.x, ballPosition.y)
          ..lineWidth = 3
          ..strokeStyle = 'rgba(255, 255, 255, 0.6)'
          ..stroke();
      } else {
        context
        // waiting text
          ..fillStyle = 'white'
          ..font = '16px helvetica'
          ..textBaseline = 'middle'
          ..fillText('Väntar på servern!', c.x - 65, c.y);
      }

  }

  void drawBall() {
    final String color = isAiming ? 'rgba(255, 140, 0, 1)' : 'rgba(0, 0, 0, 0.2)';

    context
      ..beginPath()
      ..arc(ballPosition.x, ballPosition.y, BALL_RADIUS, 0, 2 * PI, false)
      ..fillStyle = color
      ..lineWidth = 3
      ..strokeStyle = 'white'
      ..fill()
      ..stroke();
  }

  void onTouchStart(final TouchEvent event) {
    event.preventDefault();

    final Vec2 touch = vectorFromPoint(event.touches[0].page);
    isAiming = touch.distanceTo(ballPosition) < BALL_RADIUS;
  }

  void onTouchMove(final TouchEvent event) {
    event.preventDefault();

    if(isAiming) {
      Vec2 touch = vectorFromPoint(event.touches[0].page);
      Vec2 c = center;

      // restrict the ball position within the bounding circle
      if(touch.distanceTo(c) < CIRCLE_RADIUS) {
        ballPosition = touch;
      } else {
        Vec2 direction = (touch - c).normalize();
        Vec2 position = direction * CIRCLE_RADIUS;
        ballPosition = c + position;
      }

      draw();
    }
  }

  void onTouchEnd(final TouchEvent event) {
    event.preventDefault();

    if(isAiming) {
      final Vec2 normalizedForce = (center - ballPosition).normalize();
      shoot(normalizedForce);
      isAiming = false;
    }
  }

  void shoot(final Vec2 force) {
    waitingForServer = true;
    draw();

    server.shoot(force).then((int pos) {
      if(pos != 0) {
        position = pos;
        gameDoneTransition();
      }

      reset();
    });
  }

  void reset() {
    isAiming = false;
    waitingForServer = false;

    ballPosition = center;
    draw();
  }
}
