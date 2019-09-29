import 'dart:async';

import 'package:dio/dio.dart';
import 'package:lemon_lib/lemon.dart';
import 'package:lemon_lib/src/isolate_executor.dart';

void main() async {

  DioEngineFactory factory = new DioEngineFactory();

  Lemon lemon = new LemonBuilder(new TestFactory())
  .setEngine(factory)
  .build();
//  DioEngine engine =  factory.createEngine();
//  engine.request("www.baidu.com");

  Test test = lemon.create(new Test());
//
 test.setUser("name");

// String response = await test.setUserId(11);
// print("response:${response}");
//
//  String response1 = await test.setUserId(11);
//  print("response1:${response1}");
//
//
//  String response2 = await test.setUserId(11);
//  print("response2:${response2}");
//
//  String response3 = await test.setUserId(11);
//  print("response3:${response3}");
//  String response4 = await test.setUserId(11);
//  print("response4:${response4}");
//  String response5 = await test.setUserId(11);
//  print("response5:${response4}");


//  print("result:${result}");

}

class TestFactory extends InterfaceFactory{
  T findInterface<T>(LemonClient client,T apiService){
    if(apiService is Test){
      return new TestImpl(client) as T;
    }
  }
}


class Test{
  void setUser(String name){

  }

  Future<String> setUserId(int id){

  }
}

class TestImpl implements Test{

  LemonClient client;

  TestImpl(LemonClient client){
    this.client = client;
  }

  void setUser(String name) async {
//    dispatcher.enqueue(new ExecuteRunnable(engine,p));
  client.newCall(null).enqueue(execute,response:response,error:error);
  client.newCall(null).enqueue(execute,response:response,error:error);
  }


  Future<String> setUserId(int id){
    return client.newCall(null).enqueueFuture();
  }

  static dynamic execute(Engine engine) async {
    return await engine.request("www.baidu.com");
  }

  static response(dynamic data){
    print("${data}");
  }

  static error(Exception e){
    print(e);
  }

}

class Action{

}


class ExecuteRunnable extends Runnable{

  Engine engine;
  Function function;
  ExecuteRunnable(Engine engine,Function function){
    this.engine = engine;
    this.function = function;
  }

  @override
  void init() {
    // TODO: implement init
  }

  @override
  Future<String> onRun() async {
    // TODO: implement onRun
    function();
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
  Future<T> request<T>(String path, {
  data,
  Map<String, dynamic> queryParameters,
      CancelToken cancelToken,
  Options options,
      ProgressCallback onSendProgress,
  ProgressCallback onReceiveProgress}) {
    // TODO: implement request
    print("request");


    return Future.delayed(Duration(seconds: 3),() => "success") as Future<T>;

  }

  @override
  void close() {
    // TODO: implement close
  }
}