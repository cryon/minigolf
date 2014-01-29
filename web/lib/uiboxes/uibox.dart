library uibox;

import 'dart:html';

typedef void Transition();

abstract class UiBox {
  final DivElement div;

  UiBox(final String id)
      : div = querySelector(id) {

        window.onResize.listen((_) => onWindowResize());
        div.onClick.listen((_) => onClick());
      }

  show() {
    div.style.display = 'block';
    onWindowResize();
    onShow();
  }

  hide() {
    onHide();
    div.style.display = 'none';
  }

  void onWindowResize() {}
  void onClick() {}
  void onShow() {}
  void onHide() {}
}