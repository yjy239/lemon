
import 'dart:collection';

import 'dart:isolate';

class Pools<P>{
  int maxSize = 5;

  List<P> _mPool;

  int _mPoolSize = 0;

  Pools({this.maxSize}){
    _mPool = new List(maxSize);
  }


  P acquire(){
    if(_mPoolSize > 0){
      int lastIndex = _mPoolSize - 1;
      P instance = _mPool[lastIndex];
      _mPool[lastIndex] = null;
      _mPoolSize--;

      return instance;
    }

    return null;
  }


  bool isInPool(P instance){
    for(var p in _mPool){
      if(p == instance){
        return true;
      }
    }

    return false;
  }


  bool release(P instance){
    if(isInPool(instance)){
      return false;
    }


    if(_mPoolSize < maxSize){
      _mPool[_mPoolSize] = instance;
      _mPoolSize++;
      return true;
    }

    return false;
  }

}

//typedef onRun = void Function();


abstract class Runnable{
  void onRun();
}

abstract class RejectHandler{
  void onHandle(IsolateExecutor executor,Runnable runnable);
}


///Isolate 池子
class IsolateExecutor{
  int corePoolSize;
  int maximumPoolSize;
  Duration keepAliveTime = Duration(minutes: 5);
  RejectHandler handler;
  int state = ctlOf(RUNNING,0);

  Queue<Runnable> _workQueue = new Queue();
  ///思想：最高三位 30 31 32控制状态，29位以下控制数量
  ///思想和android的measure很相似
  static final int COUNT_BITS = 32 - 3;
  /// -1 右移动29位 第30,31,32全是1
  static final int RUNNING    = -1 << COUNT_BITS;
  /// 全是0
  static final int SHUTDOWN =  0 << COUNT_BITS;
  /// 1 第30位为1
  static final int STOP       =  1 << COUNT_BITS;
  /// 第30,31位置为 10
  static final int TIDYING    =  2 << COUNT_BITS;
  /// 第30,31位置为 11
  static final int TERMINATED =  3 << COUNT_BITS;


  /// 1 左移动 29位 -1:29位到1位全是1
  static final int CAPACITY   = (1 << COUNT_BITS) - 1;

  ///获取最高三位
   static int runStateOf(int c)     { return c & ~CAPACITY; }
   ///获取最低29位数
   static int workerCountOf(int c)  { return c & CAPACITY; }
   ///初始化状态和位数
   static int ctlOf(int rs, int wc) { return rs | wc; }
   static bool runStateLessThan(int c, int s) {
    return c < s;
  }

  static bool runStateAtLeast(int c, int s) {
    return c >= s;
  }
  static bool isRunning(int c) {
    return c < SHUTDOWN;
  }


  Set<_Worker> workers = new Set();

  IsolateExecutor({this.corePoolSize,
    this.maximumPoolSize,this.keepAliveTime,this.handler});


  bool addWorker(Runnable run,bool isCore)  {
    int currentState = runStateOf(state);
    if(currentState >= SHUTDOWN ){
      return false;
    }

    ///寻找一样的空闲work
    _Worker _worker = findSameIdleWork(run,this);
    workers.add(_worker);
    _worker.isRunning = true;
    _worker.execute();

    return true;
  }

  _Worker findSameIdleWork(Runnable run,IsolateExecutor executor){
    for(_Worker w in workers){
      if(w.run == run&&!w.isRunning){
        return w;
      }
    }

    return new _Worker(run,executor);
  }

  void reject(Runnable runnable){
    handler?.onHandle(this, runnable);
  }

  void execute(Runnable run) {
    //当小于核心Isolate则直接添加到worker中
    if(workerCountOf(state) < corePoolSize){
      ///添加成功则返回
      if(addWorker(run, true)){
        return;
      }
    }
    //当大于核心Isolate,如果则添加到准备队列中,但是小于最大池子数
    if(isRunning(state)
        &&workerCountOf(state)<maximumPoolSize){
      _workQueue.add(run);
    }else{
      reject(run);
    }
    //启动检测
    cleanUp();
  }

  void submit(_Worker _worker){
    if(_workQueue.isNotEmpty){
      Runnable runnable = _workQueue.first;
      _worker.isRunning = true;
      _worker.executeTask(runnable);
    }

  }

