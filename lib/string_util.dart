import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String convertToIdr(String number, int decimalDigit) {
  NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp. ',
    decimalDigits: decimalDigit,
  );
  return currencyFormatter.format(int.parse(number));
}

Future<String> loadJson() async {
  String text = await rootBundle.loadString('assets/translate.json');
  return text;
}

Future<String> translate(String key) async {
  String jsonValue = await loadJson().then((value) => value);
  Map<String, dynamic> mappedJson = json.decode(jsonValue);
  final _text = mappedJson.map((key, value) => MapEntry(key, value.toString()));

  final textLabel = _text[key];
  return textLabel!;
}
