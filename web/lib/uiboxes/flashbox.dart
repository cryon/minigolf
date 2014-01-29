library flashbox;

import 'dart:html';

import 'package:css_animation/css_animation.dart';

import 'uibox.dart';

class FlashBox extends UiBox {
  FlashBox(final String rootId)
      : super(rootId);

  void info(final String text) {
    div.text = text;
    div.classes.remove('error');
    div.classes.add('info');
    show();
  }

  void error(final String text) {
    div.text = text;
    div.classes.remove('info');
    div.classes.add('error');
    show();
  }

  void onShow() {
    div.style.opacity = '1';
    final CssAnimation animation = new CssAnimation('opacity', 1, 0);
    animation.apply(div, duration: 1000, delay: 1000);
  }

  void onClick() {
    hide();
  }

  void onWindowResize() {
    final num newLeft = (window.innerWidth / 2) - (div.clientWidth / 2);
    div.style.left = '${newLeft.toInt()}px';
  }
}