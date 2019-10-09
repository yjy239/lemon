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
  HttpSampleImpl(this._client) {
    this._client = _client;
  }

  LemonClient _client;

  @override
  setUser(name, extra, params, id) async {
    var headers = {};
    var _data = {};
    var _params = {'user_name': '${name}'};
    var _fieldMap = {};
    _params.addAll(params);
    String baseUrl = _client.baseUrl;
    HttpUrl url = HttpUrl.get(baseUrl);
    bool isHttp =
        "task/${id}".startsWith("http") || "task/${id}".startsWith("https");
    url = !isHttp ? url.encodedPath("task/${id}") : url;
    _params.forEach((name, value) {
      url.addQueryParameter(name, value);
    });
    Request request = new Request().uri(url);
    headers
      ..forEach((name, value) {
        request.addHeader(name, value);
      });
    if (extra is Extra) {
      request.extra = extra;
    } else {
      DefaultExtra defaultExtra = new DefaultExtra();
      defaultExtra.extra.add(extra);
      request.extra = defaultExtra;
    }
    request.get();
    _client.newCall(request).enqueue();
  }

  @override
  setUserId(name, body) async {
    var headers = {};
    var _data = {};
    _data.addAll(body);
    var _params = {};
    var _fieldMap = {'id': '${name}'};
    String baseUrl = _client.baseUrl;
    HttpUrl url = HttpUrl.get(baseUrl);
    bool isHttp =
        "create_task".startsWith("http") || "create_task".startsWith("https");
    url = !isHttp ? url.encodedPath("create_task") : url;
    _data.addAll(_params);
    Request request = new Request().uri(url);
    headers
      ..forEach((name, value) {
        request.addHeader(name, value);
      });
    request.post(_data);
    return _client.newCall(request).enqueueFuture();
  }
}
