import 'dart:isolate';

import 'package:lemon_lib/lemon.dart';
import 'package:lemon_lib/src/utils.dart';

//这个用来生成
class AsyncCall{
  String host;
  String url;
  dynamic data;
  Map<String, dynamic> queryParameters;
  Options options;
  Isolate isolate;
  SendPort port;
}

class isolateDispatcher{
  Pools<Isolate> pools;
  List<AsyncCall> readyCalls;
  List<AsyncCall> runningCalls;
  int maxRequest = 64;
  int maxRequestsPerHost = 5;

  static isolateDispatcher _controller;

  factory isolateDispatcher(int maxSize){
    if(_controller == null){
      _controller = isolateDispatcher(maxSize);
    }

    return _controller;
  }

  isolateDispatcher._internal(int maxSize){
   pools = new Pools(maxSize: maxSize);
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
    }else{
      readyCalls.add(call);
    }

  }

  void finish(AsyncCall call){
    runningCalls.remove(call);
  }


}