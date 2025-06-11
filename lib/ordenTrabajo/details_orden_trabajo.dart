//Librerías
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jmas_gestion/controllers/evaluacion_orden_trabajo_controller.dart';
import 'package:jmas_gestion/controllers/orden_trabajo_controller.dart';
import 'package:jmas_gestion/controllers/padron_controller.dart';
import 'package:jmas_gestion/controllers/trabajo_realizado_controller.dart';
import 'package:jmas_gestion/controllers/users_controller.dart';
import 'package:jmas_gestion/service/auth_service.dart';
import 'package:jmas_gestion/widgets/formularios.dart';
import 'package:jmas_gestion/widgets/mensajes.dart';
import 'package:jmas_gestion/widgets/permission_widget.dart';
import 'package:jmas_gestion/widgets/widgets_detailOT.dart';

class DetailsOrdenTrabajo extends StatefulWidget {
  final OrdenTrabajo ordenTrabajo;
  const DetailsOrdenTrabajo({super.key, required this.ordenTrabajo});

  @override
  State<DetailsOrdenTrabajo> createState() => _DetailsOrdenTrabajoState();
}

class _DetailsOrdenTrabajoState extends State<DetailsOrdenTrabajo> {
  final AuthService _authService = AuthService();
  final PadronController _padronController = PadronController();
  final EvaluacionOrdenTrabajoController _evaluacionOrdenTrabajoController =
      EvaluacionOrdenTrabajoController();
  final UsersController _usersController = UsersController();
  final TrabajoRealizadoController _trabajoRealizadoController =
      TrabajoRealizadoController();

  Padron? _padron;
  Users? _user;
  String? idUser;
  EvaluacionOT? _evaluacionOT;
  bool _isLoadingEvaluacion = false;
  List<TrabajoRealizado> _trabajosRealizados = [];
  List<Users> _allUsers = [];
  bool _isLoadingTrabajos = false;

  @override
  void initState() {
    super.initState();
    if (widget.ordenTrabajo.idPadron != null) {
      _loadPadronInfo();
    }
    _getUserId().then((_) {
      _loadUserInfo();
    });
    _loadEvaluacion();
    _loadTrabajosRealizados();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    try {
      final users = await _usersController.listUsers();
      setState(() => _allUsers = users);
    } catch (e) {
      print('Error al cargar todos los usuarios: $e');
    }
  }

  // Y luego modificar _getUserInfo para usar la lista precargada:
  Future<Users?> _getUserInfo(int? userId) async {
    if (userId == null) return null;
    return _allUsers.firstWhere(
      (user) => user.id_User == userId,
      orElse: () => Users(),
    );
  }

  Future<void> _loadTrabajosRealizados() async {
    setState(() => _isLoadingTrabajos = true);
    try {
      final trabajos = await _trabajoRealizadoController.getTRXOtID(
        widget.ordenTrabajo.idOrdenTrabajo!,
      );
      setState(() => _trabajosRealizados = trabajos);
    } catch (e) {
      print('Error _loadTrabajosRealizados | DetailsOrdenTRabajo: $e');
    } finally {
      setState(() => _isLoadingTrabajos = false);
    }
  }

  Future<void> _loadEvaluacion() async {
    setState(() => _isLoadingEvaluacion = true);
    try {
      final evaluaciones = await _evaluacionOrdenTrabajoController.listEvOT();
      final evaluacion = evaluaciones.firstWhere(
        (element) =>
            element.idOrdenTrabajo == widget.ordenTrabajo.idOrdenTrabajo,
        orElse: () => EvaluacionOT(),
      );
      if (evaluacion.idEvaluacionOrdenTrabajo != null) {
        setState(() => _evaluacionOT = evaluacion);
      }
    } catch (e) {
      print('Error al cargar evaluación: $e');
    } finally {
      setState(() => _isLoadingEvaluacion = false);
    }
  }

