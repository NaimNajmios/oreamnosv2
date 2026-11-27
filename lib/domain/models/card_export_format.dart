enum CardExportFormat { png, jpeg }

extension CardExportFormatX on CardExportFormat {
  String get extension => switch (this) {
    CardExportFormat.png => 'png',
    CardExportFormat.jpeg => 'jpg',
  };

  String get label => switch (this) {
    CardExportFormat.png => 'PNG (lossless)',
    CardExportFormat.jpeg => 'JPEG (smaller)',
  };
}
