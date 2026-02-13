// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vpn_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VpnServerAdapter extends TypeAdapter<VpnServer> {
  @override
  final int typeId = 0;

  @override
  VpnServer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VpnServer(
      id: fields[0] as String,
      name: fields[1] as String,
      config: fields[2] as String,
      ping: fields[3] as String,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VpnServer obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.config)
      ..writeByte(3)
      ..write(obj.ping)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VpnServerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VPNSubscriptionAdapter extends TypeAdapter<VPNSubscription> {
  @override
  final int typeId = 1;

  @override
  VPNSubscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VPNSubscription(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      servers: (fields[3] as List?)?.cast<VpnServer>(),
    );
  }

  @override
  void write(BinaryWriter writer, VPNSubscription obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.servers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VPNSubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
