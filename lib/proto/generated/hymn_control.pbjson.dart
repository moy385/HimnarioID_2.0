// This is a generated file - do not edit.
//
// Generated from hymn_control.proto.

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

@$core.Deprecated('Use commandTypeDescriptor instead')
const CommandType$json = {
  '1': 'CommandType',
  '2': [
    {'1': 'NEXT_STANZA', '2': 0},
    {'1': 'PREV_STANZA', '2': 1},
    {'1': 'GO_TO_CHORUS', '2': 2},
    {'1': 'GO_TO_STANZA', '2': 3},
    {'1': 'BLACKOUT', '2': 4},
    {'1': 'CLEAR_BLACKOUT', '2': 5},
    {'1': 'SET_TRANSPOSITION', '2': 6},
    {'1': 'JUMP_TO_HYMN', '2': 7},
    {'1': 'SET_BACKGROUND', '2': 8},
    {'1': 'SET_FONT_SIZE', '2': 9},
    {'1': 'PING', '2': 10},
  ],
};

/// Descriptor for `CommandType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List commandTypeDescriptor = $convert.base64Decode(
    'CgtDb21tYW5kVHlwZRIPCgtORVhUX1NUQU5aQRAAEg8KC1BSRVZfU1RBTlpBEAESEAoMR09fVE'
    '9fQ0hPUlVTEAISEAoMR09fVE9fU1RBTlpBEAMSDAoIQkxBQ0tPVVQQBBISCg5DTEVBUl9CTEFD'
    'S09VVBAFEhUKEVNFVF9UUkFOU1BPU0lUSU9OEAYSEAoMSlVNUF9UT19IWU1OEAcSEgoOU0VUX0'
    'JBQ0tHUk9VTkQQCBIRCg1TRVRfRk9OVF9TSVpFEAkSCAoEUElORxAK');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use commandRequestDescriptor instead')
const CommandRequest$json = {
  '1': 'CommandRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.himnario.CommandType',
      '10': 'type'
    },
    {'1': 'stanza_index', '3': 2, '4': 1, '5': 5, '10': 'stanzaIndex'},
    {'1': 'semitones', '3': 3, '4': 1, '5': 5, '10': 'semitones'},
    {'1': 'hymn_id', '3': 4, '4': 1, '5': 5, '10': 'hymnId'},
    {'1': 'background_id', '3': 5, '4': 1, '5': 9, '10': 'backgroundId'},
    {'1': 'font_size', '3': 6, '4': 1, '5': 2, '10': 'fontSize'},
  ],
};

/// Descriptor for `CommandRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commandRequestDescriptor = $convert.base64Decode(
    'Cg5Db21tYW5kUmVxdWVzdBIpCgR0eXBlGAEgASgOMhUuaGltbmFyaW8uQ29tbWFuZFR5cGVSBH'
    'R5cGUSIQoMc3RhbnphX2luZGV4GAIgASgFUgtzdGFuemFJbmRleBIcCglzZW1pdG9uZXMYAyAB'
    'KAVSCXNlbWl0b25lcxIXCgdoeW1uX2lkGAQgASgFUgZoeW1uSWQSIwoNYmFja2dyb3VuZF9pZB'
    'gFIAEoCVIMYmFja2dyb3VuZElkEhsKCWZvbnRfc2l6ZRgGIAEoAlIIZm9udFNpemU=');

@$core.Deprecated('Use commandResponseDescriptor instead')
const CommandResponse$json = {
  '1': 'CommandResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error_message', '3': 2, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `CommandResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commandResponseDescriptor = $convert.base64Decode(
    'Cg9Db21tYW5kUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIjCg1lcnJvcl9tZX'
    'NzYWdlGAIgASgJUgxlcnJvck1lc3NhZ2U=');

@$core.Deprecated('Use displayStatusDescriptor instead')
const DisplayStatus$json = {
  '1': 'DisplayStatus',
  '2': [
    {'1': 'current_hymn_id', '3': 1, '4': 1, '5': 5, '10': 'currentHymnId'},
    {
      '1': 'current_hymn_title',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'currentHymnTitle'
    },
    {
      '1': 'current_stanza_index',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'currentStanzaIndex'
    },
    {'1': 'total_stanzas', '3': 4, '4': 1, '5': 5, '10': 'totalStanzas'},
    {
      '1': 'transposition_semitones',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'transpositionSemitones'
    },
    {'1': 'is_blackout', '3': 6, '4': 1, '5': 8, '10': 'isBlackout'},
    {
      '1': 'current_background_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'currentBackgroundId'
    },
    {'1': 'font_size', '3': 8, '4': 1, '5': 2, '10': 'fontSize'},
    {'1': 'display_name', '3': 9, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `DisplayStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List displayStatusDescriptor = $convert.base64Decode(
    'Cg1EaXNwbGF5U3RhdHVzEiYKD2N1cnJlbnRfaHltbl9pZBgBIAEoBVINY3VycmVudEh5bW5JZB'
    'IsChJjdXJyZW50X2h5bW5fdGl0bGUYAiABKAlSEGN1cnJlbnRIeW1uVGl0bGUSMAoUY3VycmVu'
    'dF9zdGFuemFfaW5kZXgYAyABKAVSEmN1cnJlbnRTdGFuemFJbmRleBIjCg10b3RhbF9zdGFuem'
    'FzGAQgASgFUgx0b3RhbFN0YW56YXMSNwoXdHJhbnNwb3NpdGlvbl9zZW1pdG9uZXMYBSABKAVS'
    'FnRyYW5zcG9zaXRpb25TZW1pdG9uZXMSHwoLaXNfYmxhY2tvdXQYBiABKAhSCmlzQmxhY2tvdX'
    'QSMgoVY3VycmVudF9iYWNrZ3JvdW5kX2lkGAcgASgJUhNjdXJyZW50QmFja2dyb3VuZElkEhsK'
    'CWZvbnRfc2l6ZRgIIAEoAlIIZm9udFNpemUSIQoMZGlzcGxheV9uYW1lGAkgASgJUgtkaXNwbG'
    'F5TmFtZQ==');

@$core.Deprecated('Use handshakeRequestDescriptor instead')
const HandshakeRequest$json = {
  '1': 'HandshakeRequest',
  '2': [
    {'1': 'client_name', '3': 1, '4': 1, '5': 9, '10': 'clientName'},
    {'1': 'client_version', '3': 2, '4': 1, '5': 9, '10': 'clientVersion'},
    {'1': 'protocol_version', '3': 3, '4': 1, '5': 5, '10': 'protocolVersion'},
  ],
};

/// Descriptor for `HandshakeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeRequestDescriptor = $convert.base64Decode(
    'ChBIYW5kc2hha2VSZXF1ZXN0Eh8KC2NsaWVudF9uYW1lGAEgASgJUgpjbGllbnROYW1lEiUKDm'
    'NsaWVudF92ZXJzaW9uGAIgASgJUg1jbGllbnRWZXJzaW9uEikKEHByb3RvY29sX3ZlcnNpb24Y'
    'AyABKAVSD3Byb3RvY29sVmVyc2lvbg==');

