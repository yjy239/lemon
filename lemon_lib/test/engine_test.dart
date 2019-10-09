import 'dart:async';

import 'package:dio/dio.dart';
import 'package:lemon_lib/lemon.dart';
import 'package:lemon_lib/src/default_engine.dart';
import 'package:lemon_lib/src/isolate_executor.dart';
import 'package:lemon_lib/src/request.dart';

void main() async {

  EngineFactory factory = new DefaultEngineFactory();

  Lemon lemon = new LemonBuilder(new TestFactory())
  .setEngine(factory)
  .build();


//  DioEngine engine =  factory.createEngine();
//  engine.request("www.baidu.com");

  Test test = lemon.create(new Test());
//
// test.setUser("name");

 Response response = await test.setUserId(11);
 print("response:${response}");

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
  @GET(url:"www.baidu.com/{name}")
  void setUser(@Path("name")String name){

  }

  @GET(url:"www.baidu.com/{id}")
  Future<Response> setUserId(@Path("id")int id){

  }
}

class TestImpl implements Test{

  LemonClient client;

  TestImpl(LemonClient client){
    this.client = client;
  }

  void setUser(String name) async {
//    dispatcher.enqueue(new ExecuteRunnable(engine,p));
  client.newCall(null).enqueue(response:response,error:error);

  }


  Future<Response> setUserId(int id){
    HttpUrl url = new HttpUrl().host("www.baidu.com").scheme("http");

    print("${url.build()}");
    Request request = new Request().get().uri(url);
    return client.newCall(request).enqueueFuture();
  }

  static dynamic execute(Engine engine,Request request) async {
    return await engine.request(request);
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
    String result = await engine.request(new Request());
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


class SampleEngineFactory extends EngineFactory{

  @override
  Engine createEngine() {
    // TODO: implement createEngine
    return new SampleEngine();
  }
}


class SampleEngine extends Engine{
  @override
  Future<R> request<T,R>(Request request) {
    // TODO: implement request
    print("request");


    return Future.delayed(Duration(seconds: 3),() => "success") as Future<R>;

  }

  @override
  void close() {
    // TODO: implement close
  }
}