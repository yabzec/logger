import 'dart:developer';
import 'dart:io';

import 'package:cloudflare_d1/cloudflare_d1.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

enum LogLevel {
  info(0),
  warn(1),
  error(2),
  critical(3);

  const LogLevel(this.levelNumber);

  final int levelNumber;
}

class Logger {
  static const accountId = String.fromEnvironment('CLOUDFLARE_ACCOUNT_ID');
  static const databaseId = String.fromEnvironment(
    'CLOUDFLARE_LOGGER_DATABASE_ID',
  );
  static const apiToken = String.fromEnvironment('CLOUDFLARE_API_TOKEN');
  late final D1Config _config;
  late final D1Client _client;
  late final D1Database database;
  final String _table = 'log';
  final String _subject;
  late final String _title;

  Logger(this._subject, this._title) {
    _config = D1Config(
      accountId: accountId,
      databaseId: databaseId,
      apiToken: apiToken,
    );
    _client = D1Client(config: _config);
    database = D1Database(_client);
  }

  Future<void> info(String content) async {
    return _log(LogLevel.info, content);
  }

  Future<void> warn(String content) async {
    return _log(LogLevel.warn, content);
  }

  Future<void> error(String content) async {
    return _log(LogLevel.error, content);
  }

  Future<void> critical(String content) async {
    return _log(LogLevel.critical, content);
  }

  Future<void> _log(LogLevel level, String content) async {
    log(content);

    if (kDebugMode) {
      return;
    }

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    late final String device;
    late final String os;

    if (Platform.isIOS) {
      IosDeviceInfo info = await deviceInfo.iosInfo;
      device = info.modelName;
      os = "${info.systemName} - ${info.systemVersion}";
    } else {
      AndroidDeviceInfo info = await deviceInfo.androidInfo;
      device = "${info.manufacturer} - ${info.name}";
      os = "ANDROID - ${info.version.release}";
    }

    try {
      await database.insert(_table, {
        'date': new DateTime.now().millisecondsSinceEpoch,
        'device': device,
        'os': os,
        'subject': _subject,
        'level': level.levelNumber,
        'title': _title,
        'content': content,
      });
    } catch (e) {
      log(e.toString());
    }
  }
}
