import 'package:flutter/material.dart';
import '../../models/vpn_status.dart';

class StatusIndicator extends StatelessWidget {
  final VpnStatus status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;

    switch (status.state) {
      case VpnState.connected:
        statusText = 'Bağlı';
        statusColor = Color(0xFF00D4FF);
        break;
      case VpnState.connecting:
        statusText = 'Bağlanıyor...';
        statusColor = Colors.orange;
        break;
      case VpnState.disconnecting:
        statusText = 'Bağlantı kesiliyor...';
        statusColor = Colors.orange;
        break;
      case VpnState.error:
        statusText = 'Hata: ${status.message ?? "Bilinmeyen"}';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'Bağlı Değil';
        statusColor = Color(0xFF6B7280);
    }

    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.6),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          statusText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
