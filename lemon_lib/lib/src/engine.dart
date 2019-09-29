import 'package:dio/dio.dart';

import 'lemon_core.dart';


abstract class Engine{
  Future<T> request<T>(String path, {
  data,
  Map<String, dynamic> queryParameters,
      CancelToken cancelToken,
  Options options,
      ProgressCallback onSendProgress,
  ProgressCallback onReceiveProgress});

  void close();
}

abstract class EngineFactory{
  Engine createEngine();
}

abstract class InterfaceFactory{
  T findInterface<T>(LemonClient client,T apiService);
}


