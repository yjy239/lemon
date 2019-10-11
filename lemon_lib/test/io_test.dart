import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http_parser/src/media_type.dart';
import 'package:lemon_lib/src/request_body.dart';




void main() async {
  String test = "aaaa";


//  fun();

//  var onDate = Zone.current.registerUnaryCallback<dynamic,int>(handleData);
//
//  Zone.current.runUnary(onDate,2);

  //List<int> s = [1,2,3,4,5,6,7];
  String ex = "asdadadadasdd";

//  await Stream.value(s).transform<List<int>>(new RequestBodyTransformer(
//    handleData: (s,sink){
//      print("s:${s}");
//
//    }
//  )).listen((List<int> s){
//    print(s);
//  }).asFuture();

//  await Stream.fromIterable(s).map<String>((event){
//    return "${event}11";
//  }).listen((String s){
//    print("result:${s}");
//  }).asFuture();

  Future<void> nullFuture = Future.sync((){
    print("null");
  });

  await Stream.value(ex.codeUnits).transform(new RequestBodyTransformer(12,"aaaa")).listen((e){
    print("code:${String.fromCharCodes(e)}");
  }).asFuture();
  

//  StreamController<String> controller = new StreamController();
//  controller.add("111");
//  RequestBody body =  controller.stream.transform(RequestBodyTransformer(111, "asd", (data,sink){
//    sink.add(data.codeUnits);
//  }));

  RequestBody<String> body = RequestBody.create("aaaa", 111);


  Future.value((){
    return 1;
  });
  await body.listen((data){
    print("data:${data}");
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