  void showdown() async* {
    for(_Worker w in workers){
      await w.release();
    }
    workers.clear();
    _workQueue.clear();
    ctlOf(TERMINATED, 0);
  }


  //为了解决内存泄漏的问题，没5分钟检查一下所有的Isolate是否过期
  cleanUp() => Future.delayed(keepAliveTime,(){
    //每间隔一段时间，判断是否空闲
    if(runStateOf(state) == SHUTDOWN){
      return;
    }
     Iterator<_Worker> it =  workers.iterator;
     while(it.moveNext()){
       if(!it.current.isRunning){
         it.current.release();
         workers.remove(it.current);
       }

     }

     cleanUp();
    });

}

class _Worker{
  Runnable run;
  ///Isolate 底层调度有个队列算法，当有空闲则取出空闲的Thread
  ///新创建的Isolate进行复用一个空闲的OsThread，没有则新建OSThread 接着创建一个Isolate进行调度
  ///经过源码的阅读，一个线程最多在底层等待5000 * 1000毫秒。
  ///如果说我能在这段时间内获取到对应的sendPort的话，就能完美的复用到原来的线程跨越
  Isolate _Isolate;
  ///from other Isolate
  SendPort _port;
  ReceivePort receivePort;
  bool isRunning = false;
  IsolateExecutor _executor;

  _Worker(Runnable run,IsolateExecutor executor){
    this.run = run;
    this._executor = executor;
  }

  executeTask(Runnable runnable){
    _port?.send([TRANSACTION,run]);
  }

  /// 数据构成 由命令+数据构成
  execute() async{
    if(receivePort == null||_port == null){
      _Isolate?.kill(priority: Isolate.immediate);
      receivePort = new ReceivePort();
      ///数据传输在底层会进行一次类似序列化和反序列化的工作，保证了对象唯一
      _Isolate = await Isolate.spawn(Binder.ping, [PING,receivePort.sendPort]);
      receivePort.listen(onReceive,onDone: done);
    }else{
      _port.send([TRANSACTION,run]);
    }

  }

  void onReceive(dynamic data){
    ///判断是不是List的数据
    if(data is List){
      List transaction = data as List;
      switch(transaction[0]){
        case PING_REPLY:
          _port = transaction[1];
          break;
        case TRANSACTION_REPLY:
          isRunning = false;
          _executor.submit(this);
          break;


      }
    }
  }

  void done(){

  }

  release() async {
    _port.send([CLOSE]);
    receivePort?.close();
    _Isolate?.kill(priority: Isolate.immediate);
    _port = null;
    receivePort = null;
    _Isolate = null;
  }


}


/// pingTo Isolate
const String PING = "BC_PING";
const String PING_REPLY = "BR_PING";
const String TRANSACTION = "BC_TRANSACTION";
const String TRANSACTION_REPLY = "BR_TRANSACTION";
const String CLOSE = "BC_CLOSE";
const String CLOSE_REPLY = "BR_CLOSE";

class Binder{
  static ReceivePort receivePort;
  //from root
  static SendPort sendPort;

  static void ping(var message){
    if(message is List){
      List transaction = message as List;
      if(transaction.isEmpty||transaction.length <= 1){
        return;
      }
      parseTransaction(transaction);
    }else{
      throw Exception("ping must be List");
    }

  }

  static void ioctl(dynamic data){
    if(data is List){
      List transaction = data as List;
      if(transaction.isEmpty||transaction.length <= 1){
        return;
      }
      parseTransaction(transaction);
    }else{
      throw Exception("ioctl must be List");
    }
  }


  static void parseTransaction(List transaction){
    switch(transaction[0]){
      case PING:
        sendPort = transaction[1];
        receivePort = new ReceivePort();
        receivePort.listen(ioctl,onDone: done);
        sendPort.send([PING_REPLY,receivePort.sendPort]);
        break;

      case TRANSACTION:
        Runnable r =  transaction[1] as Runnable;
        r.onRun();
        sendPort?.send([TRANSACTION_REPLY]);
        if(sendPort == null){
          throw Exception("sendPort is null ,please ping to sure");
        }
        break;

      case CLOSE_REPLY:
        sendPort = null;
        receivePort = null;
        break;
    }
  }

  static void done(){

  }

}

