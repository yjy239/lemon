import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';

///RequestBody for all network.This is for Future Design
class FormBody extends RequestBody<Map<String,String>>{

  static String formBodyContentType = "application/x-www-form-urlencoded";

  FormBody(Stream source,int _contentLength,{ dynamic data})
      :super(source,_contentLength,null,data:data);

  @override
  void onData(Map<String,String> data, EventSink<List<int>> sink) {
    // TODO: implement onData
    super.onData(data, sink);
    StringBuffer result = new StringBuffer();
    int length = data?.length;
    int count = 0;
    data.forEach((name,value){
      if(count>0){
        result.write("&");
      }
      result.write("${name}=${value}");
    });

    sink.add(result?.toString()?.codeUnits);
  }

  @override
  String contentType() {
    // TODO: implement contentType
    return formBodyContentType;
  }
}


class FormBodyTransformer extends RequestBodyTransformer<Map<String,String>>{
  FormBodyTransformer(int contentLength,{Map<String,String> data}):
        super(contentLength,null,data:data);
}



class RequestBodyTransformer<S>  implements StreamTransformer<S, List<int>>{

//  Function(S, EventSink<List<int>> sink) handleData;
//
//  Function(Object error, StackTrace stackTrace, EventSink<List<int>> sink) handleError;
//  Function(EventSink<List<int>> sink) handleDone;

  String _contentType = "";
  int _contentLength = -1;
  dynamic data;
  RequestBodyCallback<S, List<int>> callback;

  RequestBodyTransformer(this._contentLength,this._contentType,{this.data});


  /// Returns the Content-Type header for this body.
  MediaType contentType(){
    return MediaType.parse(_contentType);
  }
  /// Returns the number of bytes that will be written to {@code sink} in a call to {@link #writeTo},
  ///or -1 if that count is unknown.
  contentLength() {
    return _contentLength;
  }

  @override
  Stream<List<int>> bind(Stream<S> stream) {
    return RequestBody(stream,this._contentLength,this._contentType,data: data);
  }

  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<S, List<int>, RS, RT>(this);

}

abstract class RequestBodyCallback<S,T>{
  onData(S data, EventSink<T> sink);

  void onError(Object error, StackTrace stackTrace, EventSink<T> sink);

  void onDone(EventSink<T> sink);
}



class RequestBody<S> extends Stream<List<int>> implements RequestBodyCallback<S,List<int>>{
  String _contentType;
  int _contentLength;
  dynamic data;
  dynamic extra;

  factory RequestBody.create(String contentType,int contentLength,
      {dynamic data}){
    StreamController<S> controller = new StreamController();
    return controller.stream.transform(RequestBodyTransformer(contentLength, contentType,data: data));
  }

  factory RequestBody.createForm(int contentLength,
      {dynamic data}){
    StreamController<Map<String,String>> controller = new StreamController();
    return controller.stream.transform(FormBodyTransformer(contentLength,data: data));
  }




  Stream<S> source;
  RequestBody(this.source,this._contentLength,this._contentType,{ this.data});


  /// Returns the Content-Type header for this body.
  String contentType(){
    return _contentType;
  }
  /// Returns the number of bytes that will be written to {@code sink} in a call to {@link #writeTo},
  ///or -1 if that count is unknown.
  contentLength() {
    return _contentLength;
  }

  void onData(S data, EventSink<List<int>> sink){

  }

  void onError(Object error, StackTrace stackTrace, EventSink<List<int>> sink){
    sink.addError(error,stackTrace);
  }

  void onDone(EventSink<List<int>> sink){
    sink.close();
  }



  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
//    StreamSubscription<List<int>> subscription =  Stream.castFrom(source)
//        .listen(handleData,onError: onError,onDone: onDone,cancelOnError: cancelOnError);
    cancelOnError = identical(true, cancelOnError);
    return new RequestBodyStreamSubscription<S,List<int>>(source,
        this,
        onData,onError,onDone,cancelOnError);
  }


}


