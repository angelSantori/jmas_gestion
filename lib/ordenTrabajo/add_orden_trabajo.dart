import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jmas_gestion/controllers/orden_trabajo_controller.dart';
import 'package:jmas_gestion/controllers/padron_controller.dart';
import 'package:jmas_gestion/widgets/buscar_padron.dart';
import 'package:jmas_gestion/widgets/formularios.dart';
import 'package:jmas_gestion/widgets/generales.dart';
import 'package:jmas_gestion/widgets/mensajes.dart';

class AddOrdenTrabajo extends StatefulWidget {
  final String? userName;
  final String? idUser;
  const AddOrdenTrabajo({super.key, this.userName, this.idUser});

  @override
  State<AddOrdenTrabajo> createState() => _AddOrdenTrabajoState();
}

class _AddOrdenTrabajoState extends State<AddOrdenTrabajo> {
  final OrdenTrabajoController _ordenTrabajoController =
      OrdenTrabajoController();
  final PadronController _padronController = PadronController();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descripcionOTController =
      TextEditingController();
  final TextEditingController _direccionOTController = TextEditingController();
  final TextEditingController _idpadronController = TextEditingController();

  String? _codFolio;
  final String _showFecha = DateFormat('dd/MM/yyyy').format(DateTime.now());

  bool _isLoading = false;

  String? _selectedTipoProblema;
  final List<String> _tipoProblemas = [
    "Problema 1",
    "Problema 2",
    "Problema 3",
    "Problema 4",
  ];

  String? _selectedMedio;
  final List<String> _medios = [
    "Wasa",
    "Fon",
    "Ventanilla",
    "Pitazo",
    "App",
    "Teléfono",
    "Presencial",
    "Inspección",
  ];

  String? _selectedPrioridad;
  final List<String> _prioridades = ["Baja", "Media", "Alta"];

  bool _requiereMaterial = false;

  Padron? _selectedPadron;

  @override
  void initState() {
    super.initState();
    _loadFolioOT();
  }

  Future<void> _loadFolioOT() async {
    final fetchFolioOT = await _ordenTrabajoController.getNextOTFolio();
    setState(() {
      _codFolio = fetchFolioOT;
    });
  }

