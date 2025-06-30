//Librerías
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jmas_gestion/controllers/evaluacion_orden_servicio_controller.dart';
import 'package:jmas_gestion/controllers/orden_servicio_controller.dart';
import 'package:jmas_gestion/controllers/padron_controller.dart';
import 'package:jmas_gestion/controllers/tipo_problema_controller.dart';
import 'package:jmas_gestion/controllers/trabajo_realizado_controller.dart';
import 'package:jmas_gestion/controllers/users_controller.dart';
import 'package:jmas_gestion/service/auth_service.dart';
import 'package:jmas_gestion/widgets/formularios.dart';
import 'package:jmas_gestion/widgets/mensajes.dart';
import 'package:jmas_gestion/widgets/permission_widget.dart';
import 'package:jmas_gestion/widgets/widgets_detailOT.dart';

class DetailsOrdenServicio extends StatefulWidget {
  final OrdenServicio ordenServicio;
  const DetailsOrdenServicio({super.key, required this.ordenServicio});

  @override
  State<DetailsOrdenServicio> createState() => _DetailsOrdenServicioState();
}

class _DetailsOrdenServicioState extends State<DetailsOrdenServicio> {
  final AuthService _authService = AuthService();
  final PadronController _padronController = PadronController();
  final EvaluacionOrdenServicioController _evaluacionOrdenServicioController =
      EvaluacionOrdenServicioController();
  final UsersController _usersController = UsersController();
  final TrabajoRealizadoController _trabajoRealizadoController =
      TrabajoRealizadoController();
  final TipoProblemaController _tipoProblemaController =
      TipoProblemaController();

  List<TipoProblema> _allTipoProblemas = [];

  Padron? _padron;
  String? idUser;
  Users? _selectedEmpleado;
  // ignore: unused_field
  Users? _evaluador;
  // ignore: unused_field
  EvaluacionOS? _evaluacionOS;
  List<EvaluacionOS> _evaluaciones = [];
  int _currentEvaluacionIndex = 0;
  bool _isLoadingEvaluacion = false;
  List<TrabajoRealizado> _trabajosRealizados = [];
  List<Users> _allUsers = [];
  bool _isLoadingTrabajos = false;
  String? folioTR;

  @override
  void initState() {
    super.initState();

    _loadAllUsers();
    if (widget.ordenServicio.idPadron != null) {
      _loadPadronInfo();
    }
    _loadProblemas();
    _getUserId();
    _loadEvaluacion();
    _loadTrabajosRealizados();

    _loadFolioTR();
  }

  Future<Users?> _loadEvaluadorInfo(int? userId) async {
    if (userId == null) return null;

    try {
      return await _usersController.getUserById(userId);
    } catch (e) {
      print('Error al cargar información del evaluador: $e');
      return null;
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      final users = await _usersController.listUsers();
      setState(() => _allUsers = users);
    } catch (e) {
      print('Error al cargar todos los usuarios: $e');
    }
  }

