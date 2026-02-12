import 'package:flutter/material.dart';

class ConnectButton extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onPressed;

  const ConnectButton({
    required this.isConnected,
    required this.isConnecting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isConnecting ? null : onPressed,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isConnected
                ? [Color(0xFF00D4FF), Color(0xFF0099FF)]
                : [Color(0xFF6B7280), Color(0xFF4B5563)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isConnected ? Color(0xFF00D4FF) : Colors.grey)
                  .withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: isConnecting
              ? CircularProgressIndicator(color: Colors.white)
              : Icon(
                  isConnected ? Icons.power_off : Icons.power_settings_new,
                  size: 80,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
