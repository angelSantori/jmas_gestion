// ignore_for_file: public_member_api_docs, sort_constructors_first
// Librerías
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:jmas_gestion/service/auth_service.dart';

class EvaluacionOrdenTrabajoController {
  final AuthService _authService = AuthService();

  //Get
  //List
  Future<List<EvaluacionOT>> listEvOT() async {
    try {
      final response = await http.get(
        Uri.parse('${_authService.apiURL}/EvaluacionOrdenTrabajoes'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((listEvOT) => EvaluacionOT.fromMap(listEvOT)).toList();
      } else {
        print(
          'Error listEvOT | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error listEvOT | Try | Controller: $e');
      return [];
    }
  }

  //EvOTxidOT
  Future<List<EvaluacionOT>> listEvXidOT(int idOT) async {
    try {
      final response = await http.get(
        Uri.parse('${_authService.apiURL}/EvaluacionOrdenTrabajoes/ByOT/$idOT'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((listEvOTxidOT) => EvaluacionOT.fromMap(listEvOTxidOT))
            .toList();
      } else {
        print(
          'Error listEvXidOT | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error listEvXidOT | Try | Controller: $e');
      return [];
    }
  }

  //POST
  //Add
  Future<bool> addEvOT(EvaluacionOT evaluacionOT) async {
    try {
      final response = await http.post(
        Uri.parse('${_authService.apiURL}/EvaluacionOrdenTrabajoes'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: evaluacionOT.toJson(),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'Error addEvOT | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error addEvOT | Try | Controller: $e');
      return false;
    }
  }
}

class EvaluacionOT {
  int? idEvaluacionOrdenTrabajo;
  String? fechaEOT;
  String? comentariosEOT;
  String? estadoEnviadoEOT;
  int? idUser;
  int? idOrdenTrabajo;
  EvaluacionOT({
    this.idEvaluacionOrdenTrabajo,
    this.fechaEOT,
    this.comentariosEOT,
    this.estadoEnviadoEOT,
    this.idUser,
    this.idOrdenTrabajo,
  });

  EvaluacionOT copyWith({
    int? idEvaluacionOrdenTrabajo,
    String? fechaEOT,
    String? comentariosEOT,
    String? estadoEnviadoEOT,
    int? idUser,
    int? idOrdenTrabajo,
  }) {
    return EvaluacionOT(
      idEvaluacionOrdenTrabajo:
          idEvaluacionOrdenTrabajo ?? this.idEvaluacionOrdenTrabajo,
      fechaEOT: fechaEOT ?? this.fechaEOT,
      comentariosEOT: comentariosEOT ?? this.comentariosEOT,
      estadoEnviadoEOT: estadoEnviadoEOT ?? this.estadoEnviadoEOT,
      idUser: idUser ?? this.idUser,
      idOrdenTrabajo: idOrdenTrabajo ?? this.idOrdenTrabajo,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idEvaluacionOrdenTrabajo': idEvaluacionOrdenTrabajo,
      'fechaEOT': fechaEOT,
      'comentariosEOT': comentariosEOT,
      'estadoEnviadoEOT': estadoEnviadoEOT,
      'idUser': idUser,
      'idOrdenTrabajo': idOrdenTrabajo,
    };
  }

  factory EvaluacionOT.fromMap(Map<String, dynamic> map) {
    return EvaluacionOT(
      idEvaluacionOrdenTrabajo:
          map['idEvaluacionOrdenTrabajo'] != null
              ? map['idEvaluacionOrdenTrabajo'] as int
              : null,
      fechaEOT: map['fechaEOT'] != null ? map['fechaEOT'] as String : null,
      comentariosEOT:
          map['comentariosEOT'] != null
              ? map['comentariosEOT'] as String
              : null,
      estadoEnviadoEOT:
          map['estadoEnviadoEOT'] != null
              ? map['estadoEnviadoEOT'] as String
              : null,
      idUser: map['idUser'] != null ? map['idUser'] as int : null,
      idOrdenTrabajo:
          map['idOrdenTrabajo'] != null ? map['idOrdenTrabajo'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory EvaluacionOT.fromJson(String source) =>
      EvaluacionOT.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EvaluacionOT(idEvaluacionOrdenTrabajo: $idEvaluacionOrdenTrabajo, fechaEOT: $fechaEOT, comentariosEOT: $comentariosEOT, estadoEnviadoEOT: $estadoEnviadoEOT, idUser: $idUser, idOrdenTrabajo: $idOrdenTrabajo)';
  }

  @override
  bool operator ==(covariant EvaluacionOT other) {
    if (identical(this, other)) return true;

    return other.idEvaluacionOrdenTrabajo == idEvaluacionOrdenTrabajo &&
        other.fechaEOT == fechaEOT &&
        other.comentariosEOT == comentariosEOT &&
        other.estadoEnviadoEOT == estadoEnviadoEOT &&
        other.idUser == idUser &&
        other.idOrdenTrabajo == idOrdenTrabajo;
  }

  @override
  int get hashCode {
    return idEvaluacionOrdenTrabajo.hashCode ^
        fechaEOT.hashCode ^
        comentariosEOT.hashCode ^
        estadoEnviadoEOT.hashCode ^
        idUser.hashCode ^
        idOrdenTrabajo.hashCode;
  }
}
