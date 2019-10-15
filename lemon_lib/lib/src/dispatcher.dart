import 'dart:io';

import 'package:lemon_lib/lemon.dart';
import 'package:lemon_lib/src/request.dart';

import 'isolate_executor.dart';

class Answer{
  dynamic data;
  int id;
}

//这个用来生成
class AsyncCall extends Runnable{

  Engine engine;
  OnResponse response;
  OnError error;
  OnExecute execute;
  OnEnd end;
  Request request;
  String host;
  String url;

  AsyncCall(
      this.engine,
      this.request,
      this.execute,
      this.response,
      this.error,
      this.end
      );

  @override
  void init() {
    // TODO: implement init
  }

  @override
  dynamic onRun() async {
    // TODO: implement onRun

    Answer answer = new Answer();
    if(execute != null){
      try{
        dynamic result = await execute(engine,request);
        answer.data = result;
        answer.id = request.id;
        return answer;
      }catch(e,stack){
        print("exception:${e.toString()}");
        print("${stack}");
        answer.data = e;
        answer.id = request.id;
        return answer;

      }

    }
    return null;
  }


  @override
  void callback(data) {
    // TODO: implement callback
    if(data != null&&data is Answer){
      dynamic result = data.data;
      if(result is Exception){
        if(error != null){
          error(data.id,result);
        }
      }else{
        if(response != null){
          response(data.id,result);
        }
      }

    }else if(data is Exception){
      if(error != null){
        error(-1,data);
      }

    } else {
      if(response != null){
        response(-1,data);
      }
    }

    if(end != null){
      end(this);
    }


  }

  @override
  void close() {
    // TODO: implement close
    engine?.close();
  }

  @override
  bool operator ==(other) {
    // TODO: implement ==
    //找到一样的host 复用
    if(other is AsyncCall){
      return (other as AsyncCall).host == host;
    }else{
      return false;
    }

  }
}

class Dispatcher{
  ///核心isolate池子为3
  IsolateExecutor _executor;
  List<AsyncCall> readyCalls = new List();
  List<AsyncCall> runningCalls = new List();
  int maxRequest = 64;
  int maxRequestsPerHost = 5;


  ///从源码可以看到，每一个HttpClient带着多个socket，每一个Socket存活时间默认为15秒
  ///太多socket会导致线程过于繁重，加上Isolate除了生成线程之外会带着Heap，不建议生成多个实例
  Dispatcher({int corePoolSize : 3,
    int maxSize : 5,Duration keepAliveTime : const Duration(seconds: 15)}){
    _executor = new IsolateExecutor(maximumPoolSize: maxSize,
       keepAliveTime: keepAliveTime,corePoolSize: corePoolSize);
  }



  int runningCallsForHost(AsyncCall call){
    int result = 0;
    for(AsyncCall c in runningCalls){
      if(c.host == call.host){
        result++;
      }
    }

    return result;
  }




  void enqueue<T>(AsyncCall call){
    if(runningCalls.length < maxRequest
        &&runningCallsForHost(call)<maxRequestsPerHost){
      runningCalls.add(call);
      _executor.execute(call);
    }else{
      readyCalls.add(call);
    }
  }

  void execute(AsyncCall call) {
    if(runningCalls.length < maxRequest
        &&runningCallsForHost(call)<maxRequestsPerHost){
      runningCalls.add(call);
    }else{
      readyCalls.add(call);
    }
  }

  void executeSyncCall(AsyncCall call) async {
    call?.init();
    dynamic data =  await call?.onRun();
    call?.callback(data);
  }

  void finish(AsyncCall call){
    runningCalls.remove(call);
    AsyncCall next = tryToFindSameHostCall(call);
    if(next != null){
      _executor.execute(next);
    }
  }

  AsyncCall tryToFindSameHostCall(AsyncCall call){
    AsyncCall prepare;
    for(int i = readyCalls.length - 1;i>=0;i--){
      AsyncCall c = readyCalls[i];
      if(c?.host == call?.host){
        return c;
      }else{
        prepare = c;
      }
    }


    return prepare;
  }


}