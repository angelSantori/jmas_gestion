import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jmas_gestion/controllers/evaluacion_orden_trabajo_controller.dart';
import 'package:jmas_gestion/controllers/orden_trabajo_controller.dart';
import 'package:jmas_gestion/controllers/padron_controller.dart';
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

  Padron? _padron;
  String? idUser;
  EvaluacionOT? _evaluacionOT;
  bool _isLoadingEvaluacion = false;

  @override
  void initState() {
    super.initState();
    if (widget.ordenTrabajo.idPadron != null) {
      _loadPadronInfo();
    }
    _getUserId();
    _loadEvaluacion();
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
              const SizedBox(height: 10),
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
              _buildInfoRow(
                'Revisado por',
                _evaluacionOT?.idUser.toString() ?? 'N/A',
              ),
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
                                        ? 'Aprobada'
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
}
