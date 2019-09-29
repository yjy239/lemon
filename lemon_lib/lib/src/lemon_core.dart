import 'dart:async';
import 'dart:io';

import 'package:lemon_lib/src/dispatcher.dart';
import 'package:lemon_lib/src/isolate_executor.dart';

import 'engine.dart';

/**
 * isolate Pool 一个异步池子
 */

typedef OnResponse<T> =  void Function(T object);
typedef OnError<T> = void Function(Exception e);
typedef OnExecute<T> = dynamic Function(Engine engine);
typedef OnEnd<T> = dynamic Function(AsyncCall call);

class LemonBuilder{

  InterfaceFactory _mInterfaceFactory;
  EngineFactory _mEngineFactory;
  int _maxPoolSize = 5;
  Duration _keepAliveTime = Duration(seconds: 15);
  int _maxRequestTimes = 64;
  int _corePoolSize = 3;

  //设置接口查询器
  LemonBuilder(InterfaceFactory factory){
    this._mInterfaceFactory = factory;
  }

  LemonBuilder setIsolatePoolMaxSize(int maxSize){
    this._maxPoolSize = maxSize;
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
        _mEngineFactory);
  }
}

/// 希望完整一个isolate对应一个dio，
/// 每一个dio请求结束之后会回到当前的isolate
abstract class Lemon{
  factory Lemon(int coreSize,int maxSize,Duration keepAliveTime,int maxRequestTimes,InterfaceFactory interfaceFactory,
      EngineFactory engineFactory) {
    return new _LemonImpl(interfaceFactory,engineFactory,
        corePoolsSize: coreSize,maxPoolSize: maxSize,keepAliveTime: keepAliveTime,
    maxRequestTimes: maxRequestTimes);
  }


  get engine;


  T create<T>(T interface);
}

 class Call{
  OnResponse response;
  OnError error;
  static LemonClient lemonClient;
  static Completer completer;

  HttpRequest request;

  Call.newRealCall(LemonClient client,HttpRequest request){
    lemonClient = client;
    this.request = request;
  }


  void enqueue(OnExecute execute,{OnResponse response,OnError error}){
    if(lemonClient == null){
      throw Exception("Call has been disposed");
    }
    lemonClient.dispatcher.enqueue(new AsyncCall(lemonClient?.engine,request,execute,response,error,onEnd));
  }

  Future<T> enqueueFuture<T>(){
    if(lemonClient == null){
      throw Exception("Call has been disposed");
    }
    completer = new Completer<T>();
    lemonClient.dispatcher.enqueue(new AsyncCall(lemonClient?.engine,request,innerExecute,innerResponse,innerError,onEnd));
    return completer.future as Future<T>;

  }

  static dynamic innerExecute(Engine engine) async{
    return await engine.request("test");
  }

  static void innerResponse(dynamic data){
    completer?.complete(data);
  }

  static void innerError(Exception e){
    completer?.completeError(e);
  }

  static void dispose(){
    lemonClient = null;
    completer = null;
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

  LemonClient(int corePoolsSize,int maxPoolSize,
      Duration keepAliveTime,int maxRequestTimes,Engine engine):_keepAliveTime = keepAliveTime,
        _maxPoolSize = maxPoolSize,_corePoolsSize = corePoolsSize,
        _maxRequestTimes = maxRequestTimes,engine = engine{

    dispatcher = new Dispatcher(corePoolSize:_corePoolsSize,
        maxSize: _maxPoolSize,keepAliveTime: _keepAliveTime);
  }


  Call newCall(HttpRequest request){
    return Call.newRealCall(this,request);
  }

}

class _LemonImpl implements Lemon{

  InterfaceFactory _interfaceFactory;


  LemonClient client;

  _LemonImpl(this._interfaceFactory,
   EngineFactory engineFactory,{int corePoolsSize,int maxPoolSize,Duration keepAliveTime,int maxRequestTimes}){
    Engine engine = engineFactory?.createEngine();
    client = new LemonClient(corePoolsSize, maxPoolSize, keepAliveTime, maxRequestTimes, engine);

  }

  get engine{
    return client.engine;
  }


  T create<T>(T interface){
    if(_interfaceFactory == null){
      throw new Exception("please set InterfaceFactory");
    }
    return _interfaceFactory.findInterface(client,interface);
  }
}
