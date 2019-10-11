import 'package:dio/dio.dart';
import 'package:lemon_lib/src/request.dart';

import 'engine.dart';

class DioExtra extends Extra{
  CancelToken cancelToken;
//  Options options;
  ProgressCallback onSendProgress;
  ProgressCallback onReceiveProgress;
  Map<String, dynamic> extra;
  int sendTimeout;
  int receiveTimeout;
  ResponseType responseType;
  ValidateStatus validateStatus;

  bool receiveDataWhenStatusError;

  bool followRedirects;

  int maxRedirects;

  RequestEncoder requestEncoder;

  ResponseDecoder responseDecoder;
  int connectTimeout;
}

class DefaultEngine implements Engine{

  Dio dio;
  static DioExtra extra;

  DefaultEngine(Dio dio){
    this.dio = dio;
  }

  Future<R> request<T,R>(Request request) async{
    String method = request.method();
    HttpUrl httpUrl = request.url();
    if(request.extra is DioExtra){
      extra = request.extra as DioExtra;
    }else{
      extra = new DioExtra();
    }

    RequestOptions options;

    if(extra != null){
      options = new RequestOptions();
      options.headers = request.header().map;
      options.method = method;
      options.extra ??= extra?.extra;
      options.followRedirects ??= extra?.followRedirects;
      options.responseType ??= extra?.responseType;
      options.sendTimeout ??= extra?.sendTimeout;
      options.receiveTimeout ??= extra?.receiveTimeout;
      options.validateStatus ??= extra?.validateStatus;
      options.maxRedirects ??= extra?.maxRedirects;
      options.requestEncoder ??= extra?.requestEncoder;
      options.responseDecoder ??= extra?.responseDecoder;
      options.contentType ??= request.body().contentType();
      options.cancelToken ??=extra?.cancelToken;
    }
    Response<T> response = await dio?.request<T>(httpUrl?.build().toString(),
      data : request?.body().data,queryParameters: httpUrl?.queryParameters,
        cancelToken: extra?.cancelToken,
      onSendProgress: onSend,onReceiveProgress:onReceive,
      options: options) ;
    response.request.onSendProgress = onSend;
    response.request.onReceiveProgress = onReceive;
    response?.request?.requestEncoder = requestEncoder;
    response?.request?.responseDecoder = requestDecoder;
    response?.request?.validateStatus = validateStatus;
    return response as R;
  }

  static onSend(int count, int total){
    if(extra?.onSendProgress != null){
      extra?.onSendProgress(count,total);
    }

  }

  static onReceive(int count, int total){
    if(extra?.onReceiveProgress!=null){
      extra?.onReceiveProgress(count,total);
    }

  }

  static String requestDecoder(
      List<int> responseBytes, RequestOptions options, ResponseBody responseBody){
    if(extra?.responseDecoder == null){
      return null;
    }
   return extra?.responseDecoder(responseBytes,options,responseBody);
  }

  static List<int> requestEncoder(
      String request, RequestOptions options){
    if(extra?.requestEncoder == null){
      return null;
    }
    return extra?.requestEncoder(request,options);
  }


  static bool validateStatus(int status){
    if(extra?.validateStatus == null){
      return false;
    }
    return extra?.validateStatus(status);
  }




  @override
  void close() {
    // TODO: implement close
    dio?.close();
  }

}


class DefaultEngineFactory extends EngineFactory{

  Dio dio = new Dio();

  DefaultEngineFactory addInterceptor(Interceptor interceptor){
    dio.interceptors.add(interceptor);
    return this;
  }

  DefaultEngineFactory setHttpClientAdapter(HttpClientAdapter httpClientAdapter){
    dio.httpClientAdapter = httpClientAdapter;
    return this;
  }

  DefaultEngineFactory setTransformer(Transformer transformer){
    dio.transformer = transformer;
    return this;
  }

  DefaultEngineFactory setBaseOptions(BaseOptions options){
    dio.options = options;
    return this;
  }

  @override
  Engine createEngine() {
    // TODO: implement createEngine
    return new DefaultEngine(dio);
  }
}