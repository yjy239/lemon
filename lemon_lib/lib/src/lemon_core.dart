import 'dart:async';

import 'package:lemon_lib/src/dispatcher.dart';
import 'package:lemon_lib/src/request.dart';

import 'default_engine.dart';
import 'engine.dart';
import 'isolate_executor.dart';

/**
 * isolate Pool 一个异步池子
 */

typedef OnResponse<T> =  void Function(int id,T object);
typedef OnError<T> = void Function(int id,Exception e);
typedef OnExecute<T> = dynamic Function(Engine engine,Request request);
typedef OnEnd<T> = dynamic Function(AsyncCall call);

class LemonBuilder{

  InterfaceFactory _mInterfaceFactory;
  EngineFactory _mEngineFactory = new DefaultEngineFactory();
  int _maxPoolSize = 5;
  Duration _keepAliveTime = Duration(seconds: 15);
  int _maxRequestTimes = 64;
  int _corePoolSize = 3;
  String baseUrl;

  //设置接口查询器
  LemonBuilder(InterfaceFactory factory){
    this._mInterfaceFactory = factory;
  }

  LemonBuilder setIsolatePoolMaxSize(int maxSize){
    this._maxPoolSize = maxSize;
    return this;
  }

  LemonBuilder setBaseUrl(String base){
    this.baseUrl = base;
    return this;
  }


  LemonBuilder setCorePoolMaxSize(int maxSize){
    this._corePoolSize = maxSize;
    return this;
  }


  LemonBuilder setKeepAliveTime(Duration time){
    this._keepAliveTime = time;
    return this;
  }


  LemonBuilder setMaxRequest(int maxSize){
    this._maxRequestTimes = maxSize;
    return this;
  }


  //设置引擎
  LemonBuilder setEngine(EngineFactory factory){
    _mEngineFactory = factory;
    return this;
  }

  Lemon build(){
    return Lemon(_corePoolSize,_maxPoolSize,_keepAliveTime,_maxRequestTimes,_mInterfaceFactory,
        _mEngineFactory,baseUrl);
  }
}

/// 希望完整一个isolate对应一个dio，
/// 每一个dio请求结束之后会回到当前的isolate
abstract class Lemon{


  factory Lemon(int coreSize,int maxSize,Duration keepAliveTime,int maxRequestTimes,InterfaceFactory interfaceFactory,
      EngineFactory engineFactory,String baseUrl) {
    return new _LemonImpl(interfaceFactory,engineFactory,
        corePoolsSize: coreSize,maxPoolSize: maxSize,keepAliveTime: keepAliveTime,
    maxRequestTimes: maxRequestTimes,baseUrl:baseUrl);
  }

  get engine;

  get baseUrl;


  T create<T>(T interface);
}

class Call{
  OnResponse response;
  OnError error;
  static LemonClient lemonClient;

  static CompleterRecord record = CompleterRecord();

  Request request;

  Call.newRealCall(LemonClient client,Request request){
    lemonClient = client;
    this.request = request;
  }


  void enqueue({OnResponse response,OnError error}){
    lemonClient.dispatcher.enqueue(new AsyncCall(lemonClient?.engine,request,innerExecute,response,error,onEnd));
  }

  Future<T> enqueueFuture<T>(){
    Completer completer = new Completer<T>();
    request.id = completer.hashCode;
    record.completerMap[completer.hashCode] = completer;

    lemonClient.dispatcher.enqueue(new AsyncCall(lemonClient?.engine,
        request,innerExecute,innerResponse,innerError,onEnd));

    return completer.future as Future<T>;

  }

  static dynamic innerExecute(Engine engine,Request request) async{
    return await engine.request(request);
  }

  static void innerResponse(int id,dynamic data){
    record.completerMap[id]?.complete(data);
    record.completerMap.remove(id);
  }

  static void innerError(int id,Exception e){
    record.completerMap[id]?.completeError(e);
    record.completerMap.remove(id);
  }

  static void dispose(){
    lemonClient = null;
  }

  static void onEnd(AsyncCall call){
    lemonClient.dispatcher.finish(call);
    dispose();
  }
}



class LemonClient{

  int _maxPoolSize;
  Duration _keepAliveTime;
  int _maxRequestTimes;
  int _corePoolsSize;
  Engine engine;

  Dispatcher dispatcher;
  String baseUrl;

  LemonClient(int corePoolsSize,int maxPoolSize,
      Duration keepAliveTime,int maxRequestTimes,Engine engine,String baseUrl):_keepAliveTime = keepAliveTime,
        _maxPoolSize = maxPoolSize,_corePoolsSize = corePoolsSize,
        _maxRequestTimes = maxRequestTimes,engine = engine,baseUrl = baseUrl{

    dispatcher = new Dispatcher(corePoolSize:_corePoolsSize,
        maxSize: _maxPoolSize,keepAliveTime: _keepAliveTime);
  }

  void setBaseUrl(String baseUrl){
    this.baseUrl = baseUrl;
  }


  Call newCall(Request request){
    return Call.newRealCall(this,request);
  }

}

class _LemonImpl implements Lemon{

  InterfaceFactory _interfaceFactory;


  LemonClient client;

  String _baseUrl;

  _LemonImpl(this._interfaceFactory,
   EngineFactory engineFactory,{int corePoolsSize,int maxPoolSize,Duration keepAliveTime,int maxRequestTimes,
        String baseUrl}){
    this._baseUrl = baseUrl;
    Engine engine = engineFactory?.createEngine();
    client = new LemonClient(corePoolsSize, maxPoolSize,
        keepAliveTime, maxRequestTimes, engine,_baseUrl);

  }

  get engine{
    return client.engine;
  }



  get baseUrl{

    return _baseUrl;
  }

  set baseUrl(String url){
    _baseUrl = url;
    client.setBaseUrl(_baseUrl);
  }

  T create<T>(T interface){
    if(_interfaceFactory == null){
      throw new Exception("please set InterfaceFactory");
    }
    return _interfaceFactory.findInterface(client,interface);
  }
}
