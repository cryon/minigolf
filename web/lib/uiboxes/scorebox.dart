library scorebox;

import 'dart:html';

import 'uibox.dart';

class ScoreBox extends UiBox {

  final SpanElement _scoreSpan = querySelector('#score-position');
  final ButtonElement retryButton = querySelector('#replay-button');

  ScoreBox(final String rootId)
      : super(rootId);

  void set position(final int position) {
    _scoreSpan.text = position.toString();
  }

  void set retryTransition(final Transition retryTransition) {
    retryButton.onClick.listen((_) => retryTransition());
  }
}