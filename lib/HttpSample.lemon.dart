// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CodeGenerator
// **************************************************************************

import 'package:lemon/HttpSample.dart';
import 'package:lemon_lib/lemon.dart';
import 'dart:core';
import 'package:dio/dio.dart';
import 'User.dart';
import 'package:lemon_lib/lemon.dart';

class HttpSampleImpl implements HttpSample {
  HttpSampleImpl(this.client) {
    this.client = client;
  }

  LemonClient client;

  @override
  setUser(name, map, params) async {
    DefaultExtra defaultExtra = new DefaultExtra();

    defaultExtra.extra.add(map);

    var params = {'user_name': '${name}'};
    params.addAll(params);
  }

  @override
  setUserId(name, body) async {
    var _data = body;
    var params = {'id': '${name}'};
  }
}
