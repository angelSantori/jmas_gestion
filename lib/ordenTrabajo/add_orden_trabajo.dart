import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jmas_gestion/controllers/orden_trabajo_controller.dart';
import 'package:jmas_gestion/controllers/padron_controller.dart';
import 'package:jmas_gestion/controllers/tipo_problema_controller.dart';
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

  final TextEditingController _idpadronController = TextEditingController();

  String? _codFolio;
  final String _showFecha = DateFormat('dd/MM/yyyy').format(DateTime.now());

  bool _isLoading = false;

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

  //  Tipo de problema
  final TipoProblemaController _tipoProblemaController =
      TipoProblemaController();
  List<TipoProblema> _allProblemas = [];
  TipoProblema? _selectedTipoProblema;

  @override
  void initState() {
    super.initState();
    _loadFolioOT();
    _loadTipoProblemas();
  }

  Future<void> _loadFolioOT() async {
    final fetchFolioOT = await _ordenTrabajoController.getNextOTFolio();
    setState(() {
      _codFolio = fetchFolioOT;
    });
  }

  Future<void> _loadTipoProblemas() async {
    List<TipoProblema> problemas =
        await _tipoProblemaController.listTipoProblema();
    setState(() {
      _allProblemas = problemas;
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
      fechaOT: DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
      medioOT: _selectedMedio,
      materialOT: _requiereMaterial,
      estadoOT: 'Pendiente',
      prioridadOT: _selectedPrioridad,
      idUser: int.tryParse(widget.idUser!),
      idPadron: _selectedPadron?.idPadron,
      idTipoProblema: _selectedTipoProblema!.idTipoProblema,
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
                                        child: CustomListaDesplegableTipo<
                                          TipoProblema
                                        >(
                                          value: _selectedTipoProblema,
                                          labelText: 'Tipo de Problema',
                                          items: _allProblemas,
                                          onChanged: (problema) {
                                            setState(() {
                                              _selectedTipoProblema = problema;
                                            });
                                          },
                                          validator: (problema) {
                                            if (problema == null) {
                                              return 'Debe seleccionar un tipo de problema';
                                            }
                                            return null;
                                          },
                                          itemLabelBuilder:
                                              (problema) =>
                                                  '${problema.nombreTP ?? 'Sin nombre'} - (${problema.idTipoProblema})',
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