  // Método de guardado mejorado
  Future<void> _guardarOrdenTrabajo() async {
    // Primero validamos el formulario básico
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Luego validamos que se haya seleccionado un padrón
    if (_selectedPadron == null) {
      showAdvertence(context, 'Debe seleccionar un padrón');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ordenTrabajo = _crearOT();
      final success = await _ordenTrabajoController.addOrdenTrabajo(
        ordenTrabajo,
      );

      if (success && mounted) {
        showOk(context, 'Orden de trabajo guardada exitosamente');
        _limpiarFormulario();
      } else if (mounted) {
        showError(context, 'Error al guardar la orden de trabajo');
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al guardar la orden de trabajo');
        print('Error al guardar la orden de trabajo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    setState(() {
      _descripcionOTController.clear();
      _direccionOTController.clear();
      _idpadronController.clear();
      _selectedMedio = null;
      _selectedPrioridad = null;
      _selectedTipoProblema = null;
      _requiereMaterial = false;
      _selectedPadron = null;
      _loadFolioOT(); // Recargar folio para nueva orden
    });
  }

  OrdenTrabajo _crearOT() {
    return OrdenTrabajo(
      idOrdenTrabajo: 0,
      folioOT: _codFolio,
      descripcionOT: _descripcionOTController.text,
      fechaOT: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      medioOT: _selectedMedio,
      materialOT: _requiereMaterial,
      direccionOT: _direccionOTController.text,
      tipoProblemaOT: _selectedTipoProblema,
      estadoOT: 'Pendiente',
      prioridadOT: _selectedPrioridad,
      idUser: int.tryParse(widget.idUser!),
      idPadron: _selectedPadron?.idPadron,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      // Cabeceras
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: buildCabeceraItem(
                              'Folio',
                              _codFolio ?? 'Cargando...',
                            ),
                          ),
                          Expanded(
                            child: buildCabeceraItem('Fecha', _showFecha),
                          ),
                          Expanded(
                            child: buildCabeceraItem(
                              'Captura',
                              widget.userName!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Contenido principal
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.95,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Columna izquierda (campos)
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  DividerWithText(
                                    text: 'Información del Problema',
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextFielTexto(
                                          controller: _descripcionOTController,
                                          labelText: 'Descripción del problema',
                                          validator: (desc) {
                                            if (desc == null || desc.isEmpty) {
                                              return 'Descripción obligatoria';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextFielTexto(
                                          controller: _direccionOTController,
                                          labelText: 'Dirección',
                                          validator: (direc) {
                                            if (direc == null ||
                                                direc.isEmpty) {
                                              return 'Dirección obligatoria';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 20),

                                      Expanded(
                                        child: CustomListaDesplegable(
                                          value: _selectedMedio,
                                          labelText: 'Medio',
                                          items: _medios,
                                          onChanged: (medio) {
                                            setState(() {
                                              _selectedMedio = medio;
                                            });
                                          },
                                          validator: (medio) {
                                            if (medio == null ||
                                                medio.isEmpty) {
                                              return 'Medio obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomListaDesplegable(
                                          value: _selectedTipoProblema,
                                          labelText: 'Tipo de Problema',
                                          items: _tipoProblemas,
                                          onChanged: (tProblema) {
                                            setState(() {
                                              _selectedTipoProblema = tProblema;
                                            });
                                          },
                                          validator: (tProblema) {
                                            if (tProblema == null ||
                                                tProblema.isEmpty) {
                                              return 'Tipo de problema obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 20),

                                      Expanded(
                                        child: CustomListaDesplegable(
                                          value: _selectedPrioridad,
                                          labelText: 'Prioridad',
                                          items: _prioridades,
                                          onChanged: (prioridad) {
                                            setState(() {
                                              _selectedPrioridad = prioridad;
                                            });
                                          },
                                          validator: (prioridad) {
                                            if (prioridad == null ||
                                                prioridad.isEmpty) {
                                              return 'Prioridad obligatorio';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),

                                  // Requiere material
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Requiere material:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.blue.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Contenedor para el switch con etiquetas
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade200,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'No',
                                              style: TextStyle(
                                                color:
                                                    !_requiereMaterial
                                                        ? Colors.blue.shade900
                                                        : Colors.grey,
                                                fontWeight:
                                                    !_requiereMaterial
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Transform.scale(
                                              scale: 1.2,
                                              child: Switch(
                                                value: _requiereMaterial,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _requiereMaterial = value;
                                                  });
                                                },
                                                activeColor:
                                                    Colors.blue.shade900,
                                                activeTrackColor:
                                                    Colors.blue.shade200,
                                                inactiveTrackColor:
                                                    Colors.grey.shade300,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Sí',
                                              style: TextStyle(
                                                color:
                                                    _requiereMaterial
                                                        ? Colors.blue.shade900
                                                        : Colors.grey,
                                                fontWeight:
                                                    _requiereMaterial
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 60),

                            // Columna derecha (padrón)
                            Expanded(
                              flex: 2,
                              child: BuscarPadronWidgetSalida(
                                idPadronController: _idpadronController,
                                padronController: _padronController,
                                selectedPadron: _selectedPadron,
                                onPadronSeleccionado: (padron) {
                                  setState(() {
                                    _selectedPadron = padron;
                                  });
                                },
                                onAdvertencia: (p0) {
                                  showAdvertence(context, p0);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (_isLoading)
                        Center(
                          child: CircularProgressIndicator(
                            color: Colors.indigo.shade900,
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ElevatedButton(
                          onPressed:
                              (_isLoading || _selectedPadron == null)
                                  ? null
                                  : _guardarOrdenTrabajo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (_selectedPadron == null)
                                    ? Colors.grey
                                    : Colors.indigo.shade900,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'GUARDAR ORDEN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
