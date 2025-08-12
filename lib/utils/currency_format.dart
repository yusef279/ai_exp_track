import 'package:intl/intl.dart';

class CurrencyFmt {
  final String code;
  CurrencyFmt(this.code);

  String money(num v) {
    // Map a few codes to symbols; fallback to code prefix
    final symbol = {
      'USD': '\$','EUR': '€','GBP': '£','EGP': 'E£','AED': 'د.إ','SAR': 'ر.س'
    }[code] ?? '$code ';
    final nf = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return nf.format(v);
  }
}
