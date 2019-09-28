import 'package:lemon_lib/src/dispatcher.dart';
import 'package:lemon_lib/src/isolate_executor.dart';

import 'engine.dart';

/**
 * isolate Pool 一个异步池子
 */

typedef ResponseCallback<T> = void Function(T object);

class LemonBuilder{

  InterfaceFactory _mInterfaceFactory;
  EngineFactory _mEngineFactory;
  int _maxPoolSize;
  Duration _keepAliveTime;
  int _maxRequestTimes;
  int _corePoolSize;

  //设置接口查询器
  LemonBuilder(InterfaceFactory factory){
    this._mInterfaceFactory = factory;
  }

  LemonBuilder setIsolatePoolMaxSize(int maxSize){
    this._maxPoolSize = maxSize;
  }

  LemonBuilder setCorePoolMaxSize(int maxSize){
    this._corePoolSize = maxSize;
  }


  LemonBuilder setKeepAliveTime(Duration time){
    this._keepAliveTime = time;
  }


  LemonBuilder setMaxRequest(int maxSize){
    this._maxRequestTimes = maxSize;
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
    return new _LemonImpl(coreSize,maxSize,keepAliveTime,maxRequestTimes
      ,interfaceFactory,engineFactory);
  }


  get engineFactory;

  get dispatcher;

  T create<T>(T interface);
}


class Client{

}


class _LemonImpl implements Lemon{

  InterfaceFactory _mInterfaceFactory;
  EngineFactory _mEngineFactory;
  int _maxPoolSize;
  Duration _keepAliveTime;
  int _maxRequestTimes;
  int _corePoolsSize;
  Engine _engine;

  Dispatcher _dispatcher;

  _LemonImpl(int corePoolsSize,int maxPoolSize,Duration keepAliveTime,int maxRequestTimes,
      this._mInterfaceFactory,
      this._mEngineFactory):_keepAliveTime = Duration(seconds: 15),
  _maxPoolSize = 5,_corePoolsSize = 3,_maxRequestTimes = 64{
    _engine = _mEngineFactory?.createEngine();
    _dispatcher = new Dispatcher(corePoolSize:_corePoolsSize,
        maxSize: _maxPoolSize,keepAliveTime: _keepAliveTime);
  }

  get engineFactory{
    return _mEngineFactory;
  }

  get dispatcher{
    return _dispatcher;
  }

  T create<T>(T interface){
    if(_mInterfaceFactory == null){
      throw new Exception("please set InterfaceFactory");
    }
    return _mInterfaceFactory.findInterface(_dispatcher,_engine,interface);
  }
}
