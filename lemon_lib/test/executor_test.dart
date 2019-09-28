

import 'dart:async';
import 'dart:io';

import 'package:lemon_lib/src/isolate_executor.dart';

class NamedRunnable extends Runnable{

  String host;

  NamedRunnable({this.host});

  @override
  dynamic onRun() {
    // TODO: implement onRun
    print("${Zone.current}");
//    sleep(Duration(seconds: 10));

  return 10;
  }

  @override
  bool operator ==(other) {
    // TODO: implement ==
    if(other is NamedRunnable){
      return other.host == host;
    }
    return false;
  }

  @override
  void close() {
    // TODO: implement close
    print("close");
  }

  @override
  void init() {
    // TODO: implement init
  }

  @override
  void callback(data) {
    // TODO: implement callback
    print("data:${data}");
  }

}

void main(){
  IsolateExecutor executor = IsolateExecutor(keepAliveTime: Duration(seconds: 5));

  executor.execute(new NamedRunnable(host: "www.baidu.com"));

  executor.execute(new NamedRunnable(host: "www.baidu.com"));

  executor.execute(new NamedRunnable(host: "www.baidu.com"));

//  executor.execute(new NamedRunnable());
//  executor.execute(new NamedRunnable());


  //sleep(Duration(seconds: 10));

//  executor.execute(new NamedRunnable(host: "www.baidu.com"));
//  executor.execute(new NamedRunnable(host: "www.baidu.com"));
//  executor.execute(new NamedRunnable(host: "www.baidu.com"));
//  executor.execute(new NamedRunnable(host: "www.baidu.com"));
//  executor.execute(new NamedRunnable(host: "www.baidu.com"));

//  executor.shutdown();
}