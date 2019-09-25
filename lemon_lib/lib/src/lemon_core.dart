import 'dart:isolate';

import 'engine.dart';

/**
 * isolate Pool 一个异步池子
 */
class IsolatePool {
  List<ReceivePort> list = new List();
}


class LemonBuilder{

  InterfaceFactory mInterfaceFactory;
  EngineFactory mEngineFactory;

  //设置接口查询器
  LemonBuilder(InterfaceFactory factory){
    this.mInterfaceFactory = factory;
  }


  //设置引擎
  LemonBuilder setEngine(EngineFactory factory){
    mEngineFactory = factory;
    return this;
  }

  Lemon build(){
    return new Lemon();
  }
}

/// 希望完整一个isolate对应一个dio，
/// 每一个dio请求结束之后会回到当前的isolate
class Lemon{
  InterfaceFactory _mInterfaceFactory;
  EngineFactory _mEngineFactory;

  _Lemon(InterfaceFactory interfaceFactory,
      EngineFactory engineFactory){
    this._mInterfaceFactory = interfaceFactory;
    this._mEngineFactory = engineFactory;
  }

  T create<T>(T interface){
    if(_mInterfaceFactory == null){
      throw new Exception("please set InterfaceFactory");
    }
    return _mInterfaceFactory.findInterface(this,interface);
  }
}