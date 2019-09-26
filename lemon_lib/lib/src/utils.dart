
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