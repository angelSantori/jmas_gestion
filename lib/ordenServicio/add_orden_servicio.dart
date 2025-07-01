import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jmas_gestion/controllers/orden_servicio_controller.dart';
import 'package:jmas_gestion/controllers/padron_controller.dart';
import 'package:jmas_gestion/controllers/tipo_problema_controller.dart';
import 'package:jmas_gestion/widgets/buscar_padron.dart';
import 'package:jmas_gestion/widgets/formularios.dart';
import 'package:jmas_gestion/widgets/generales.dart';
import 'package:jmas_gestion/widgets/mensajes.dart';

class AddOrdenServicio extends StatefulWidget {
  final String? userName;
  final String? idUser;
  const AddOrdenServicio({super.key, this.userName, this.idUser});

  @override
  State<AddOrdenServicio> createState() => _AddOrdenServicioState();
}

class _AddOrdenServicioState extends State<AddOrdenServicio> {
  final OrdenServicioController _ordenServicioController =
      OrdenServicioController();
  final PadronController _padronController = PadronController();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _idpadronController = TextEditingController();

  final TextEditingController _contactoCTR = TextEditingController();

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
    final fetchFolioOT = await _ordenServicioController.getNextOSFolio();
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

  Future<void> _guardarOrdenServicio() async {
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
      final ordenTrabajo = _crearOS();
      final success = await _ordenServicioController.addOrdenServicio(
        ordenTrabajo,
      );

      if (success && mounted) {
        showOk(context, 'Orden de servicio registrada exitosamente');
        _limpiarFormulario();
      } else if (mounted) {
        showError(context, 'Error al registrar la orden de servicio');
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al registrar la orden de servicio');
        print('Error al registrar la orden de servicio: $e');
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
      _contactoCTR.clear();
      _selectedMedio = null;
      _selectedPrioridad = null;
      _selectedTipoProblema = null;
      _selectedPadron = null;
      _loadFolioOT(); // Recargar folio para nueva orden
    });
  }

  OrdenServicio _crearOS() {
    return OrdenServicio(
      idOrdenServicio: 0,
      folioOS: _codFolio,
      fechaOS: DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
      medioOS: _selectedMedio,
      estadoOS: 'Pendiente',
      prioridadOS: _selectedPrioridad,
      contactoOS: int.tryParse(_contactoCTR.text),
      idUser: int.tryParse(widget.idUser!),
      idPadron: _selectedPadron?.idPadron,
      idTipoProblema: _selectedTipoProblema!.idTipoProblema,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agregar Orden de Servicio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
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
                                      //  Medio
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
                                      const SizedBox(width: 20),

                                      //  Tipo Problema
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
                                    ],
                                  ),
                                  const SizedBox(height: 30),

                                  Row(
                                    children: [
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
                                      const SizedBox(width: 20),

                                      //  Contacto
                                      Expanded(
                                        child: CustomTextFieldNumero(
                                          controller: _contactoCTR,
                                          labelText: 'Contacto',
                                          prefixIcon: Icons.phone,
                                          validator: (contacto) {
                                            if (contacto == null ||
                                                contacto.isEmpty) {
                                              return 'Contacto obligatorio';
                                            }
                                            return null;
                                          },
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
                                  : _guardarOrdenServicio,
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