@$core.Deprecated('Use handshakeResponseDescriptor instead')
const HandshakeResponse$json = {
  '1': 'HandshakeResponse',
  '2': [
    {'1': 'accepted', '3': 1, '4': 1, '5': 8, '10': 'accepted'},
    {'1': 'server_name', '3': 2, '4': 1, '5': 9, '10': 'serverName'},
    {'1': 'server_version', '3': 3, '4': 1, '5': 9, '10': 'serverVersion'},
    {'1': 'display_name', '3': 4, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'protocol_version', '3': 5, '4': 1, '5': 5, '10': 'protocolVersion'},
    {'1': 'session_id', '3': 6, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `HandshakeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeResponseDescriptor = $convert.base64Decode(
    'ChFIYW5kc2hha2VSZXNwb25zZRIaCghhY2NlcHRlZBgBIAEoCFIIYWNjZXB0ZWQSHwoLc2Vydm'
    'VyX25hbWUYAiABKAlSCnNlcnZlck5hbWUSJQoOc2VydmVyX3ZlcnNpb24YAyABKAlSDXNlcnZl'
    'clZlcnNpb24SIQoMZGlzcGxheV9uYW1lGAQgASgJUgtkaXNwbGF5TmFtZRIpChBwcm90b2NvbF'
    '92ZXJzaW9uGAUgASgFUg9wcm90b2NvbFZlcnNpb24SHQoKc2Vzc2lvbl9pZBgGIAEoCVIJc2Vz'
    'c2lvbklk');

const $core.Map<$core.String, $core.dynamic> HymnControlServiceBase$json = {
  '1': 'HymnControl',
  '2': [
    {
      '1': 'SendCommand',
      '2': '.himnario.CommandRequest',
      '3': '.himnario.CommandResponse'
    },
    {'1': 'GetStatus', '2': '.himnario.Empty', '3': '.himnario.DisplayStatus'},
    {
      '1': 'WatchStatus',
      '2': '.himnario.Empty',
      '3': '.himnario.DisplayStatus',
      '6': true
    },
    {
      '1': 'Handshake',
      '2': '.himnario.HandshakeRequest',
      '3': '.himnario.HandshakeResponse'
    },
  ],
};

@$core.Deprecated('Use hymnControlServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    HymnControlServiceBase$messageJson = {
  '.himnario.CommandRequest': CommandRequest$json,
  '.himnario.CommandResponse': CommandResponse$json,
  '.himnario.Empty': Empty$json,
  '.himnario.DisplayStatus': DisplayStatus$json,
  '.himnario.HandshakeRequest': HandshakeRequest$json,
  '.himnario.HandshakeResponse': HandshakeResponse$json,
};

/// Descriptor for `HymnControl`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List hymnControlServiceDescriptor = $convert.base64Decode(
    'CgtIeW1uQ29udHJvbBJCCgtTZW5kQ29tbWFuZBIYLmhpbW5hcmlvLkNvbW1hbmRSZXF1ZXN0Gh'
    'kuaGltbmFyaW8uQ29tbWFuZFJlc3BvbnNlEjUKCUdldFN0YXR1cxIPLmhpbW5hcmlvLkVtcHR5'
    'GhcuaGltbmFyaW8uRGlzcGxheVN0YXR1cxI5CgtXYXRjaFN0YXR1cxIPLmhpbW5hcmlvLkVtcH'
    'R5GhcuaGltbmFyaW8uRGlzcGxheVN0YXR1czABEkQKCUhhbmRzaGFrZRIaLmhpbW5hcmlvLkhh'
    'bmRzaGFrZVJlcXVlc3QaGy5oaW1uYXJpby5IYW5kc2hha2VSZXNwb25zZQ==');
