enum VpnState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error
}

class VpnStatus {
  final VpnState state;
  final String? message;
  final int uploadSpeed;
  final int downloadSpeed;
  final Duration? connectedTime;

  VpnStatus({
    required this.state,
    this.message,
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.connectedTime,
  });

  bool get isConnected => state == VpnState.connected;
  bool get isConnecting => state == VpnState.connecting;
  bool get isDisconnected => state == VpnState.disconnected;
}
