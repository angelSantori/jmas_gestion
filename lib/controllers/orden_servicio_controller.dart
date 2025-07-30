// ignore_for_file: public_member_api_docs, sort_constructors_first
// Librerías
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:jmas_gestion/service/auth_service.dart';

class OrdenServicioController {
  final AuthService _authService = AuthService();

  //GET
  //List
  Future<List<OrdenServicio>> listOrdenServicio() async {
    try {
      final response = await http.get(
        Uri.parse('${_authService.apiURL}/OrdenServicios'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((listOT) => OrdenServicio.fromMap(listOT)).toList();
      } else {
        print(
          'Error listOrdenServicio | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error listOrdenServicio | Try | Controller: $e');
      return [];
    }
  }

  Future<List<OrdenServicio>> listOSXFolio(String folio) async {
    try {
      final response = await http.get(
        Uri.parse('${_authService.apiURL}/OrdenServicios/ByFolio/$folio'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((listOtXF) => OrdenServicio.fromMap(listOtXF))
            .toList();
      } else {
        print(
          'Error listOTXFolio | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error listOTXFolio | Try | Controller: $e');
      return [];
    }
  }

  Future<String> getNextOSFolio() async {
    try {
      final response = await http.get(
        Uri.parse('${_authService.apiURL}/OrdenServicios/nextOTFolio'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(
          'Error getNextOTFolio | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return '';
      }
    } catch (e) {
      print('Error getNextOTFolio | Try | Controller: $e');
      return '';
    }
  }

  //GetXId
  Future<OrdenServicio?> getOrdenServicioXId(int idOT) async {
    try {
      final response = await http.get(
        Uri.parse('${_authService.apiURL}/OrdenServicios/$idOT'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        return OrdenServicio.fromMap(jsonData);
      } else {
        print(
          'Error getOrdenServicioXId | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getOrdenServicioXId | Try | Controller: $e');
      return null;
    }
  }

  //POST
  //Add
  Future<bool> addOrdenServicio(OrdenServicio ordenServicio) async {
    try {
      final response = await http.post(
        Uri.parse('${_authService.apiURL}/OrdenServicios'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: ordenServicio.toJson(),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'Error addOrdenServicio | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error addOrdenServicio | Try | Controller: $e');
      return false;
    }
  }

  //Put
  //Edit
  Future<bool> editOrdenServicio(OrdenServicio ordenServicio) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${_authService.apiURL}/OrdenServicios/${ordenServicio.idOrdenServicio}',
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: ordenServicio.toJson(),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print(
          'Error editOrdenServicio | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error editOrdenServicio | Try | Controller: $e');
      return false;
    }
  }
}

class OrdenServicio {
  int? idOrdenServicio;
  String? folioOS;
  String? contactoOS;
  String? fechaOS;
  bool? materialOS;
  String? estadoOS;
  String? prioridadOS;
  int? idUser;
  int? idPadron;
  int? idTipoProblema;
  int? idMedio;
  int? idCalle;
  int? idColonia;
  OrdenServicio({
    this.idOrdenServicio,
    this.folioOS,
    this.contactoOS,
    this.fechaOS,
    this.materialOS,
    this.estadoOS,
    this.prioridadOS,
    this.idUser,
    this.idPadron,
    this.idTipoProblema,
    this.idMedio,
    this.idCalle,
    this.idColonia,
  });

  OrdenServicio copyWith({
    int? idOrdenServicio,
    String? folioOS,
    String? contactoOS,
    String? fechaOS,
    bool? materialOS,
    String? estadoOS,
    String? prioridadOS,
    int? idUser,
    int? idPadron,
    int? idTipoProblema,
    int? idMedio,
    int? idCalle,
    int? idColonia,
  }) {
    return OrdenServicio(
      idOrdenServicio: idOrdenServicio ?? this.idOrdenServicio,
      folioOS: folioOS ?? this.folioOS,
      contactoOS: contactoOS ?? this.contactoOS,
      fechaOS: fechaOS ?? this.fechaOS,
      materialOS: materialOS ?? this.materialOS,
      estadoOS: estadoOS ?? this.estadoOS,
      prioridadOS: prioridadOS ?? this.prioridadOS,
      idUser: idUser ?? this.idUser,
      idPadron: idPadron ?? this.idPadron,
      idTipoProblema: idTipoProblema ?? this.idTipoProblema,
      idMedio: idMedio ?? this.idMedio,
      idCalle: idCalle ?? this.idCalle,
      idColonia: idColonia ?? this.idColonia,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idOrdenServicio': idOrdenServicio,
      'folioOS': folioOS,
      'contactoOS': contactoOS,
      'fechaOS': fechaOS,
      'materialOS': materialOS,
      'estadoOS': estadoOS,
      'prioridadOS': prioridadOS,
      'idUser': idUser,
      'idPadron': idPadron,
      'idTipoProblema': idTipoProblema,
      'idMedio': idMedio,
      'idCalle': idCalle,
      'idColonia': idColonia,
    };
  }

  factory OrdenServicio.fromMap(Map<String, dynamic> map) {
    return OrdenServicio(
      idOrdenServicio: map['idOrdenServicio'] != null ? map['idOrdenServicio'] as int : null,
      folioOS: map['folioOS'] != null ? map['folioOS'] as String : null,
      contactoOS: map['contactoOS'] != null ? map['contactoOS'] as String : null,
      fechaOS: map['fechaOS'] != null ? map['fechaOS'] as String : null,
      materialOS: map['materialOS'] != null ? map['materialOS'] as bool : null,
      estadoOS: map['estadoOS'] != null ? map['estadoOS'] as String : null,
      prioridadOS: map['prioridadOS'] != null ? map['prioridadOS'] as String : null,
      idUser: map['idUser'] != null ? map['idUser'] as int : null,
      idPadron: map['idPadron'] != null ? map['idPadron'] as int : null,
      idTipoProblema: map['idTipoProblema'] != null ? map['idTipoProblema'] as int : null,
      idMedio: map['idMedio'] != null ? map['idMedio'] as int : null,
      idCalle: map['idCalle'] != null ? map['idCalle'] as int : null,
      idColonia: map['idColonia'] != null ? map['idColonia'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory OrdenServicio.fromJson(String source) =>
      OrdenServicio.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrdenServicio(idOrdenServicio: $idOrdenServicio, folioOS: $folioOS, contactoOS: $contactoOS, fechaOS: $fechaOS, materialOS: $materialOS, estadoOS: $estadoOS, prioridadOS: $prioridadOS, idUser: $idUser, idPadron: $idPadron, idTipoProblema: $idTipoProblema, idMedio: $idMedio, idCalle: $idCalle, idColonia: $idColonia)';
  }

  @override
  bool operator ==(covariant OrdenServicio other) {
    if (identical(this, other)) return true;
  
    return 
      other.idOrdenServicio == idOrdenServicio &&
      other.folioOS == folioOS &&
      other.contactoOS == contactoOS &&
      other.fechaOS == fechaOS &&
      other.materialOS == materialOS &&
      other.estadoOS == estadoOS &&
      other.prioridadOS == prioridadOS &&
      other.idUser == idUser &&
      other.idPadron == idPadron &&
      other.idTipoProblema == idTipoProblema &&
      other.idMedio == idMedio &&
      other.idCalle == idCalle &&
      other.idColonia == idColonia;
  }

  @override
  int get hashCode {
    return idOrdenServicio.hashCode ^
      folioOS.hashCode ^
      contactoOS.hashCode ^
      fechaOS.hashCode ^
      materialOS.hashCode ^
      estadoOS.hashCode ^
      prioridadOS.hashCode ^
      idUser.hashCode ^
      idPadron.hashCode ^
      idTipoProblema.hashCode ^
      idMedio.hashCode ^
      idCalle.hashCode ^
      idColonia.hashCode;
  }
}
