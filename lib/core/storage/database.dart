import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class ScanSessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get panelType => text()();
  TextColumn get panelLabel => text().nullable()();
  TextColumn get deviceModel => text()();
  TextColumn get cameraResolution => text()();
  TextColumn get patternMode => text()();
  TextColumn get patternConfiguration => text()();
  IntColumn get scanDuration => integer()();
  RealColumn get qualityScore => real()();
  TextColumn get processingVersion => text()();
  TextColumn get status => text()();
  TextColumn get thumbnailPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DentCandidates extends Table {
  TextColumn get id => text()();
  TextColumn get scanId => text().references(ScanSessions, #id)();
  RealColumn get normalizedX => real()();
  RealColumn get normalizedY => real()();
  RealColumn get estimatedRadius => real()();
  TextColumn get severity => text()();
  RealColumn get confidence => real()();
  IntColumn get supportingFrameCount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [ScanSessions, DentCandidates])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pocket_dent_scanner.db'));
    return NativeDatabase.createInBackground(file);
  });
}