class RequestBodyStreamSubscription <S, T>
    extends _BufferingStreamSubscription<T>{


  /// The transformer's input sink.
  EventSink<S> _transformerSink;

  /// The subscription to the input stream.
  StreamSubscription<S> _subscription;

//  Function(S data, EventSink sink) handleData;
//  Function(Object error, StackTrace stackTrace, EventSink<S> sink) handleError;
//  Function(EventSink<S> sink) handleDone;
  RequestBodyCallback<S,T> callback;

  RequestBodyStreamSubscription(Stream<S> source,
      this.callback,
      void onData(T data), Function onError, void onDone(), bool cancelOnError)
  // We set the adapter's target only when the user is allowed to send data.
      : super(onData, onError, onDone, cancelOnError) {
    _transformerSink = new _HandlerEventSink<S,T>(callback, this);
    _subscription =
        source.listen(_handleData, onError: _handleError, onDone: _handleDone);
  }

  /** Whether this subscription is still subscribed to its source. */
  bool get _isSubscribed => _subscription != null;

  // _EventSink interface.

  /**
   * Adds an event to this subscriptions.
   *
   * Contrary to normal [_BufferingStreamSubscription]s we may receive
   * events when the stream is already closed. Report them as state
   * error.
   */
  void _add(T data) {
    if (_isClosed) {
      throw new StateError("Stream is already closed");
    }
    super.add(data);
  }

  /**
   * Adds an error event to this subscriptions.
   *
   * Contrary to normal [_BufferingStreamSubscription]s we may receive
   * events when the stream is already closed. Report them as state
   * error.
   */
  void _addError(Object error, StackTrace stackTrace) {
    if (_isClosed) {
      throw new StateError("Stream is already closed");
    }
    super.addError(error, stackTrace);
  }

  /**
   * Adds a close event to this subscriptions.
   *
   * Contrary to normal [_BufferingStreamSubscription]s we may receive
   * events when the stream is already closed. Report them as state
   * error.
   */
  void _close() {
    if (_isClosed) {
      throw new StateError("Stream is already closed");
    }
    super.close();
  }

  // _BufferingStreamSubscription hooks.

  void _onPause() {
    if (_isSubscribed) _subscription.pause();
  }

  void _onResume() {
    if (_isSubscribed) _subscription.resume();
  }

  Future _onCancel() {
    if (_isSubscribed) {
      StreamSubscription subscription = _subscription;
      _subscription = null;
      return subscription.cancel();
    }
    return null;
  }

  void _handleData(S data) {
    try {
      _transformerSink.add(data);
    } catch (e, s) {
      _addError(e, s);
    }
  }

  void _handleError(error, [StackTrace stackTrace]) {
    try {
      _transformerSink.addError(error, stackTrace);
    } catch (e, s) {
      if (identical(e, error)) {
        _addError(error, stackTrace);
      } else {
        _addError(e, s);
      }
    }
  }

  void _handleDone() {
    try {
      _subscription = null;
      _transformerSink.close();
    } catch (e, s) {
      _addError(e, s);
    }
  }

}

abstract class _EventDispatch<T> {
  void _sendData(T data);
  void _sendError(Object error, StackTrace stackTrace);
  void _sendDone();
}


/// Data-handler coming from [StreamTransformer.fromHandlers].
typedef void _TransformDataHandler<S, T>(S data, EventSink<T> sink);

/// Error-handler coming from [StreamTransformer.fromHandlers].
typedef void _TransformErrorHandler<T>(
    Object error, StackTrace stackTrace, EventSink<T> sink);

/// Done-handler coming from [StreamTransformer.fromHandlers].
typedef void _TransformDoneHandler<T>(EventSink<T> sink);

class _HandlerEventSink<S, T> implements EventSink<S> {
//  final _TransformDataHandler<S, T> _handleData;
//  final _TransformErrorHandler<T> _handleError;
//  final _TransformDoneHandler<T> _handleDone;

  /// The output sink where the handlers should send their data into.
  EventSink<T> _sink;
  RequestBodyCallback<S,T> callback;

  _HandlerEventSink(
      this.callback, this._sink) {
    if (_sink == null) {
      throw new ArgumentError("The provided sink must not be null.");
    }
  }

  bool get _isClosed => _sink == null;

  void add(S data) {
    if (_isClosed) {
      throw StateError("Sink is closed");
    }
    if (callback != null) {
      callback.onData(data, _sink);
    } else {
      _sink.add(data as T);
    }
  }

  void addError(Object error, [StackTrace stackTrace]) {
    if (_isClosed) {
      throw StateError("Sink is closed");
    }
    if (callback != null) {
      callback.onError(error, stackTrace, _sink);
    } else {
      _sink.addError(error, stackTrace);
    }
  }

  void close() {
    if (_isClosed) return;
    var sink = _sink;
    _sink = null;
    if (callback != null) {
      callback.onDone(sink);
    } else {
      sink.close();
    }
  }
}


