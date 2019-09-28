
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


abstract class Runnable {
  void init();
  dynamic onRun();
  void close();
  void callback(dynamic data);
}

abstract class RejectHandler{
  void onHandle(IsolateExecutor executor,Runnable runnable);
}


///Isolate 池子
class IsolateExecutor{
  int corePoolSize = 3;
  int maximumPoolSize = 10;
  Duration keepAliveTime = Duration(minutes: 5);
  RejectHandler handler;
  int state = ctlOf(RUNNING,0);

  DoubleLinkedQueue<Runnable> _workQueue = new DoubleLinkedQueue();
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

  addWorkCount(int count){
    state = ctlOf(runStateOf(state),count+1);
  }

  decrementWorkCount(int count){
    state = ctlOf(runStateOf(state),count-1);
  }


  static bool runStateAtLeast(int c, int s) {
    return c >= s;
  }
  static bool isRunning(int c) {
    return c < SHUTDOWN;
  }


  List<_Worker> workers = new List();

  IsolateExecutor({this.corePoolSize :3,
    this.maximumPoolSize:5,this.keepAliveTime:const Duration(minutes: 5),
    this.handler}){
    cleanUp();
  }


  ///因为是单线程，不能通过阻塞队列循环，可以换一种方式。

  bool addWorker(Runnable run,bool isCore)  {
    int currentState = runStateOf(state);
    if(currentState >= SHUTDOWN){
      return false;
    }

    int count = workerCountOf(state);
    ///寻找一样的空闲work
    _Worker _worker = new _Worker(run,this);
    workers.add(_worker);

    addWorkCount(count);
    print("after add:${workerCountOf(state)}");
    _worker.isRunning = true;
    _worker.execute();

    return true;
  }

//  _Worker findSameIdleWork(Runnable run,IsolateExecutor executor){
//    for(_Worker w in workers){
//      if(w.run == run&&!w.isRunning){
//        w.run = run;
//        return w;
//      }
//    }
//
//    return new _Worker(run,executor);
//  }

  void reject(Runnable runnable){
    handler?.onHandle(this, runnable);
  }

  void execute(Runnable run) {
    //当小于核心Isolate则直接添加到worker中
    ///最好去先寻找寻找空闲的线程

    if(findIdleToRun(run)){
      return;
    }

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

  }

  bool findIdleToRun(Runnable run){

    if(workers.isNotEmpty){
      _Worker preWork;
      for(int i = 0;i< workers.length;i++){
        _Worker _worker = workers[i];
        if(!_worker.isRunning
            &&!_worker.isShutdown){
          if(run == _worker.run){
            _worker.run = run;
            _worker.execute();
            return true;
          }else{
            preWork = _worker;
          }
        }
      }

      if(preWork!=null){
        preWork.run = run;
        preWork.execute();
        return true;
      }
    }

    return false;
  }

  void runIdle(_Worker _worker){
    if(_workQueue.isNotEmpty){
      Runnable runnable = _workQueue.first;
      _workQueue.removeFirst();
      _worker.isRunning = true;
      _worker.executeTask(runnable);
    }

  }

  shutdown() {
    for(_Worker w in workers){
      w.release();
    }
    workers.clear();
    _workQueue.clear();
    state = ctlOf(TERMINATED, 0);
  }


  //为了解决内存泄漏的问题，没5分钟检查一下所有的Isolate是否过期
  cleanUp() => Future.delayed(keepAliveTime,(){
    //每间隔一段时间，判断是否空闲
    if(runStateOf(state) >= SHUTDOWN){
      return;
    }
    workers.removeWhere((element){
      if(!element.isRunning){
        element.release();
      }
      return !element.isRunning;
    });

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
  bool isShutdown = false;
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
      ///数据传输在底层会进行一次类似序列化和反序列化的工作，保证了对象完整，
      ///但是sendPort特殊处理，本质上是native层上的对象
      _Isolate = await Isolate.spawn(Binder.ping, [PING,receivePort.sendPort]);
      receivePort.listen(onReceive,onDone: done);

    }else{
      await _port.send([TRANSACTION,run]);
    }

  }



  void onReceive(dynamic data) async{
    ///判断是不是List的数据
    if(data is List){
      List transaction = data as List;
      switch(transaction[0]){
        case PING_REPLY:
          _port = transaction[1];
          await _port.send([TRANSACTION,run]);
          break;
        case TRANSACTION_REPLY:
          isRunning = false;
          data = transaction[1];
          run.callback(data);
          _executor.runIdle(this);
          break;
        case CLOSE_REPLY:
          _port = null;
          receivePort = null;
          _Isolate = null;
          isShutdown = true;
          break;


      }
    }
  }

  void done(){

  }

  release() async {
    if(isShutdown){
      return;
    }
    await _port?.send([CLOSE,run]);
    receivePort?.close();
    _Isolate?.kill(priority: Isolate.immediate);
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

  static  ioctl(dynamic data) async {
    if(data is List){
      List transaction = data as List;
      if(transaction.isEmpty||transaction.length <= 1){
        return;
      }
      await parseTransaction(transaction);
    }else{
      throw Exception("ioctl must be List");
    }
  }


  static  parseTransaction(List transaction) async{
    switch(transaction[0]){
      case PING:
        sendPort = transaction[1];
        receivePort = new ReceivePort();
        receivePort.listen(ioctl,onDone: done);
        sendPort.send([PING_REPLY,receivePort.sendPort]);
        break;

      case TRANSACTION:
        Runnable r =  transaction[1] as Runnable;
        r.init();
        print("after init");
        dynamic data = await r.onRun();
        print("after run:${data}");
        sendPort?.send([TRANSACTION_REPLY,data]);
        if(sendPort == null){
          throw Exception("sendPort is null ,please ping to sure");
        }
        break;

      case CLOSE:
        Runnable r =  transaction[1] as Runnable;
        r.close();
        sendPort.send([CLOSE_REPLY]);
        sendPort = null;
        receivePort = null;

        break;
    }
  }

  static void done(){

  }

}

