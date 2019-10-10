import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http_parser/src/media_type.dart';




void main() async {
  String test = "aaaa";


//  fun();

//  var onDate = Zone.current.registerUnaryCallback<dynamic,int>(handleData);
//
//  Zone.current.runUnary(onDate,2);

  List<int> s = [1,2,3,4,5,6,7];
//  await Stream.value(s).transform<List<int>>(new RequestBodyTransformer(
//    handleData: (s,sink){
//      print("s:${s}");
//
//    }
//  )).listen((List<int> s){
//    print(s);
//  }).asFuture();

  await Stream.fromIterable(s).map<String>((event){
    return "${event}11";
  }).listen((String s){
    print("result:${s}");
  }).asFuture();

}



fun() async {
  var directory = await new Directory("temp").create();
  print(directory.absolute.path);
  File file = new File("${directory.absolute.path}/test.txt");
  file = await file.create();


//  file.writeAsString("test 111\n").asStream()
//      .transform(StreamTransformer.fromHandlers(
//    handleData: (data,sink){
//      sink.add("+abc");
//    }
//  )).listen((data){
//    print(":data ${data}");
//  });

  List<int> encode = Utf8Codec().encode("test 111\n");



  file.open(mode:FileMode.write).then((f){
    f.writeFrom(encode,0,encode.length).then<File>((_){
       return f.flush().asStream().listen((data){
         print(":data ${data}");
       }).asFuture().then((_) => file).whenComplete((){
         f.close();
       });
    });
  });

  List<String> lines = await file.readAsLines();
  lines.forEach(
          (String line) => print(line)
  );









}



handleData(result) {
  print("VVVVVVVVVVVVVVVVVVVVVVVVVVV");
  print(result);
}


class RequestBodyTransformer  implements StreamTransformer<List<int>, List<int>>{

  Function handleData;
  EventSink<List<int>> sink;

  RequestBodyTransformer({void handleData(List<int> data, EventSink<List<int>> sink),
    void handleError(Object error, StackTrace stackTrace, EventSink<List<int>> sink),
    void handleDone(EventSink<List<int>> sink)}):handleData = handleData;


//  /// Returns the Content-Type header for this body.
//  MediaType contentType(){
//    return MediaType.parse(_contentType);
//  }
//  /// Returns the number of bytes that will be written to {@code sink} in a call to {@link #writeTo},
//  ///or -1 if that count is unknown.
//  contentLength() {
//    return _contentLength;
//  }

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    return RequestBody(stream,handleData) ;
  }

  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<List<int>, List<int>, RS, RT>(this);




}



class RequestBody extends Stream<List<int>>{
  String _contentType;
  int _contentLength;
  Function(List<int> data, EventSink sink) handle;

  Stream source;
  RequestBody(this.source,this.handle);


  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    StreamSubscription<List<int>> subscription =  Stream.castFrom(source)
        .listen(handleData,onError: onError,onDone: onDone,cancelOnError: cancelOnError);
    return subscription;
  }

  void handleData(dynamic event){
    print("in requestBody");
  }

}

/// Data-handler coming from [StreamTransformer.fromHandlers].
typedef void _TransformDataHandler<S, T>(S data, EventSink<T> sink);

/// Error-handler coming from [StreamTransformer.fromHandlers].
typedef void _TransformErrorHandler<T>(
    Object error, StackTrace stackTrace, EventSink<T> sink);

/// Done-handler coming from [StreamTransformer.fromHandlers].
typedef void _TransformDoneHandler<T>(EventSink<T> sink);

class _HandlerEventSink<S, T> implements EventSink<S> {
  final _TransformDataHandler<S, T> _handleData;
  final _TransformErrorHandler<T> _handleError;
  final _TransformDoneHandler<T> _handleDone;

  /// The output sink where the handlers should send their data into.
  EventSink<T> _sink;

  _HandlerEventSink(
      this._handleData, this._handleError, this._handleDone, this._sink) {
    if (_sink == null) {
      throw new ArgumentError("The provided sink must not be null.");
    }
  }

  bool get _isClosed => _sink == null;

  void add(S data) {
    if (_isClosed) {
      throw StateError("Sink is closed");
    }
    if (_handleData != null) {
      _handleData(data, _sink);
    } else {
      _sink.add(data as T);
    }
  }

  void addError(Object error, [StackTrace stackTrace]) {
    if (_isClosed) {
      throw StateError("Sink is closed");
    }
    if (_handleError != null) {
      _handleError(error, stackTrace, _sink);
    } else {
      _sink.addError(error, stackTrace);
    }
  }

  void close() {
    if (_isClosed) return;
    var sink = _sink;
    _sink = null;
    if (_handleDone != null) {
      _handleDone(sink);
    } else {
      sink.close();
    }
  }
}


class RequestBodyStreamSubscription<S, T> implements StreamSubscription<T> ,
    EventSink<T>{
  final StreamSubscription<S> _source;

  /// Zone where listen was called.
  final Zone _zone = Zone.current;

  /// User's data handler. May be null.
  void Function(T data) _handleData;

  /// Copy of _source's handleError so we can report errors in onData.
  /// May be null.
  Function _handleError;
  _HandlerEventSink _handlerEventSink;

  RequestBodyStreamSubscription(this._source, this._handlerEventSink) {
    _source.onData(_onData);
  }

  Future cancel() => _source.cancel();

  void onData(void handleData(T data)) {
    _handleData = handleData == null
        ? null
        : _zone.registerUnaryCallback<dynamic, T>(handleData);
  }

  void onError(Function handleError) {
    _source.onError(handleError);
    if (handleError == null) {
      _handleError = null;
    } else if (handleError is Function(Null, Null)) {
      _handleError = _zone
          .registerBinaryCallback<dynamic, Object, StackTrace>(handleError);
    } else {
      _handleError = _zone.registerUnaryCallback<dynamic, Object>(handleError);
    }
  }

  void onDone(void handleDone()) {
    _source.onDone(handleDone);
  }

  void _onData(S data) {
    if (_handleData == null) return;
    T targetData;
    try {
      targetData = data as T;
    } catch (error, stack) {
      if (_handleError == null) {
        _zone.handleUncaughtError(error, stack);
      } else if (_handleError is Function(Null, Null)) {
        _zone.runBinaryGuarded(_handleError, error, stack);
      } else {
        _zone.runUnaryGuarded(_handleError, error);
      }
      return;
    }
    _zone.runUnaryGuarded(_handleData, targetData);
  }

  void pause([Future resumeSignal]) {
    _source.pause(resumeSignal);
  }

  void resume() {
    _source.resume();
  }

  bool get isPaused => _source.isPaused;

  Future<E> asFuture<E>([E futureValue]) => _source.asFuture<E>(futureValue);

  @override
  void add(T event) {

  }

  @override
  void close() {

  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {

  }
}

