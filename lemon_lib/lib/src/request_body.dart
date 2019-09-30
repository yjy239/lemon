
import 'dart:async';

import 'package:http_parser/src/media_type.dart';

abstract class RequestBody extends Stream<List<int>>{

  RequestBody(){
    this.transform(StreamTransformer.fromHandlers(
      handleData: onHandle,handleDone: onDone,handleError: onError
    ));
  }

  onHandle(List<int> data,Sink<List<int>> sink);

  onDone(EventSink<List<int>> sink);


  onError(Object error, StackTrace stackTrace, EventSink<List<int>> sink);


  /// Returns the Content-Type header for this body.
  MediaType contentType();
  /// Returns the number of bytes that will be written to {@code sink} in a call to {@link #writeTo},
  ///or -1 if that count is unknown.
  contentLength() {
    return -1;
  }


  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}){

  }



}