  Future<void> _loadProblemas() async {
    try {
      _allTipoProblemas = await _tipoProblemaController.listTipoProblema();
    } catch (e) {
      print('Error _loadProblemas | DetailsOrdenTRabajo: $e');
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

  Future<void> _loadFolioTR() async {
    final fetchedFolioTR = await _trabajoRealizadoController.getNextTRFolio();
    setState(() {
      folioTR = fetchedFolioTR;
    });
  }

  Future<bool> _crearTrabajo() async {
    if (_selectedEmpleado == null) return false;
    try {
      final trabajo = TrabajoRealizado(
        idTrabajoRealizado: 0,
        folioTR: folioTR,
        idUserTR: _selectedEmpleado?.id_User,
        idOrdenServicio: widget.ordenServicio.idOrdenServicio,
      );

      return await _trabajoRealizadoController.addTrabajoRealizado(trabajo);
    } catch (e) {
      print('Error _crearTrabajo | addSalidaPage: $e');
      return false;
    }
  }

  Future<void> _loadTrabajosRealizados() async {
    setState(() => _isLoadingTrabajos = true);
    try {
      final trabajos = await _trabajoRealizadoController.getTRXOtID(
        widget.ordenServicio.idOrdenServicio!,
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
      final evaluaciones = await _evaluacionOrdenServicioController.listEvXidOS(
        widget.ordenServicio.idOrdenServicio!,
      );
      if (evaluaciones.isNotEmpty) {
        // ignore: unused_local_variable
        final evaluadores = await Future.wait(
          evaluaciones.map((evs) => _loadEvaluadorInfo(evs.idUser)).toList(),
        );

        setState(() {
          _evaluaciones = evaluaciones;
          _currentEvaluacionIndex = 0;
        });
      } else {
        setState(() {
          _evaluaciones = [];
          _currentEvaluacionIndex = 0;
        });
      }
    } catch (e) {
      print('Error al cargar evaluación: $e');
    } finally {
      setState(() => _isLoadingEvaluacion = false);
    }
  }

  void _nextEvaluacion() {
    if (_evaluaciones.isEmpty) return;
    setState(() {
      _currentEvaluacionIndex =
          (_currentEvaluacionIndex + 1) % _evaluaciones.length;
    });
  }

  void _prevEvaluacion() {
    if (_evaluaciones.isEmpty) return;
    setState(() {
      _currentEvaluacionIndex =
          (_currentEvaluacionIndex - 1) % _evaluaciones.length;
      if (_currentEvaluacionIndex < 0) {
        _currentEvaluacionIndex = _evaluaciones.length - 1;
      }
    });
  }

  Future<void> _loadPadronInfo() async {
    try {
      final padronList = await _padronController.listPadron();
      final foundPadron = padronList.firstWhere(
        (p) => p.idPadron == widget.ordenServicio.idPadron,
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
            'Detalles: ${widget.ordenServicio.folioOS}',
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
                      children: [_buildStatusSection()],
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
    // Obtener nombre del tipo de problema
    final tipoProblema = _allTipoProblemas.firstWhere(
      (tp) => tp.idTipoProblema == widget.ordenServicio.idTipoProblema,
      orElse: () => TipoProblema(),
    );
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
            _buildInfoRow('Folio', widget.ordenServicio.folioOS),
            const Divider(),
            _buildInfoRow('Fecha', formatDate(widget.ordenServicio.fechaOS)),
            const Divider(),
            _buildInfoRow('Medio', widget.ordenServicio.medioOS),
            const Divider(),
            _buildInfoRow(
              'Tipo de Problema',
              '${tipoProblema.nombreTP ?? 'Sin Nombre'} - (${tipoProblema.idTipoProblema})',
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
              'Estado de la Orden de Servicio',
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
                      widget.ordenServicio.prioridadOS ?? 'No disponible',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    backgroundColor: getPrioridadColor(
                      widget.ordenServicio.prioridadOS,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Chip(
                    label: Text(
                      widget.ordenServicio.estadoOS ?? 'No disponible',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    backgroundColor: getEstadoColor(
                      widget.ordenServicio.estadoOS,
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
                      widget.ordenServicio.materialOS == true
                          ? Colors.orange
                          : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.ordenServicio.materialOS == true
                      ? 'Requiere material'
                      : 'No requiere material',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        widget.ordenServicio.materialOS == true
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
                      onTap: () => openGoogleMaps(value),
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
    final currentEvaluacion =
        _evaluaciones.isNotEmpty
            ? _evaluaciones[_currentEvaluacionIndex]
            : null;
    final evaluador =
        currentEvaluacion?.idUser != null
            ? _allUsers.firstWhere(
              (user) => user.id_User == currentEvaluacion?.idUser,
              orElse: () => Users(),
            )
            : null;

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
                Row(
                  children: [
                    const Text(
                      'Evaluación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    if (_evaluaciones.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '${_currentEvaluacionIndex + 1}/${_evaluaciones.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (_evaluaciones.length > 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: _prevEvaluacion,
                        tooltip: 'Evaluación anterior',
                      ),
                    if (_evaluaciones.length > 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: _nextEvaluacion,
                        tooltip: 'Siguiente evaluación',
                      ),
                    if (widget.ordenServicio.estadoOS == 'Pendiente')
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
                    if (widget.ordenServicio.estadoOS == 'Revisión')
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
                            onPressed: () => _showRevisionDialog(context),
                            child: Text(
                              'Revisar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoadingEvaluacion)
              Center(
                child: CircularProgressIndicator(color: Colors.indigo.shade900),
              )
            else if (currentEvaluacion != null) ...[
              _buildInfoRow('Fecha', currentEvaluacion.fechaEOS ?? 'N/A'),
              _buildInfoRow(
                'Comentarios',
                currentEvaluacion.comentariosEOS ?? 'N/A',
              ),
              _buildInfoRow(
                'Estado',
                currentEvaluacion.estadoEnviadoEOS ?? 'N/A',
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
              if (currentEvaluacion.idUser != null) ...[
                _buildInfoRow(
                  'Usuario',
                  '${currentEvaluacion.idUser} - ${evaluador?.user_Name ?? 'No disponible'} (${evaluador?.user_Contacto ?? 'Sin contacto'})',
                ),
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
    final EvaluacionOrdenServicioController evaluacionOSController =
        EvaluacionOrdenServicioController();
    final OrdenServicioController ordenServicioController =
        OrdenServicioController();

    bool isSubmitting = false;
    bool showAsignarUsuario = widget.ordenServicio.materialOS != true;

    // Filtrar solo empleados al inicio
    List<Users> empleados =
        _allUsers.where((user) => user.user_Rol == "Empleado").toList();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Evaluar Orden de Trabajo'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSubmitting)
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
                                setState(() {
                                  estadoSeleccionado = value;
                                  showAsignarUsuario =
                                      widget.ordenServicio.materialOS != true &&
                                      value == 'Aprobar';
                                });
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
                      const SizedBox(height: 16),
                      // Sección para asignar usuario (solo visible cuando corresponda)
                      if (showAsignarUsuario) ...[
                        Row(
                          children: [
                            Expanded(
                              child: CustomListaDesplegableTipo<Users>(
                                value: _selectedEmpleado,
                                labelText: 'Seleccionar Empleado',
                                items: empleados,
                                onChanged: (Users? newValue) {
                                  setState(() {
                                    _selectedEmpleado = newValue;
                                  });
                                },
                                itemLabelBuilder:
                                    (empleado) =>
                                        '${empleado.user_Name ?? 'Sin nombre'} - (${empleado.id_User})',
                              ),
                            ),
                          ],
                        ),
                      ],
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
                                        ? 'Aprobada - A'
                                        : 'Rechazada';

                                final ordenActualizada = widget.ordenServicio
                                    .copyWith(estadoOS: nuevoEstado);

                                // Crear objeto de evaluación
                                final evaluacion = EvaluacionOS(
                                  idEvaluacionOrdenServicio: 0,
                                  fechaEOS: DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(DateTime.now()),
                                  comentariosEOS: comentarioController.text,
                                  estadoEnviadoEOS: estadoSeleccionado,
                                  idUser: int.tryParse(idUser!),
                                  idOrdenServicio:
                                      widget.ordenServicio.idOrdenServicio,
                                );

                                // Enviar cambios al servidor
                                final successEvaluacion =
                                    await evaluacionOSController.addEvOS(
                                      evaluacion,
                                    );

                                final successOrden =
                                    await ordenServicioController
                                        .editOrdenServicio(ordenActualizada);

                                // Si se aprobó y no requiere material, crear trabajo realizado
                                bool successTrabajo = true;
                                if (estadoSeleccionado == 'Aprobar' &&
                                    widget.ordenServicio.materialOS != true &&
                                    _selectedEmpleado != null) {
                                  successTrabajo = await _crearTrabajo();
                                }

                                if (successEvaluacion &&
                                    successOrden &&
                                    successTrabajo) {
                                  Navigator.pop(context);
                                  showOk(
                                    context,
                                    'Evaluación enviada con éxito',
                                  );
                                  // Forzar recarga de la página
                                  setState(() {
                                    widget.ordenServicio.estadoOS = nuevoEstado;
                                  });
                                  await _loadEvaluacion();
                                  await _loadTrabajosRealizados();
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

  Future<void> _showRevisionDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String? estadoSeleccionado = 'Cerrar';
    final TextEditingController comentarioController = TextEditingController();
    final EvaluacionOrdenServicioController evaluacionOSController =
        EvaluacionOrdenServicioController();
    final OrdenServicioController ordenServicioController =
        OrdenServicioController();

    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Revisar Orden de Trabajo'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSubmitting)
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
                              items: ['Cerrar', 'Devolver'],
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
                                    estadoSeleccionado == 'Cerrar'
                                        ? 'Cerrada'
                                        : 'Devuelta';

                                final ordenActualizada = widget.ordenServicio
                                    .copyWith(estadoOS: nuevoEstado);

                                // Crear objeto de evaluación/revisión
                                final evaluacion = EvaluacionOS(
                                  idEvaluacionOrdenServicio: 0,
                                  fechaEOS: DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(DateTime.now()),
                                  comentariosEOS: comentarioController.text,
                                  estadoEnviadoEOS: estadoSeleccionado,
                                  idUser: int.tryParse(idUser!),
                                  idOrdenServicio:
                                      widget.ordenServicio.idOrdenServicio,
                                );

                                // Enviar cambios al servidor
                                final successEvaluacion =
                                    await evaluacionOSController.addEvOS(
                                      evaluacion,
                                    );

                                final successOrden =
                                    await ordenServicioController
                                        .editOrdenServicio(ordenActualizada);

                                if (successEvaluacion && successOrden) {
                                  Navigator.pop(context);
                                  showOk(context, 'Revisión enviada con éxito');

                                  // Actualizar el estado local
                                  setState(() {
                                    widget.ordenServicio.estadoOS = nuevoEstado;
                                  });

                                  await _loadEvaluacion();
                                  Navigator.pop(context, true);
                                } else {
                                  Navigator.pop(context);
                                  showError(
                                    context,
                                    'Error al enviar revisión',
                                  );
                                }
                              } catch (e) {
                                Navigator.pop(context);
                                showError(context, 'Error: ${e.toString()}');
                              } finally {
                                setState(() => isSubmitting = false);
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
        onTap: () => showImageDialog(context, base64String, label),
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
}
