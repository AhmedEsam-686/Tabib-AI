// This is a generated file - do not edit.
//
// Generated from rag.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use chatRequestDescriptor instead')
const ChatRequest$json = {
  '1': 'ChatRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'messages',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.medical_rag.Message',
      '10': 'messages'
    },
    {
      '1': 'config',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.medical_rag.GenerationConfig',
      '10': 'config'
    },
  ],
};

/// Descriptor for `ChatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatRequestDescriptor = $convert.base64Decode(
    'CgtDaGF0UmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSMAoIbWVzc2FnZX'
    'MYAiADKAsyFC5tZWRpY2FsX3JhZy5NZXNzYWdlUghtZXNzYWdlcxI1CgZjb25maWcYAyABKAsy'
    'HS5tZWRpY2FsX3JhZy5HZW5lcmF0aW9uQ29uZmlnUgZjb25maWc=');

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'role', '3': 1, '4': 1, '5': 9, '10': 'role'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEhIKBHJvbGUYASABKAlSBHJvbGUSGAoHY29udGVudBgCIAEoCVIHY29udGVudA'
    '==');

@$core.Deprecated('Use generationConfigDescriptor instead')
const GenerationConfig$json = {
  '1': 'GenerationConfig',
  '2': [
    {'1': 'max_tokens', '3': 1, '4': 1, '5': 5, '10': 'maxTokens'},
    {'1': 'temperature', '3': 2, '4': 1, '5': 2, '10': 'temperature'},
    {'1': 'top_p', '3': 3, '4': 1, '5': 2, '10': 'topP'},
  ],
};

/// Descriptor for `GenerationConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generationConfigDescriptor = $convert.base64Decode(
    'ChBHZW5lcmF0aW9uQ29uZmlnEh0KCm1heF90b2tlbnMYASABKAVSCW1heFRva2VucxIgCgt0ZW'
    '1wZXJhdHVyZRgCIAEoAlILdGVtcGVyYXR1cmUSEwoFdG9wX3AYAyABKAJSBHRvcFA=');

@$core.Deprecated('Use chatResponseDescriptor instead')
const ChatResponse$json = {
  '1': 'ChatResponse',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {'1': 'is_finished', '3': 2, '4': 1, '5': 8, '10': 'isFinished'},
  ],
};

/// Descriptor for `ChatResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatResponseDescriptor = $convert.base64Decode(
    'CgxDaGF0UmVzcG9uc2USFAoFdG9rZW4YASABKAlSBXRva2VuEh8KC2lzX2ZpbmlzaGVkGAIgAS'
    'gIUgppc0ZpbmlzaGVk');
