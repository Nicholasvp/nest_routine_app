import 'package:hive/hive.dart';
import '../baby.dart';

class BabyAdapter extends TypeAdapter<Baby> {
  @override
  final int typeId = 0;

  @override
  Baby read(BinaryReader reader) {
    return Baby(
      id: reader.readString(),
      name: reader.readString(),
      photoPath: reader.readBool() ? reader.readString() : null,
      dateOfBirth: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Baby obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeBool(obj.photoPath != null);
    if (obj.photoPath != null) {
      writer.writeString(obj.photoPath!);
    }
    writer.writeInt(obj.dateOfBirth.millisecondsSinceEpoch);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
