// This is a generated file - do not edit.
//
// Generated from rag.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'rag.pb.dart' as $0;

export 'rag.pb.dart';

/// خدمة الشات الطبي
@$pb.GrpcServiceName('medical_rag.MedicalChatService')
class MedicalChatServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MedicalChatServiceClient(super.channel, {super.options, super.interceptors});

  /// دالة واحدة تقبل تاريخ المحادثة وتعيد رداً متدفقاً (Streaming)
  $grpc.ResponseStream<$0.ChatResponse> generateStream(
    $0.ChatRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$generateStream, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$generateStream =
      $grpc.ClientMethod<$0.ChatRequest, $0.ChatResponse>(
          '/medical_rag.MedicalChatService/GenerateStream',
          ($0.ChatRequest value) => value.writeToBuffer(),
          $0.ChatResponse.fromBuffer);
}

@$pb.GrpcServiceName('medical_rag.MedicalChatService')
abstract class MedicalChatServiceBase extends $grpc.Service {
  $core.String get $name => 'medical_rag.MedicalChatService';

  MedicalChatServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ChatRequest, $0.ChatResponse>(
        'GenerateStream',
        generateStream_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ChatRequest.fromBuffer(value),
        ($0.ChatResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.ChatResponse> generateStream_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ChatRequest> $request) async* {
    yield* generateStream($call, await $request);
  }

  $async.Stream<$0.ChatResponse> generateStream(
      $grpc.ServiceCall call, $0.ChatRequest request);
}
