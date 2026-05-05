import 'package:flutter/widgets.dart';

/// Avoids framework asserts when the IME/route is still tearing down after
/// [showDialog] / [TextField] — dispose after the next frame.
void disposeTextControllerNextFrame(TextEditingController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
}