abstract class _PendingEvents<T> {
  // No async event has been scheduled.
  static const int _STATE_UNSCHEDULED = 0;
  // An async event has been scheduled to run a function.
  static const int _STATE_SCHEDULED = 1;
  // An async event has been scheduled, but it will do nothing when it runs.
  // Async events can't be preempted.
  static const int _STATE_CANCELED = 3;

  /**
   * State of being scheduled.
   *
   * Set to [_STATE_SCHEDULED] when pending events are scheduled for
   * async dispatch. Since we can't cancel a [scheduleMicrotask] call, if
   * scheduling is "canceled", the _state is simply set to [_STATE_CANCELED]
   * which will make the async code do nothing except resetting [_state].
   *
   * If events are scheduled while the state is [_STATE_CANCELED], it is
   * merely switched back to [_STATE_SCHEDULED], but no new call to
   * [scheduleMicrotask] is performed.
   */
  int _state = _STATE_UNSCHEDULED;

  bool get isEmpty;

  bool get isScheduled => _state == _STATE_SCHEDULED;
  bool get _eventScheduled => _state >= _STATE_SCHEDULED;

  /**
   * Schedule an event to run later.
   *
   * If called more than once, it should be called with the same dispatch as
   * argument each time. It may reuse an earlier argument in some cases.
   */
  void schedule(_EventDispatch<T> dispatch) {
    if (isScheduled) return;
    assert(!isEmpty);
    if (_eventScheduled) {
      assert(_state == _STATE_CANCELED);
      _state = _STATE_SCHEDULED;
      return;
    }
    scheduleMicrotask(() {
      int oldState = _state;
      _state = _STATE_UNSCHEDULED;
      if (oldState == _STATE_CANCELED) return;
      handleNext(dispatch);
    });
    _state = _STATE_SCHEDULED;
  }

  void cancelSchedule() {
    if (isScheduled) _state = _STATE_CANCELED;
  }

  void handleNext(_EventDispatch<T> dispatch);

  /** Throw away any pending events and cancel scheduled events. */
  void clear();
}


// Internal helpers.

// Types of the different handlers on a stream. Types used to type fields.
typedef void _DataHandler<T>(T value);
typedef void _DoneHandler();

/** Default data handler, does nothing. */
void _nullDataHandler(Object value) {}

/** Default error handler, reports the error to the current zone's handler. */
void _nullErrorHandler(Object error, [StackTrace stackTrace]) {
  Zone.current.handleUncaughtError(error, stackTrace);
}

/** Default done handler, does nothing. */
void _nullDoneHandler() {}

/** A delayed event on a buffering stream subscription. */
abstract class _DelayedEvent<T> {
  /** Added as a linked list on the [StreamController]. */
  _DelayedEvent next;
  /** Execute the delayed event on the [StreamController]. */
  void perform(_EventDispatch<T> dispatch);
}

/** A delayed data event. */
class _DelayedData<T> extends _DelayedEvent<T> {
  final T value;
  _DelayedData(this.value);
  void perform(_EventDispatch<T> dispatch) {
    dispatch._sendData(value);
  }
}

/** A delayed error event. */
class _DelayedError extends _DelayedEvent {
  final error;
  final StackTrace stackTrace;

  _DelayedError(this.error, this.stackTrace);
  void perform(_EventDispatch dispatch) {
    dispatch._sendError(error, stackTrace);
  }
}

/** A delayed done event. */
class _DelayedDone implements _DelayedEvent {
  const _DelayedDone();
  void perform(_EventDispatch dispatch) {
    dispatch._sendDone();
  }

  _DelayedEvent get next => null;

  void set next(_DelayedEvent _) {
    throw new StateError("No events after a done.");
  }
}

/** Class holding pending events for a [_StreamImpl]. */
class _StreamImplEvents<T> extends _PendingEvents<T> {
  /// Single linked list of [_DelayedEvent] objects.
  _DelayedEvent firstPendingEvent;

  /// Last element in the list of pending events. New events are added after it.
  _DelayedEvent lastPendingEvent;

  bool get isEmpty => lastPendingEvent == null;

  void add(_DelayedEvent event) {
    if (lastPendingEvent == null) {
      firstPendingEvent = lastPendingEvent = event;
    } else {
      lastPendingEvent = lastPendingEvent.next = event;
    }
  }

  void handleNext(_EventDispatch<T> dispatch) {
    assert(!isScheduled);
    _DelayedEvent event = firstPendingEvent;
    firstPendingEvent = event.next;
    if (firstPendingEvent == null) {
      lastPendingEvent = null;
    }
    event.perform(dispatch);
  }

