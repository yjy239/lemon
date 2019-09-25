import 'lemon_core.dart';
import 'options.dart';

abstract class Engine{
  Future<T> request<T>(String path,{
    data,
    Map<String, dynamic> queryParameters,
    Options options,
  });
}

abstract class EngineFactory{
  Engine createEngine();
}

abstract class InterfaceFactory{
  T findInterface<T>(Lemon lemon,T apiService);
}