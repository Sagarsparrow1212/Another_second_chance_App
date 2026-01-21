import 'package:flutter/material.dart';

Widget customDivider({
  double height = 1,
  double thickness = 1,
  Color? color = const Color(0xFF00988b),
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          color!.withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ),
    ),
    height: height,
    width: double.infinity,
  );
}
