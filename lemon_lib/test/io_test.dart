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
  await Stream.value(s).transform<List<int>>(new RequestBodyTransformer(
    handleData: (s,sink){
      print("s:${s}");

    }
  )).listen((List<int> s){
    print(s);
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


class RequestBodyTransformer<S , T extends List<int>>  implements StreamTransformer<S, List<int>>,EventSink<T>{

  Function handleData;
  EventSink<T> sink;

  RequestBodyTransformer({void handleData(S data, EventSink<T> sink),
    void handleError(Object error, StackTrace stackTrace, EventSink<T> sink),
    void handleDone(EventSink<T> sink)}):handleData = handleData;


  @override
  void add(T event) {

  } //
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
  Stream<List<int>> bind(Stream<S> stream) {
    return RequestBody(stream,handleData) ;
  }

  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<S, List<int>, RS, RT>(this);

  @override
  void addError(Object error, [StackTrace stackTrace]) {

  }

  @override
  void close() {

  }


}



class RequestBody<S> extends Stream<List<int>>{
  String _contentType;
  int _contentLength;
  Function(S data, EventSink sink) handle;

  Stream<S> source;
  RequestBody(this.source,this.handle);


  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    var subscription =  Stream.castFrom<S,List<int>>(source)
        .listen(handleData,onError: onError,onDone: onDone,cancelOnError: cancelOnError);
    return subscription;
  }

  void handleData(dynamic event){
    print("in requestBody");
  }

}

