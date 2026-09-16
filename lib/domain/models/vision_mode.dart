/// Vision extraction mode (Android OcrInputSheet parity).
enum VisionMode {
  auto,
  onDeviceOnly;

  static VisionMode fromString(String? value) {
    return VisionMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VisionMode.auto,
    );
  }
}
