import 'package:hive/hive.dart';
import '../event.dart';

class EventTypeAdapter extends TypeAdapter<EventType> {
  @override
  final int typeId = 2;

  @override
  EventType read(BinaryReader reader) {
    return EventType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, EventType obj) {
    writer.writeInt(obj.index);
  }
}

class FeedTypeAdapter extends TypeAdapter<FeedType> {
  @override
  final int typeId = 3;

  @override
  FeedType read(BinaryReader reader) {
    return FeedType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, FeedType obj) {
    writer.writeInt(obj.index);
  }
}

class FeedSideAdapter extends TypeAdapter<FeedSide> {
  @override
  final int typeId = 4;

  @override
  FeedSide read(BinaryReader reader) {
    return FeedSide.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, FeedSide obj) {
    writer.writeInt(obj.index);
  }
}

class DiaperTextureAdapter extends TypeAdapter<DiaperTexture> {
  @override
  final int typeId = 5;

  @override
  DiaperTexture read(BinaryReader reader) {
    return DiaperTexture.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, DiaperTexture obj) {
    writer.writeInt(obj.index);
  }
}

class BabyEventAdapter extends TypeAdapter<BabyEvent> {
  @override
  final int typeId = 1;

  @override
  BabyEvent read(BinaryReader reader) {
    return BabyEvent(
      id: reader.readString(),
      babyId: reader.readString(),
      type: reader.read() as EventType,
      startTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      endTime: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      notes: reader.readBool() ? reader.readString() : null,
      feedType: reader.readBool() ? reader.read() as FeedType : null,
      feedSide: reader.readBool() ? reader.read() as FeedSide : null,
      durationMinutes: reader.readBool() ? reader.readInt() : null,
      volumeMl: reader.readBool() ? reader.readInt() : null,
      hasPee: reader.readBool(),
      hasPoop: reader.readBool(),
      diaperTexture: reader.readBool() ? reader.read() as DiaperTexture : null,
    );
  }

  @override
  void write(BinaryWriter writer, BabyEvent obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.babyId);
    writer.write(obj.type);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeBool(obj.endTime != null);
    if (obj.endTime != null) {
      writer.writeInt(obj.endTime!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) {
      writer.writeString(obj.notes!);
    }
    writer.writeBool(obj.feedType != null);
    if (obj.feedType != null) {
      writer.write(obj.feedType);
    }
    writer.writeBool(obj.feedSide != null);
    if (obj.feedSide != null) {
      writer.write(obj.feedSide);
    }
    writer.writeBool(obj.durationMinutes != null);
    if (obj.durationMinutes != null) {
      writer.writeInt(obj.durationMinutes!);
    }
    writer.writeBool(obj.volumeMl != null);
    if (obj.volumeMl != null) {
      writer.writeInt(obj.volumeMl!);
    }
    writer.writeBool(obj.hasPee);
    writer.writeBool(obj.hasPoop);
    writer.writeBool(obj.diaperTexture != null);
    if (obj.diaperTexture != null) {
      writer.write(obj.diaperTexture);
    }
  }
}
