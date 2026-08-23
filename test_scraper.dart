import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://www.espn.com/soccer/story/_/id/47288870/arsenal-mikel-arteta-critics-viktor-gyokeres';
  print('Fetching: $url');
  
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }
    );
    print('Status: ${response.statusCode}');
    
    final document = parse(response.body);
    final articleElements = document.getElementsByTagName('article');
    if (articleElements.isNotEmpty) {
      print('Found article tag. Length: ${articleElements.first.text.length}');
      print(articleElements.first.text.substring(0, 100));
    } else {
      print('No article tag found.');
      final pElements = document.getElementsByTagName('p');
      print('Found ${pElements.length} p tags.');
    }
  } catch (e) {
    print('Error: $e');
  }
}

