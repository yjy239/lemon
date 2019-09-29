import 'package:dio/dio.dart';

import 'engine.dart';

class DefaultEngine implements Engine{
  Future<T> request<T>(String path, {
  data, Map<String, dynamic> queryParameters, CancelToken cancelToken,
  Options options, ProgressCallback onSendProgress,
  ProgressCallback onReceiveProgress}){

  }

  @override
  void close() {
    // TODO: implement close
  }

}



class DefaultEngineFactory extends EngineFactory{
  @override
  Engine createEngine() {
    // TODO: implement createEngine
    return new DefaultEngine();
  }
}