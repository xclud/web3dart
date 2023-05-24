import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final client = HttpClient();
  const lintUrl =
      'https://raw.githubusercontent.com/dart-lang/linter/gh-pages/lints/machine/rules.json';
  final lints = await client
      .getUrl(Uri.parse(lintUrl))
      .then((request) => request.close())
      .then(
        (response) =>
    response.transform(utf8.decoder).transform(json.decoder).first,
  )
      .then((list) => (list as List).cast<Map>());
  final sb = StringBuffer('linter:\n  rules:\n');
  for (final lint in lints) {
    sb.write('    # ');
    sb.write('[ ');
    sb.write(lint['group']);
    sb.write('/');
    sb.write(lint['state']);
    sb.write(' ] ');
    sb.writeln(lint['description']);
    if (lint['state'] == 'removed') {
      sb.write('    # - ');
    } else {
      sb.write('    - ');
    }
    sb.writeln(lint['name']);
    sb.writeln();
  }
  File('${Directory.current.path}/all_lint_rules.yaml').writeAsStringSync(sb.toString());
}
