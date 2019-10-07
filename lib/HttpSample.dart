import 'package:lemon_lib/lemon.dart';
import 'dart:core';
import 'package:dio/dio.dart';
import 'User.dart';


@Controller()
class HttpSample{

  @GET(url:"www.baidu.com")
  void setUser(@Query("user_name")User name,@EXTRA()Map map,@QueryMap()Map params){

  }


  @POST(url:"www.baidu.com")
  Future<Response> setUserId(@Field("id")User name,@Body()Map body){
    return null;
  }
}