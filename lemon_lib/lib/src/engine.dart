import 'package:dio/dio.dart';
import 'package:lemon_lib/src/request.dart';

import 'lemon_core.dart';


abstract class Engine{
  Future<R> request<T,R>(Request request);

  void close();
}

abstract class EngineFactory{
  Engine createEngine();
}

abstract class InterfaceFactory{
  T findInterface<T>(LemonClient client,T apiService);
}


