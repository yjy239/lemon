import 'dart:async';
import 'dart:io';

void main(){
  String test = "aaaa";

  StreamController<List<int>> controller = StreamController();

  controller.stream.listen((data){
    print("${data}");
  });

  IOSink sink = new IOSink(controller);
  sink.write(test);
  sink.write(test);
  sink.flush();


}


class MyConsumer implements StreamConsumer{

  @override
  Future addStream(Stream stream) {
    // TODO: implement addStream
    return null;
  }

  @override
  Future close() {
    // TODO: implement close
    return null;
  }
}


