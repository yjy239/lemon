import 'dart:isolate';
import 'dart:math';

import 'package:lemon_lib/lemon.dart';

import 'isolate_executor.dart';

typedef OnExecute = dynamic Function();

typedef OnError = void Function(Exception e);


//这个用来生成
class AsyncCall extends Runnable{
  String host;
  String url;

  Runnable runnable;

  AsyncCall(Runnable runnable){
    this.runnable = runnable;
  }

  @override
  dynamic onRun() async {
   return await runnable.onRun();
  }

  @override
  void close() {
    // TODO: implement close
  }

  @override
  void init() {
    // TODO: implement init
  }

  @override
  void callback(data) {
    // TODO: implement callback
    print("${data}");
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
  Dispatcher({int corePoolSize,
    int maxSize,Duration keepAliveTime}){
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




  void enqueue<T>(Runnable runnable){
    AsyncCall call = new AsyncCall(runnable);
    if(runningCalls.length < maxRequest
        &&runningCallsForHost(call)<maxRequestsPerHost){
      runningCalls.add(call);
      _executor.execute(call);
    }else{
      readyCalls.add(call);
    }

  }

  void finish(AsyncCall call){
    runningCalls.remove(call);
  }


}