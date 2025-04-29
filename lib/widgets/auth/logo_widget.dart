import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {

  const LogoWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icons/icon_green.png', // Make sure to add this image to your assets
          width: 250,
          height: 250,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}