import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoUcn extends StatelessWidget {
  const LogoUcn({
    super.key,
    this.height = 80,
    this.width,
    this.colorFilter,
  });

  final double height;
  final double? width;

  /// Si se deja en null, el SVG se muestra con sus COLORES ORIGINALES.
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/ucn_logo.svg',
      height: height,
      width: width,
      fit: BoxFit.contain,
      colorFilter: colorFilter,
    );
  }
}
