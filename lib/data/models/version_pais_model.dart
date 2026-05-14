import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/version_pais.dart';
import 'estrofa_model.dart';

part 'version_pais_model.g.dart';

/// Modelo serializable de VersionPais.
@JsonSerializable()
class VersionPaisModel {
  final int id;
  @JsonKey(name: 'himno_id')
  final int himnoId;
  final String pais;
  @JsonKey(name: 'tonalidad_original')
  final String tonalidadOriginal;
  final bool activo;
  List<EstrofaModel>? estrofas;

  VersionPaisModel({
    required this.id,
    required this.himnoId,
    required this.pais,
    required this.tonalidadOriginal,
    this.activo = true,
    this.estrofas,
  });

  factory VersionPaisModel.fromJson(Map<String, dynamic> json) =>
      _$VersionPaisModelFromJson(json);

  Map<String, dynamic> toJson() => _$VersionPaisModelToJson(this);

  VersionPais toEntity() {
    return VersionPais(
      id: id,
      himnoId: himnoId,
      pais: pais,
      tonalidadOriginal: tonalidadOriginal,
      activo: activo,
      estrofas: estrofas?.map((e) => e.toEntity()).toList() ?? [],
    );
  }

  factory VersionPaisModel.fromMap(Map<String, dynamic> map) {
    return VersionPaisModel(
      id: map['id'] as int,
      himnoId: map['himno_id'] as int,
      pais: map['pais'] as String,
      tonalidadOriginal: map['tonalidad_original'] as String,
      activo: (map['activo'] as int?) == 1,
    );
  }
}
