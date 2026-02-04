import 'package:flutter/services.dart';

/// Formatador de entrada de moeda no padrão brasileiro
/// Converte entrada numérica em R$ 0,00 automaticamente
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove tudo que não for dígito
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Se não tem dígitos, retorna vazio
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Converte para double (centavos)
    double value = double.parse(digitsOnly) / 100;

    // Formata no padrão brasileiro
    String formatted = _formatCurrency(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatCurrency(double value) {
    // Formata com 2 casas decimais
    String valueStr = value.toStringAsFixed(2);

    // Separa parte inteira e decimal
    List<String> parts = valueStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    // Adiciona pontos de milhar
    String formattedInteger = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        formattedInteger = '.$formattedInteger';
        count = 0;
      }
      formattedInteger = integerPart[i] + formattedInteger;
      count++;
    }

    return '$formattedInteger,$decimalPart';
  }
}

/// Parser para converter texto formatado de volta para double
class CurrencyParser {
  static double parse(String formattedValue) {
    if (formattedValue.isEmpty) return 0.0;

    // Remove pontos de milhar e substitui vírgula por ponto
    String cleaned = formattedValue.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(cleaned) ?? 0.0;
  }

  static String format(double value) {
    String valueStr = value.toStringAsFixed(2);

    List<String> parts = valueStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    String formattedInteger = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        formattedInteger = '.$formattedInteger';
        count = 0;
      }
      formattedInteger = integerPart[i] + formattedInteger;
      count++;
    }

    return '$formattedInteger,$decimalPart';
  }
}