  void clear() {
    if (isScheduled) cancelSchedule();
    firstPendingEvent = lastPendingEvent = null;
  }
}

/** Abstract and private interface for a place to put events. */
abstract class _EventSink<T> {
  void _add(T data);
  void _addError(Object error, StackTrace stackTrace);
  void _close();
}

class _BufferingStreamSubscription<T>
    implements StreamSubscription<T>, EventSink<T>, _EventDispatch<T> {
  /** The `cancelOnError` flag from the `listen` call. */
  static const int _STATE_CANCEL_ON_ERROR = 1;
  /**
   * Whether the "done" event has been received.
   * No further events are accepted after this.
   */
  static const int _STATE_CLOSED = 2;
  /**
   * Set if the input has been asked not to send events.
   *
   * This is not the same as being paused, since the input will remain paused
   * after a call to [resume] if there are pending events.
   */
  static const int _STATE_INPUT_PAUSED = 4;
  /**
   * Whether the subscription has been canceled.
   *
   * Set by calling [cancel], or by handling a "done" event, or an "error" event
   * when `cancelOnError` is true.
   */
  static const int _STATE_CANCELED = 8;
  /**
   * Set when either:
   *
   *   * an error is sent, and [cancelOnError] is true, or
   *   * a done event is sent.
   *
   * If the subscription is canceled while _STATE_WAIT_FOR_CANCEL is set, the
   * state is unset, and no further events must be delivered.
   */
  static const int _STATE_WAIT_FOR_CANCEL = 16;
  static const int _STATE_IN_CALLBACK = 32;
  static const int _STATE_HAS_PENDING = 64;
  static const int _STATE_PAUSE_COUNT = 128;

  /* Event handlers provided in constructor. */
  _DataHandler<T> _onData;
  Function _onError;
  _DoneHandler _onDone;
  final Zone _zone = Zone.current;

  /** Bit vector based on state-constants above. */
  int _state;

  // TODO(floitsch): reuse another field
  /** The future [_onCancel] may return. */
  Future _cancelFuture;

  final Future<void> nullFuture = Future.sync((){

  });

  /**
   * Queue of pending events.
   *
   * Is created when necessary, or set in constructor for preconfigured events.
   */
  _PendingEvents<T> _pending;

  _BufferingStreamSubscription(
      void onData(T data), Function onError, void onDone(), bool cancelOnError)
      : _state = (cancelOnError ? _STATE_CANCEL_ON_ERROR : 0) {
    this.onData(onData);
    this.onError(onError);
    this.onDone(onDone);
  }

  /**
   * Sets the subscription's pending events object.
   *
   * This can only be done once. The pending events object is used for the
   * rest of the subscription's life cycle.
   */
  void _setPendingEvents(_PendingEvents<T> pendingEvents) {
    assert(_pending == null);
    if (pendingEvents == null) return;
    _pending = pendingEvents;
    if (!pendingEvents.isEmpty) {
      _state |= _STATE_HAS_PENDING;
      _pending.schedule(this);
    }
  }

  // StreamSubscription interface.

  void onData(void handleData(T event)) {
    handleData ??= _nullDataHandler;
    // TODO(floitsch): the return type should be 'void', and the type
    // should be inferred.
    _onData = _zone.registerUnaryCallback<dynamic, T>(handleData);
  }

  void onError(Function handleError) {
    handleError ??= _nullErrorHandler;
    if (handleError is void Function(Object, StackTrace)) {
      _onError = _zone
          .registerBinaryCallback<dynamic, Object, StackTrace>(handleError);
    } else if (handleError is void Function(Object)) {
      _onError = _zone.registerUnaryCallback<dynamic, Object>(handleError);
    } else {
      throw new ArgumentError("handleError callback must take either an Object "
          "(the error), or both an Object (the error) and a StackTrace.");
    }
  }

  void onDone(void handleDone()) {
    handleDone ??= _nullDoneHandler;
    _onDone = _zone.registerCallback(handleDone);
  }

  void pause([Future resumeSignal]) {
    if (_isCanceled) return;
    bool wasPaused = _isPaused;
    bool wasInputPaused = _isInputPaused;
    // Increment pause count and mark input paused (if it isn't already).
    _state = (_state + _STATE_PAUSE_COUNT) | _STATE_INPUT_PAUSED;
    if (resumeSignal != null) resumeSignal.whenComplete(resume);
    if (!wasPaused && _pending != null) _pending.cancelSchedule();
    if (!wasInputPaused && !_inCallback) _guardCallback(_onPause);
  }

  void resume() {
    if (_isCanceled) return;
    if (_isPaused) {
      _decrementPauseCount();
      if (!_isPaused) {
        if (_hasPending && !_pending.isEmpty) {
          // Input is still paused.
          _pending.schedule(this);
        } else {
          assert(_mayResumeInput);
          _state &= ~_STATE_INPUT_PAUSED;
          if (!_inCallback) _guardCallback(_onResume);
        }
      }
    }
  }

  Future cancel() {
    // The user doesn't want to receive any further events. If there is an
    // error or done event pending (waiting for the cancel to be done) discard
    // that event.
    _state &= ~_STATE_WAIT_FOR_CANCEL;
    if (!_isCanceled) {
      _cancel();
    }
    return _cancelFuture ?? nullFuture;
  }

  Future<E> asFuture<E>([E futureValue]) {
    Future<E> result = new Future<E>.value(futureValue);
    // Overwrite the onDone and onError handlers.
    return result.asStream().transform(StreamTransformer.fromHandlers(handleError:
        (error, StackTrace stackTrace,EventSink sink){
      Future cancelFuture = cancel();
      if (!identical(cancelFuture, nullFuture)) {
        cancelFuture.whenComplete(() {
          sink.addError(error, stackTrace);
        });
      } else {
        sink.addError(error, stackTrace);
      }
    })).listen((e){

    }).asFuture();


  }

  // State management.

  bool get _isInputPaused => (_state & _STATE_INPUT_PAUSED) != 0;
  bool get _isClosed => (_state & _STATE_CLOSED) != 0;
  bool get _isCanceled => (_state & _STATE_CANCELED) != 0;
  bool get _waitsForCancel => (_state & _STATE_WAIT_FOR_CANCEL) != 0;
  bool get _inCallback => (_state & _STATE_IN_CALLBACK) != 0;
  bool get _hasPending => (_state & _STATE_HAS_PENDING) != 0;
  bool get _isPaused => _state >= _STATE_PAUSE_COUNT;
  bool get _canFire => _state < _STATE_IN_CALLBACK;
  bool get _mayResumeInput =>
      !_isPaused && (_pending == null || _pending.isEmpty);
  bool get _cancelOnError => (_state & _STATE_CANCEL_ON_ERROR) != 0;

  bool get isPaused => _isPaused;

  void _cancel() {
    _state |= _STATE_CANCELED;
    if (_hasPending) {
      _pending.cancelSchedule();
    }
    if (!_inCallback) _pending = null;
    _cancelFuture = _onCancel();
  }

  /**
   * Decrements the pause count.
   *
   * Does not automatically unpause the input (call [_onResume]) when
   * the pause count reaches zero. This is handled elsewhere, and only
   * if there are no pending events buffered.
   */
  void _decrementPauseCount() {
    assert(_isPaused);
    _state -= _STATE_PAUSE_COUNT;
  }

  // _EventSink interface.

  void add(T data) {
    assert(!_isClosed);
    if (_isCanceled) return;
    if (_canFire) {
      _sendData(data);
    } else {
      _addPending(new _DelayedData<T>(data));
    }
  }

  void addError(Object error, [StackTrace stackTrace]){
    if (_isCanceled) return;
    if (_canFire) {
      _sendError(error, stackTrace); // Reports cancel after sending.
    } else {
      _addPending(new _DelayedError(error, stackTrace));
    }
  }

  void close() {
    assert(!_isClosed);
    if (_isCanceled) return;
    _state |= _STATE_CLOSED;
    if (_canFire) {
      _sendDone();
    } else {
      _addPending(const _DelayedDone());
    }
  }

  // Hooks called when the input is paused, unpaused or canceled.
  // These must not throw. If overwritten to call user code, include suitable
  // try/catch wrapping and send any errors to
  // [_Zone.current.handleUncaughtError].
  void _onPause() {
    assert(_isInputPaused);
  }

  void _onResume() {
    assert(!_isInputPaused);
  }

  Future _onCancel() {
    assert(_isCanceled);
    return null;
  }

  // Handle pending events.

  /**
   * Add a pending event.
   *
   * If the subscription is not paused, this also schedules a firing
   * of pending events later (if necessary).
   */
  void _addPending(_DelayedEvent event) {
    _StreamImplEvents<T> pending = _pending;
    if (_pending == null) {
      pending = _pending = new _StreamImplEvents<T>();
    }
    pending.add(event);
    if (!_hasPending) {
      _state |= _STATE_HAS_PENDING;
      if (!_isPaused) {
        _pending.schedule(this);
      }
    }
  }

  /* _EventDispatch interface. */

  void _sendData(T data) {
    assert(!_isCanceled);
    assert(!_isPaused);
    assert(!_inCallback);
    bool wasInputPaused = _isInputPaused;
    _state |= _STATE_IN_CALLBACK;
    _zone.runUnaryGuarded(_onData, data);
    _state &= ~_STATE_IN_CALLBACK;
    _checkState(wasInputPaused);
  }

  void _sendError(Object error, StackTrace stackTrace) {
    assert(!_isCanceled);
    assert(!_isPaused);
    assert(!_inCallback);
    bool wasInputPaused = _isInputPaused;

    void sendError() {
      // If the subscription has been canceled while waiting for the cancel
      // future to finish we must not report the error.
      if (_isCanceled && !_waitsForCancel) return;
      _state |= _STATE_IN_CALLBACK;
      // TODO(floitsch): this dynamic should be 'void'.
      var onError = _onError;
      if (onError is void Function(Object, StackTrace)) {
        _zone.runBinaryGuarded<Object, StackTrace>(onError, error, stackTrace);
      } else {
        assert(_onError is void Function(Object));
        _zone.runUnaryGuarded<Object>(_onError, error);
      }
      _state &= ~_STATE_IN_CALLBACK;
    }

    if (_cancelOnError) {
      _state |= _STATE_WAIT_FOR_CANCEL;
      _cancel();
      if (_cancelFuture != null &&
          !identical(_cancelFuture, nullFuture)) {
        _cancelFuture.whenComplete(sendError);
      } else {
        sendError();
      }
    } else {
      sendError();
      // Only check state if not cancelOnError.
      _checkState(wasInputPaused);
    }
  }

  void _sendDone() {
    assert(!_isCanceled);
    assert(!_isPaused);
    assert(!_inCallback);

    void sendDone() {
      // If the subscription has been canceled while waiting for the cancel
      // future to finish we must not report the done event.
      if (!_waitsForCancel) return;
      _state |= (_STATE_CANCELED | _STATE_CLOSED | _STATE_IN_CALLBACK);
      _zone.runGuarded(_onDone);
      _state &= ~_STATE_IN_CALLBACK;
    }

    _cancel();
    _state |= _STATE_WAIT_FOR_CANCEL;
    if (_cancelFuture != null &&
        !identical(_cancelFuture, nullFuture)) {
      _cancelFuture.whenComplete(sendDone);
    } else {
      sendDone();
    }
  }

  /**
   * Call a hook function.
   *
   * The call is properly wrapped in code to avoid other callbacks
   * during the call, and it checks for state changes after the call
   * that should cause further callbacks.
   */
  void _guardCallback(void callback()) {
    assert(!_inCallback);
    bool wasInputPaused = _isInputPaused;
    _state |= _STATE_IN_CALLBACK;
    callback();
    _state &= ~_STATE_IN_CALLBACK;
    _checkState(wasInputPaused);
  }

  /**
   * Check if the input needs to be informed of state changes.
   *
   * State changes are pausing, resuming and canceling.
   *
   * After canceling, no further callbacks will happen.
   *
   * The cancel callback is called after a user cancel, or after
   * the final done event is sent.
   */
  void _checkState(bool wasInputPaused) {
    assert(!_inCallback);
    if (_hasPending && _pending.isEmpty) {
      _state &= ~_STATE_HAS_PENDING;
      if (_isInputPaused && _mayResumeInput) {
        _state &= ~_STATE_INPUT_PAUSED;
      }
    }
    // If the state changes during a callback, we immediately
    // make a new state-change callback. Loop until the state didn't change.
    while (true) {
      if (_isCanceled) {
        _pending = null;
        return;
      }
      bool isInputPaused = _isInputPaused;
      if (wasInputPaused == isInputPaused) break;
      _state ^= _STATE_IN_CALLBACK;
      if (isInputPaused) {
        _onPause();
      } else {
        _onResume();
      }
      _state &= ~_STATE_IN_CALLBACK;
      wasInputPaused = isInputPaused;
    }
    if (_hasPending && !_isPaused) {
      _pending.schedule(this);
    }
  }
}
