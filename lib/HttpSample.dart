import 'package:lemon_lib/lemon.dart';
import 'dart:core';
import 'package:dio/dio.dart';
import 'User.dart';


@Controller()
class HttpSample{

  @GET(url:"task/{id}")
  void setUser(@Query("user_name")User name,@EXTRA()DioExtra extra,
      @QueryMap()Map params,@Path("id")int id){

  }


  @POST(url:"create_task")
  Future<Response> setUserId(@Field("id")User name,@Body()Map body){
    return null;
  }
}