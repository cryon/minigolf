library scorebox;

import 'dart:html';

import 'uibox.dart';

class ScoreBox extends UiBox {

  final SpanElement _scoreSpan = querySelector('#score-position');
  final ButtonElement _retryButton = querySelector('#replay-button');

  ScoreBox()
      : super('#score-box');

  void set position(final int position) {
    _scoreSpan.text = position.toString();
  }

  void set retryTransition(void retryTransition()) {
    _retryButton.onClick.listen((_) => retryTransition());
  }
}