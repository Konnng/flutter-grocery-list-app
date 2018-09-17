import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartson/dartson.dart';
import 'package:path_provider/path_provider.dart';

class Db {

  Map _emptyData = { 'data': [], 'settings': [] };
  Map data = {};

  Future<bool> get checkDbFileExists async {
    return this._checkDbFileExists;
  }

  // /Users/juliovedovatto/Library/Developer/CoreSimulator/Devices/469B18E8-E59B-4FC8-9883-93CA1659DF4C/data/Containers/Data/Application/86C30F46-B989-4483-8C1D-EBC83F476D29/Documents/data/db.json

// PRIVATE METHODS --------------------------------------------------------------------------------

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
  
    return directory.path;
  }

  Future<String> get _localDbFilePath async {
    final path = await _localPath;

    return '$path/data/db.json';
  }
  
  Future<File> get _localDbFile async {
    final file = await _localDbFilePath;

    return File(file);
  }

  Future<bool> get _checkDbFileExists async {
    final file = await this._localDbFilePath;

    if (FileSystemEntity.typeSync(file) == FileSystemEntityType.notFound) {
      await new File(file).create(recursive: true);

      this.data = this._emptyData;
      await this.writeDb();

      return true;
    }

    return true;
  }

  Future<File> writeDb() async {
    final file = await _localDbFile;
  
  // Write the file
    return file.writeAsString(json.encode(this.data));
  }

  Future<Map> readDb() async {
    try {
      final file = await _localDbFile;

      // Read the file
      String contents = await file.readAsString();

      data = json.decode(contents);
      
      return data;
    } catch (e) {
      return new Map();
    }
  }
}
// /PRIVATE METHODS -------------------------------------------------------------------------------
