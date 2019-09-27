import 'dart:isolate';

import 'package:lemon_lib/lemon.dart';

import 'IsolateExecutor.dart';


//这个用来生成
class AsyncCall extends Runnable{
  String host;
  String url;
  dynamic data;
  Map<String, dynamic> queryParameters;
  Options options;

  @override
  void onRun() {

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

class IsolateDispatcher{
  ///核心isolate池子为3
  IsolateExecutor _executor;
  List<AsyncCall> readyCalls;
  List<AsyncCall> runningCalls;
  int maxRequest = 64;
  int maxRequestsPerHost = 5;

  static IsolateDispatcher _controller;

  factory IsolateDispatcher(int maxSize){
    if(_controller == null){
      _controller = IsolateDispatcher(maxSize);
    }


    return _controller;
  }

  IsolateDispatcher._internal(int maxSize){
    _executor = new IsolateExecutor(maximumPoolSize: maxSize,
       keepAliveTime: Duration(minutes: 5),corePoolSize: 3);
  }


  int runningCallsForHost(AsyncCall call){
    int result;
    for(AsyncCall c in runningCalls){
      if(c.host == call.host){
        result++;
      }
    }

    return result;
  }


  //
  void enqueue<T>(AsyncCall call){
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