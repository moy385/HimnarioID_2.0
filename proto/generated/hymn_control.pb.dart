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

import 'hymn_control.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'hymn_control.pbenum.dart';

class Empty extends $pb.GeneratedMessage {
  factory Empty() => create();

  Empty._();

  factory Empty.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Empty.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Empty',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'himnario'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty copyWith(void Function(Empty) updates) =>
      super.copyWith((message) => updates(message as Empty)) as Empty;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Empty create() => Empty._();
  @$core.override
  Empty createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Empty>(create);
  static Empty? _defaultInstance;
}

class CommandRequest extends $pb.GeneratedMessage {
  factory CommandRequest({
    CommandType? type,
    $core.int? stanzaIndex,
    $core.int? semitones,
    $core.int? hymnId,
    $core.String? backgroundId,
    $core.double? fontSize,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (stanzaIndex != null) result.stanzaIndex = stanzaIndex;
    if (semitones != null) result.semitones = semitones;
    if (hymnId != null) result.hymnId = hymnId;
    if (backgroundId != null) result.backgroundId = backgroundId;
    if (fontSize != null) result.fontSize = fontSize;
    return result;
  }

  CommandRequest._();

  factory CommandRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CommandRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CommandRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'himnario'),
      createEmptyInstance: create)
    ..aE<CommandType>(1, _omitFieldNames ? '' : 'type',
        enumValues: CommandType.values)
    ..aI(2, _omitFieldNames ? '' : 'stanzaIndex')
    ..aI(3, _omitFieldNames ? '' : 'semitones')
    ..aI(4, _omitFieldNames ? '' : 'hymnId')
    ..aOS(5, _omitFieldNames ? '' : 'backgroundId')
    ..aD(6, _omitFieldNames ? '' : 'fontSize', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommandRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommandRequest copyWith(void Function(CommandRequest) updates) =>
      super.copyWith((message) => updates(message as CommandRequest))
          as CommandRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommandRequest create() => CommandRequest._();
  @$core.override
  CommandRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CommandRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommandRequest>(create);
  static CommandRequest? _defaultInstance;

  @$pb.TagNumber(1)
  CommandType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(CommandType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get stanzaIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set stanzaIndex($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStanzaIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearStanzaIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get semitones => $_getIZ(2);
  @$pb.TagNumber(3)
  set semitones($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSemitones() => $_has(2);
  @$pb.TagNumber(3)
  void clearSemitones() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get hymnId => $_getIZ(3);
  @$pb.TagNumber(4)
  set hymnId($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHymnId() => $_has(3);
  @$pb.TagNumber(4)
  void clearHymnId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get backgroundId => $_getSZ(4);
  @$pb.TagNumber(5)
  set backgroundId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBackgroundId() => $_has(4);
  @$pb.TagNumber(5)
  void clearBackgroundId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get fontSize => $_getN(5);
  @$pb.TagNumber(6)
  set fontSize($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFontSize() => $_has(5);
  @$pb.TagNumber(6)
  void clearFontSize() => $_clearField(6);
}

class CommandResponse extends $pb.GeneratedMessage {
  factory CommandResponse({
    $core.bool? success,
    $core.String? errorMessage,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  CommandResponse._();

  factory CommandResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CommandResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CommandResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'himnario'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommandResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommandResponse copyWith(void Function(CommandResponse) updates) =>
      super.copyWith((message) => updates(message as CommandResponse))
          as CommandResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommandResponse create() => CommandResponse._();
  @$core.override
  CommandResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CommandResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommandResponse>(create);
  static CommandResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errorMessage => $_getSZ(1);
  @$pb.TagNumber(2)
  set errorMessage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrorMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrorMessage() => $_clearField(2);
}

class DisplayStatus extends $pb.GeneratedMessage {
  factory DisplayStatus({
    $core.int? currentHymnId,
    $core.String? currentHymnTitle,
    $core.int? currentStanzaIndex,
    $core.int? totalStanzas,
    $core.int? transpositionSemitones,
    $core.bool? isBlackout,
    $core.String? currentBackgroundId,
    $core.double? fontSize,
    $core.String? displayName,
  }) {
    final result = create();
    if (currentHymnId != null) result.currentHymnId = currentHymnId;
    if (currentHymnTitle != null) result.currentHymnTitle = currentHymnTitle;
    if (currentStanzaIndex != null)
      result.currentStanzaIndex = currentStanzaIndex;
    if (totalStanzas != null) result.totalStanzas = totalStanzas;
    if (transpositionSemitones != null)
      result.transpositionSemitones = transpositionSemitones;
    if (isBlackout != null) result.isBlackout = isBlackout;
    if (currentBackgroundId != null)
      result.currentBackgroundId = currentBackgroundId;
    if (fontSize != null) result.fontSize = fontSize;
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  DisplayStatus._();

  factory DisplayStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DisplayStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisplayStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'himnario'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'currentHymnId')
    ..aOS(2, _omitFieldNames ? '' : 'currentHymnTitle')
    ..aI(3, _omitFieldNames ? '' : 'currentStanzaIndex')
    ..aI(4, _omitFieldNames ? '' : 'totalStanzas')
    ..aI(5, _omitFieldNames ? '' : 'transpositionSemitones')
    ..aOB(6, _omitFieldNames ? '' : 'isBlackout')
    ..aOS(7, _omitFieldNames ? '' : 'currentBackgroundId')
    ..aD(8, _omitFieldNames ? '' : 'fontSize', fieldType: $pb.PbFieldType.OF)
    ..aOS(9, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayStatus copyWith(void Function(DisplayStatus) updates) =>
      super.copyWith((message) => updates(message as DisplayStatus))
          as DisplayStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DisplayStatus create() => DisplayStatus._();
  @$core.override
  DisplayStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DisplayStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisplayStatus>(create);
  static DisplayStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get currentHymnId => $_getIZ(0);
  @$pb.TagNumber(1)
  set currentHymnId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCurrentHymnId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCurrentHymnId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get currentHymnTitle => $_getSZ(1);
  @$pb.TagNumber(2)
  set currentHymnTitle($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrentHymnTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrentHymnTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get currentStanzaIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set currentStanzaIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrentStanzaIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrentStanzaIndex() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get totalStanzas => $_getIZ(3);
  @$pb.TagNumber(4)
  set totalStanzas($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalStanzas() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalStanzas() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get transpositionSemitones => $_getIZ(4);
  @$pb.TagNumber(5)
  set transpositionSemitones($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTranspositionSemitones() => $_has(4);
  @$pb.TagNumber(5)
  void clearTranspositionSemitones() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isBlackout => $_getBF(5);
  @$pb.TagNumber(6)
  set isBlackout($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsBlackout() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsBlackout() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get currentBackgroundId => $_getSZ(6);
  @$pb.TagNumber(7)
  set currentBackgroundId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCurrentBackgroundId() => $_has(6);
  @$pb.TagNumber(7)
  void clearCurrentBackgroundId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get fontSize => $_getN(7);
  @$pb.TagNumber(8)
  set fontSize($core.double value) => $_setFloat(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFontSize() => $_has(7);
  @$pb.TagNumber(8)
  void clearFontSize() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get displayName => $_getSZ(8);
  @$pb.TagNumber(9)
  set displayName($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDisplayName() => $_has(8);
  @$pb.TagNumber(9)
  void clearDisplayName() => $_clearField(9);
}

class HandshakeRequest extends $pb.GeneratedMessage {
  factory HandshakeRequest({
    $core.String? clientName,
    $core.String? clientVersion,
    $core.int? protocolVersion,
  }) {
    final result = create();
    if (clientName != null) result.clientName = clientName;
    if (clientVersion != null) result.clientVersion = clientVersion;
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    return result;
  }

  HandshakeRequest._();

  factory HandshakeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HandshakeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HandshakeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'himnario'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'clientName')
    ..aOS(2, _omitFieldNames ? '' : 'clientVersion')
    ..aI(3, _omitFieldNames ? '' : 'protocolVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeRequest copyWith(void Function(HandshakeRequest) updates) =>
      super.copyWith((message) => updates(message as HandshakeRequest))
          as HandshakeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HandshakeRequest create() => HandshakeRequest._();
  @$core.override
  HandshakeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HandshakeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HandshakeRequest>(create);
  static HandshakeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientName => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientName() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get clientVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set clientVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get protocolVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set protocolVersion($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProtocolVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearProtocolVersion() => $_clearField(3);
}

class HandshakeResponse extends $pb.GeneratedMessage {
  factory HandshakeResponse({
    $core.bool? accepted,
    $core.String? serverName,
    $core.String? serverVersion,
    $core.String? displayName,
    $core.int? protocolVersion,
    $core.String? sessionId,
  }) {
    final result = create();
    if (accepted != null) result.accepted = accepted;
    if (serverName != null) result.serverName = serverName;
    if (serverVersion != null) result.serverVersion = serverVersion;
    if (displayName != null) result.displayName = displayName;
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  HandshakeResponse._();

  factory HandshakeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HandshakeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HandshakeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'himnario'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'accepted')
    ..aOS(2, _omitFieldNames ? '' : 'serverName')
    ..aOS(3, _omitFieldNames ? '' : 'serverVersion')
    ..aOS(4, _omitFieldNames ? '' : 'displayName')
    ..aI(5, _omitFieldNames ? '' : 'protocolVersion')
    ..aOS(6, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeResponse copyWith(void Function(HandshakeResponse) updates) =>
      super.copyWith((message) => updates(message as HandshakeResponse))
          as HandshakeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HandshakeResponse create() => HandshakeResponse._();
  @$core.override
  HandshakeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HandshakeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HandshakeResponse>(create);
  static HandshakeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get accepted => $_getBF(0);
  @$pb.TagNumber(1)
  set accepted($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccepted() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccepted() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverName => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerName() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get serverVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServerVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get protocolVersion => $_getIZ(4);
  @$pb.TagNumber(5)
  set protocolVersion($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProtocolVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearProtocolVersion() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get sessionId => $_getSZ(5);
  @$pb.TagNumber(6)
  set sessionId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSessionId() => $_has(5);
  @$pb.TagNumber(6)
  void clearSessionId() => $_clearField(6);
}

class HymnControlApi {
  final $pb.RpcClient _client;

  HymnControlApi(this._client);

  /// Comandos del controlador al display
  $async.Future<CommandResponse> sendCommand(
          $pb.ClientContext? ctx, CommandRequest request) =>
      _client.invoke<CommandResponse>(
          ctx, 'HymnControl', 'SendCommand', request, CommandResponse());

  /// Obtener estado actual del display
  $async.Future<DisplayStatus> getStatus(
          $pb.ClientContext? ctx, Empty request) =>
      _client.invoke<DisplayStatus>(
          ctx, 'HymnControl', 'GetStatus', request, DisplayStatus());

  /// Streaming de estado (el display notifica cambios en tiempo real)
  $async.Future<DisplayStatus> watchStatus(
          $pb.ClientContext? ctx, Empty request) =>
      _client.invoke<DisplayStatus>(
          ctx, 'HymnControl', 'WatchStatus', request, DisplayStatus());

  /// Handshake de conexión inicial
  $async.Future<HandshakeResponse> handshake(
          $pb.ClientContext? ctx, HandshakeRequest request) =>
      _client.invoke<HandshakeResponse>(
          ctx, 'HymnControl', 'Handshake', request, HandshakeResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
