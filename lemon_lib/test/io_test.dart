import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http_parser/src/media_type.dart';

void main(){
  String test = "aaaa";


  fun();

  var onDate = Zone.current.registerUnaryCallback<dynamic,int>(handleData);

  Zone.current.runUnary(onDate,2);

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


class RequestBody extends Stream<List<int>>{

  RequestBody(){

  }



  /// Returns the Content-Type header for this body.
  MediaType contentType(){
    return null;
  }
  /// Returns the number of bytes that will be written to {@code sink} in a call to {@link #writeTo},
  ///or -1 if that count is unknown.
  contentLength() {
    return -1;
  }


  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}){

    return null;
  }



}

class RequestBodyController extends Stream<List<int>>{

  RequestBodyController(){

  }



  /// Returns the Content-Type header for this body.
  MediaType contentType(){
    return null;
  }
  /// Returns the number of bytes that will be written to {@code sink} in a call to {@link #writeTo},
  ///or -1 if that count is unknown.
  contentLength() {
    return -1;
  }


  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}){

    return null;
  }



}


