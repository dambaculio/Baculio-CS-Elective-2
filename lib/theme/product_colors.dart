import 'package:flutter/material.dart';

class ProductColorOption {
  const ProductColorOption(this.name, this.color);

  final String name;
  final Color color;
}

const List<ProductColorOption> productColorPalette = [
  ProductColorOption('White', Color(0xFFFFFFFF)),
  ProductColorOption('Cream', Color(0xFFF5E9D0)),
  ProductColorOption('Pink', Color(0xFFFCBED5)),
  ProductColorOption('Red', Color(0xFFE53935)),
  ProductColorOption('Orange', Color(0xFFFB8C00)),
  ProductColorOption('Yellow', Color(0xFFFDD835)),
  ProductColorOption('Green', Color(0xFF43A047)),
  ProductColorOption('Blue', Color(0xFF1E88E5)),
  ProductColorOption('Purple', Color(0xFF8E24AA)),
  ProductColorOption('Black', Color(0xFF212121)),
];

Color swatchColorFor(String name) {
  for (final option in productColorPalette) {
    if (option.name == name) return option.color;
  }
  return const Color(0xFFBDBDBD);
}
