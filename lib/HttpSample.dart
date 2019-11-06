import 'dart:io';

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
  @FormUrlEncoded()
  Future<Response> setUserId(@Field("id")User name,@FieldMap()Map body){
    return null;
  }

  @POST(url:"create_task")
  Future<Response> setUserName(@Body()Map body){
    return null;
  }

  @POST(url:"send_file")
  Future<Response> sendFile(@Multipart("file1") File file1,@Multipart("file2") File file2){
    return null;
  }

}