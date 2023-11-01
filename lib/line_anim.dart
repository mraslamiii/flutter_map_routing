import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class EasyAnimationController {
  static var vsync = TestVSync();

  AnimationController? _animationController;

  void start({
   required double initialPortion,
   required double finishedPortion,
   required Duration animationDuration,
   required Curve animationCurve,
   required Function(double) onValueChange,
    void Function()? onFinish,
  }) {
    _animationController?.stop();
    _animationController?.dispose();
    _animationController =
        AnimationController(vsync: vsync, duration: animationDuration);

    var tween = Tween<double>(begin: initialPortion, end: finishedPortion);



    var animation =
    CurvedAnimation(parent: _animationController!, curve: animationCurve);

    _animationController?.addListener(() {
      onValueChange(tween.evaluate(animation));
    });

    _animationController?.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _animationController?.dispose();
        _animationController = null;
        (onFinish ?? () {})();
      }
    });
    _animationController?.forward();
  }

  void stop() {
    _animationController?.stop();
    _animationController?.dispose();
    _animationController = null;
  }

  bool get isAnimating => _animationController != null;
}