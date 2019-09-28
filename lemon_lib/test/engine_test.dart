import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:lemon_lib/lemon.dart';
import 'package:lemon_lib/src/dispatcher.dart';
import 'package:lemon_lib/src/isolate_executor.dart';

void main() async {



  DioEngineFactory factory = new DioEngineFactory();

  Lemon lemon = new LemonBuilder(new TestFactory())
  .setEngine(factory)
  .build();
//  DioEngine engine =  factory.createEngine();
//  engine.request("www.baidu.com");

  Test test = lemon.create(new Test());

  test.setUser("name");


//  print("result:${result}");

}

class TestFactory extends InterfaceFactory{
  T findInterface<T>(Dispatcher dispatcher,Engine engine,T apiService){
    if(apiService is Test){
      return new TestImpl(dispatcher,engine) as T;
    }
  }
}


class Test{
  void setUser(String name){

  }
}

class TestImpl extends Test{

  Engine engine;
  Dispatcher dispatcher;

  TestImpl(Dispatcher dispatcher,Engine engine){
    this.engine = engine;
    this.dispatcher = dispatcher;
  }

  void setUser(String name) async {
    dispatcher.enqueue(new ExecuteRunnable(engine));
  }
}

class ExecuteRunnable extends Runnable{

  Engine engine;
  ExecuteRunnable(Engine engine){
    this.engine = engine;
  }

  @override
  void init() {
    // TODO: implement init
  }

  @override
  Future<String> onRun() async {
    // TODO: implement onRun
    String result = await engine.request("www.baidu.com");
    print("result:${result}");
    return result;
  }

  @override
  void close() {
    // TODO: implement close
  }


  @override
  void callback(data) {
    // TODO: implement callback
    print("data:${data}");
  }
}


class DioEngineFactory extends EngineFactory{

  @override
  Engine createEngine() {
    // TODO: implement createEngine
    return new DioEngine();
  }
}


class DioEngine extends Engine{
  @override
  Future<T> request<T>(String path, {data, Map<String,dynamic> queryParameters, Options options}) {
    // TODO: implement request
    print("request");

    StreamController controller = new StreamController();
    controller.sink.add(123);
    controller.add(345);

    var streamTransformer = StreamTransformer.fromHandlers(handleData: (value,sink){
      if(value == 123){
        sink.add("true");
      }
    });
    controller.stream.
    transform(streamTransformer).listen((data){
      print("data:${data}");
    });

    Future<String> f =  Future.delayed(Duration(seconds: 3),() => "success");


    return f as Future<T>;

  }
}