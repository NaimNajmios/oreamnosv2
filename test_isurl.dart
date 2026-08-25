// ignore_for_file: avoid_print
void main() {
  final text = 'https://www.espn.com/soccer/story/_/id/47288870/arsenal-mikel-arteta-critics-viktor-gyokeres';
  final uri = Uri.tryParse(text.trim());
  print('isUrl: ${uri != null && (uri.isScheme('http') || uri.isScheme('https'))}');
}

