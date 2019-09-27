import 'engine.dart';

/**
 * isolate Pool 一个异步池子
 */

typedef ResponseCallback<T> = void Function(T object);

class LemonBuilder{

  InterfaceFactory mInterfaceFactory;
  EngineFactory mEngineFactory;
  int maxSize;

  //设置接口查询器
  LemonBuilder(InterfaceFactory factory){
    this.mInterfaceFactory = factory;
  }

  LemonBuilder setIsolatePoolMaxSize(int maxSize){
    this.maxSize = maxSize;
  }


  //设置引擎
  LemonBuilder setEngine(EngineFactory factory){
    mEngineFactory = factory;
    return this;
  }

  Lemon build(){
    return Lemon(maxSize,mInterfaceFactory,
        mEngineFactory);
  }
}

/// 希望完整一个isolate对应一个dio，
/// 每一个dio请求结束之后会回到当前的isolate
class Lemon{
  InterfaceFactory _mInterfaceFactory;
  EngineFactory _mEngineFactory;
  int _maxSize;


  Lemon(int maxSize,InterfaceFactory interfaceFactory,
      EngineFactory engineFactory){
    this._mInterfaceFactory = interfaceFactory;
    this._mEngineFactory = engineFactory;
    this._maxSize = maxSize;
  }

  T create<T>(T interface){
    if(_mInterfaceFactory == null){
      throw new Exception("please set InterfaceFactory");
    }
    return _mInterfaceFactory.findInterface(this,interface);
  }
}