  Future<void> _loadPadronInfo() async {
    try {
      final padronList = await _padronController.listPadron();
      final foundPadron = padronList.firstWhere(
        (p) => p.idPadron == widget.ordenTrabajo.idPadron,
        orElse: () => Padron(),
      );
      if (foundPadron.idPadron != null) {
        setState(() {
          _padron = foundPadron;
        });
      }
    } catch (e) {
      print('Error al cargar información del padrón: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      if (idUser == null || idUser == '0') return;

      final usersList = await _usersController.listUsers();
      final userId = int.tryParse(idUser!);

      if (userId == null) return;

      final foundUser = usersList.firstWhere(
        (usr) => usr.id_User == userId,
        orElse: () => Users(),
      );

      if (foundUser.id_User != null) {
        setState(() {
          _user = foundUser;
        });
      }
    } catch (e) {
      print('Error al cargar información del usuario: $e');
    }
  }

  Future<void> _getUserId() async {
    final decodeToken = await _authService.decodeToken();
    setState(() {
      idUser = decodeToken?['Id_User'] ?? '0';
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Detalles: ${widget.ordenTrabajo.folioOT}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 2,
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primera fila con Info General y Estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de Datos Generales (izquierda)
                  Expanded(flex: 1, child: _buildInfoCard()),
                  const SizedBox(width: 20),

                  // Tarjeta de Estado y descripción a la derecha
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusSection(),
                        const SizedBox(height: 20),
                        _buildDescriptionSection(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Tarjeta de Ubicación (ancho completo)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildLocationSection()),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: _buildEvaluacionSection()),
                ],
              ),
              const SizedBox(width: 20),

              _buildTrabajosRealizadosSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Datos Generales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRow('Folio', widget.ordenTrabajo.folioOT),
            const Divider(),
            _buildInfoRow('Fecha', formatDate(widget.ordenTrabajo.fechaOT)),
            const Divider(),
            _buildInfoRow('Medio', widget.ordenTrabajo.medioOT),
            const Divider(),
            _buildInfoRow(
              'Tipo de Problema',
              widget.ordenTrabajo.tipoProblemaOT,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado de la Orden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    label: Text(
                      widget.ordenTrabajo.prioridadOT ?? 'No disponible',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    backgroundColor: getPrioridadColor(
                      widget.ordenTrabajo.prioridadOT,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Chip(
                    label: Text(
                      widget.ordenTrabajo.estadoOT ?? 'No disponible',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    backgroundColor: getEstadoColor(
                      widget.ordenTrabajo.estadoOT,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  color:
                      widget.ordenTrabajo.materialOT == true
                          ? Colors.orange
                          : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.ordenTrabajo.materialOT == true
                      ? 'Requiere material'
                      : 'No requiere material',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        widget.ordenTrabajo.materialOT == true
                            ? Colors.orange
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Descripción',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.ordenTrabajo.descripcionOT ??
                    'No hay descripción disponible',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRow('Dirección', widget.ordenTrabajo.direccionOT),
            const SizedBox(height: 10),
            if (_padron != null) ...[
              const Text(
                'Datos del Padrón:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('ID', _padron!.idPadron?.toString()),
              _buildInfoRow('Nombre', _padron!.padronNombre),
              _buildInfoRow('Dirección', _padron!.padronDireccion),
              //const SizedBox(height: 10),
            ],
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     icon: const Icon(Icons.map),
            //     label: const Text('Ver en mapa'),
            //     onPressed: () {
            //       // Implementar navegación a mapa
            //     },
            //     style: ElevatedButton.styleFrom(
            //       padding: const EdgeInsets.symmetric(vertical: 12),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'No disponible',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowCords(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child:
                label == 'Ubicación' &&
                        value != null &&
                        value != 'No disponible'
                    ? InkWell(
                      onTap: () => _openGoogleMaps(value),
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                    : Text(
                      value ?? 'No disponible',
                      style: const TextStyle(fontSize: 16),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluacionSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evaluación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                if (widget.ordenTrabajo.estadoOT == 'Pendiente')
                  PermissionWidget(
                    permission: 'evaluar',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 6,
                            offset: Offset(3, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade900,
                        ),
                        onPressed: () => _showEvaluationDialog(context),
                        child: Text(
                          'Evaluar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoadingEvaluacion)
              Center(
                child: CircularProgressIndicator(color: Colors.indigo.shade900),
              )
            else if (_evaluacionOT != null) ...[
              _buildInfoRow('Fecha', _evaluacionOT?.fechaEOT ?? 'N/A'),
              _buildInfoRow(
                'Comentarios',
                _evaluacionOT?.comentariosEOT ?? 'N/A',
              ),
              const SizedBox(height: 8),
              const Text(
                'Datos del Evaluador:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),

              if (_user != null) ...[
                _buildInfoRow(
                  'Usuario',
                  '${_user!.id_User} - ${_user!.user_Name}',
                ),
                _buildInfoRow('Contacto', _user!.user_Contacto),
              ] else ...[
                _buildInfoRow('Usuario', 'No disponible'),
              ],
            ] else ...[
              _buildInfoRow('Fecha', 'N/A'),
              _buildInfoRow('Comentarios', 'N/A'),
              _buildInfoRow('Revisado por', 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showEvaluationDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String? estadoSeleccionado = 'Aprobar';
    final TextEditingController comentarioController = TextEditingController();
    final EvaluacionOrdenTrabajoController evaluacionController =
        EvaluacionOrdenTrabajoController();
    final OrdenTrabajoController ordenTrabajoController =
        OrdenTrabajoController();

    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Permite actualizar el estado dentro del diálogo
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Evaluar Orden de Trabajo'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSubmitting) // Mostrar indicador de carga si está enviando
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CircularProgressIndicator(),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomListaDesplegable(
                              value: estadoSeleccionado,
                              labelText: 'Estado',
                              items: ['Aprobar', 'Rechazar'],
                              onChanged: (value) {
                                estadoSeleccionado = value;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Seleccione un estado';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextFielTexto(
                        controller: comentarioController,
                        labelText: 'Comentarios',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Deje un comentario';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                  ),
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                            if (formKey.currentState!.validate()) {
                              setState(() => isSubmitting = true);

                              try {
                                // Actualizar estado de la orden de trabajo
                                final nuevoEstado =
                                    estadoSeleccionado == 'Aprobar'
                                        ? 'Aprobada - S/A'
                                        : 'Rechazada';

                                final ordenActualizada = widget.ordenTrabajo
                                    .copyWith(estadoOT: nuevoEstado);

                                // Crear objeto de evaluación
                                final evaluacion = EvaluacionOT(
                                  idEvaluacionOrdenTrabajo: 0,
                                  fechaEOT: DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(DateTime.now()),
                                  comentariosEOT: comentarioController.text,
                                  idUser: int.tryParse(idUser!),
                                  idOrdenTrabajo:
                                      widget.ordenTrabajo.idOrdenTrabajo,
                                );

                                // Enviar cambios al servidor
                                final successEvaluacion =
                                    await evaluacionController.addEvOT(
                                      evaluacion,
                                    );

                                final successOrden =
                                    await ordenTrabajoController
                                        .editOrdenTrabajo(ordenActualizada);

                                if (successEvaluacion && successOrden) {
                                  Navigator.pop(context);
                                  showOk(
                                    context,
                                    'Evaluación enviada con éxito',
                                  );
                                  // Forzar recarga de la página
                                  setState(() {
                                    widget.ordenTrabajo.estadoOT = nuevoEstado;
                                    widget.ordenTrabajo.descripcionOT =
                                        widget.ordenTrabajo.descripcionOT;
                                  });
                                  await _loadEvaluacion();
                                  Navigator.pop(context, true);
                                } else {
                                  Navigator.pop(context);
                                  showError(
                                    context,
                                    'Error al enviar evaluación',
                                  );
                                }
                              } catch (e) {
                                Navigator.pop(context);
                                showError(context, 'Error: ${e.toString()}');
                              }
                            }
                          },
                  child:
                      isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                          : const Text(
                            'Guardar',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTrabajosRealizadosSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Trabajos Realizados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoadingTrabajos)
              Center(
                child: CircularProgressIndicator(color: Colors.indigo.shade900),
              )
            else if (_trabajosRealizados.isEmpty)
              const Text(
                'No hay trabajos realizados registrados',
                style: TextStyle(fontSize: 16),
              )
            else
              ..._trabajosRealizados
                  .map(
                    (listTrabajos) => _buildTrabajoRealizadoCard(listTrabajos),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrabajoRealizadoCard(TrabajoRealizado trabajos) {
    return FutureBuilder<Users?>(
      future: _getUserInfo(trabajos.idUserTR),
      builder: (context, snapshot) {
        String userInfo = 'N/A';
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          userInfo = '${user.id_User} - ${user.user_Name}';
        } else if (trabajos.idUserTR != null) {
          userInfo = '${trabajos.idUserTR} - Usuario no encontrado';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Folio', trabajos.folioTR),
                      _buildInfoRow('Usuario', userInfo),
                      if (trabajos.fechaTR != null)
                        _buildInfoRow('Fecha', trabajos.fechaTR),
                      if (trabajos.ubicacionTR != null)
                        _buildInfoRowCords('Ubicación', trabajos.ubicacionTR),
                      if (trabajos.comentarioTR != null)
                        _buildInfoRow('Comentario', trabajos.comentarioTR),
                      if (trabajos.idSalida != null)
                        _buildInfoRow(
                          'ID Salida',
                          trabajos.idSalida?.toString(),
                        ),
                    ],
                  ),
                ),
                //Fotos
                if (trabajos.fotoAntes64TR != null &&
                    trabajos.fotoAntes64TR!.isNotEmpty &&
                    trabajos.fotoDespues64TR != null &&
                    trabajos.fotoDespues64TR!.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (trabajos.fotoAntes64TR != null)
                          _buildImageFromBase64(
                            trabajos.fotoAntes64TR,
                            'Antes',
                          ),
                        const SizedBox(width: 50),
                        if (trabajos.fotoDespues64TR != null) ...[
                          const SizedBox(height: 8),
                          _buildImageFromBase64(
                            trabajos.fotoDespues64TR,
                            'Después',
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageFromBase64(String? base64String, String label) {
    if (base64String == null || base64String.isEmpty) {
      return Container();
    }

    try {
      final cleanBase64 =
          base64String.contains(',')
              ? base64String.split(',').last
              : base64String;

      return GestureDetector(
        onTap: () => _showImageDialog(context, base64String, label),
        child: Column(
          children: [
            Text(label),
            const SizedBox(height: 4),
            Image.memory(
              base64Decode(cleanBase64),
              height: 120, // Reducimos el tamaño para pantallas pequeñas
              width: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error al decodificar imagen: $e');
      return Column(
        children: [
          Text(label),
          const Icon(Icons.error_outline, color: Colors.red),
        ],
      );
    }
  }

  void _showImageDialog(
    BuildContext context,
    String imageBase64,
    String title,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width *
                    1, // 90% del ancho de pantalla
                maxHeight:
                    MediaQuery.of(context).size.height *
                    1, // 80% del alto de pantalla
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.1, // Escala mínima reducida
                      maxScale: 4.0,
                      child: Image.memory(
                        base64Decode(
                          imageBase64.contains(',')
                              ? imageBase64.split(',').last
                              : imageBase64,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _openGoogleMaps(String location) {
    // Extraer coordenadas si están en formato "lat, lng"
    final coords = location.split(',');
    if (coords.length == 2) {
      final lat = coords[0].trim();
      final lng = coords[1].trim();
      final url = 'https://www.google.com/maps?q=$lat,$lng';
      html.window.open(url, '_blank');
    } else {
      // Si no son coordenadas, hacer búsqueda por dirección
      final url =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}';
      html.window.open(url, '_blank');
    }
  }
}
