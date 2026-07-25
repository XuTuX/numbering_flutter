import 'package:get/get.dart';

class SimulationMode {
  static final isEnabled = false.obs;
  static void toggle() => isEnabled.value = !isEnabled.value;
}
