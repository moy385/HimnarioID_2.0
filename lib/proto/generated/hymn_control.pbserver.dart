// This is a generated file - do not edit.
//
// Generated from hymn_control.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'hymn_control.pb.dart' as $0;
import 'hymn_control.pbjson.dart';

export 'hymn_control.pb.dart';

abstract class HymnControlServiceBase extends $pb.GeneratedService {
  $async.Future<$0.CommandResponse> sendCommand(
      $pb.ServerContext ctx, $0.CommandRequest request);
  $async.Future<$0.DisplayStatus> getStatus(
      $pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.DisplayStatus> watchStatus(
      $pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.HandshakeResponse> handshake(
      $pb.ServerContext ctx, $0.HandshakeRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'SendCommand':
        return $0.CommandRequest();
      case 'GetStatus':
        return $0.Empty();
      case 'WatchStatus':
        return $0.Empty();
      case 'Handshake':
        return $0.HandshakeRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'SendCommand':
        return sendCommand(ctx, request as $0.CommandRequest);
      case 'GetStatus':
        return getStatus(ctx, request as $0.Empty);
      case 'WatchStatus':
        return watchStatus(ctx, request as $0.Empty);
      case 'Handshake':
        return handshake(ctx, request as $0.HandshakeRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json =>
      HymnControlServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => HymnControlServiceBase$messageJson;
}
