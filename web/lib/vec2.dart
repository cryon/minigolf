library vector2d;

import 'dart:math';

class Vec2 {
  final num x;
  final num y;

  Vec2(num this.x, num this.y);
  Vec2.fromValues(final Map<String, num> v) : x = v['x'], y = v['y'];

  Map<String, num> get values => {'x' : x, 'y': y};

  operator +(final Vec2 o) => new Vec2(x + o.x, y + o.y);
  operator -(final Vec2 o) => new Vec2(x - o.x, y - o.y);
  operator *(final num scale)  => new Vec2(x * scale, y * scale);

  num get magnitude    => sqrt(x * x + y * y);
  Vec2 normalize() => this * (1 / magnitude);
  num distanceTo(final Vec2 o) => (o - this).magnitude;
}
