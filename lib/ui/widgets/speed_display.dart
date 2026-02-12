import 'package:flutter/material.dart';

class SpeedDisplay extends StatelessWidget {
  final int uploadSpeed;
  final int downloadSpeed;
  final Duration? connectedTime;

  const SpeedDisplay({
    required this.uploadSpeed,
    required this.downloadSpeed,
    this.connectedTime,
  });

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(2)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFF16213E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SpeedItem(
                icon: Icons.arrow_upward,
                label: 'Yükleme',
                speed: _formatSpeed(uploadSpeed),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _SpeedItem(
                icon: Icons.arrow_downward,
                label: 'İndirme',
                speed: _formatSpeed(downloadSpeed),
              ),
            ],
          ),
          if (connectedTime != null) ...[
            SizedBox(height: 16),
            Divider(color: Colors.white24),
            SizedBox(height: 8),
            Text(
              'Bağlantı Süresi: ${_formatDuration(connectedTime)}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpeedItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String speed;

  const _SpeedItem({
    required this.icon,
    required this.label,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF00D4FF), size: 28),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        SizedBox(height: 4),
        Text(
          speed,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
