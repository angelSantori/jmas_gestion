import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jmas_gestion/controllers/calles_controller.dart';
import 'package:jmas_gestion/controllers/colonias_controller.dart';
import 'package:jmas_gestion/controllers/medio_controller.dart';
import 'package:jmas_gestion/controllers/orden_servicio_controller.dart';
import 'package:jmas_gestion/controllers/padron_controller.dart';
import 'package:jmas_gestion/controllers/tipo_problema_controller.dart';
import 'package:jmas_gestion/ordenServicio/widgets/buscar_calle_widget.dart';
import 'package:jmas_gestion/ordenServicio/widgets/buscar_colonia_widget.dart';
import 'package:jmas_gestion/ordenServicio/widgets/pdf_os.dart';
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
  final CallesController _callesController = CallesController();
  final ColoniasController _coloniasController = ColoniasController();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _idpadronController = TextEditingController();
  final TextEditingController _idCalleController = TextEditingController();
  final TextEditingController _idColoniaController = TextEditingController();

  final TextEditingController _contactoCTR = TextEditingController();

  String? _codFolio;
  final String _showFecha = DateFormat('dd/MM/yyyy').format(DateTime.now());

  bool _isLoading = false;
  bool _isGeneratingPDF = false;

  String? _selectedPrioridad;
  final List<String> _prioridades = ["Baja", "Media", "Alta"];

  Padron? _selectedPadron;
  Calles? _selectedCalle;
  Colonias? _selectedColonia;

  //  Tipo de problema
  final TipoProblemaController _tipoProblemaController =
      TipoProblemaController();
  List<TipoProblema> _allProblemas = [];
  TipoProblema? _selectedTipoProblema;

  //  Medio
  final MedioController _medioController = MedioController();
  List<Medios> _allMedios = [];
  Medios? _selectedMedio;

  @override
  void initState() {
    super.initState();
    _loadFolioOT();
    _loadData();
  }

  Future<void> _loadFolioOT() async {
    final fetchFolioOT = await _ordenServicioController.getNextOSFolio();
    setState(() {
      _codFolio = fetchFolioOT;
    });
  }

  Future<void> _loadData() async {
    List<TipoProblema> problemas =
        await _tipoProblemaController.listTipoProblema();
    List<Medios> medios = await _medioController.listMedios();
    setState(() {
      _allProblemas = problemas;
      _allMedios = medios;
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
    if (_selectedCalle == null) {
      showAdvertence(context, 'Debe seleccionar una calle');
      return;
    }
    if (_selectedColonia == null) {
      showAdvertence(context, 'Debe seleccionar una colonia');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ordenTrabajo = _crearOS();
      final success = await _ordenServicioController.addOrdenServicio(
        ordenTrabajo,
      );

      if (success && mounted) {
        await generarPDFOrdenServicio(
          padron: _selectedPadron!,
          tipoProblema: _selectedTipoProblema!,
          medio: _selectedMedio!,
          fechaOS: DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
          folioOS: _codFolio!,
          idUser: widget.idUser!,
          userName: widget.userName!,
          prioridadOS: _selectedPrioridad!,
          contacto: _contactoCTR.text,
          selectedCalle: _selectedCalle!,
          selectedColonia: _selectedColonia!,
        );
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
      _idCalleController.clear();
      _idColoniaController.clear();
      _contactoCTR.clear();
      _selectedMedio = null;
      _selectedPrioridad = null;
      _selectedTipoProblema = null;
      _selectedCalle = null;
      _selectedColonia = null;
      _selectedPadron = null;
      _loadFolioOT();
    });
  }

  OrdenServicio _crearOS() {
    return OrdenServicio(
      idOrdenServicio: 0,
      folioOS: _codFolio,
      fechaOS: DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
      estadoOS: 'Pendiente',
      prioridadOS: _selectedPrioridad,
      contactoOS: _contactoCTR.text,
      idUser: int.tryParse(widget.idUser!),
      idPadron: _selectedPadron?.idPadron,
      idTipoProblema: _selectedTipoProblema!.idTipoProblema,
      idMedio: _selectedMedio!.idMedio,
      idCalle: _selectedCalle!.idCalle,
      idColonia: _selectedColonia!.idColonia,
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
                                        child: CustomListaDesplegableTipo<
                                          Medios
                                        >(
                                          value: _selectedMedio,
                                          labelText: 'Medio',
                                          items: _allMedios,
                                          onChanged: (medio) {
                                            setState(() {
                                              _selectedMedio = medio;
                                            });
                                          },
                                          validator: (medioV) {
                                            if (medioV == null) {
                                              return 'Debe seleccionar un medio';
                                            }
                                            return null;
                                          },
                                          itemLabelBuilder:
                                              (medioLB) =>
                                                  '${medioLB.nombreMedio ?? 'Sin Nombre'} - (${medioLB.idMedio})',
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
                                  const SizedBox(height: 30),

                                  //  Calle
                                  Row(
                                    children: [
                                      Expanded(
                                        child: BuscarCalleWidget(
                                          idCalleController: _idCalleController,
                                          callesController: _callesController,
                                          selectedCalle: _selectedCalle,
                                          onCalleSeleccionada: (calle) {
                                            setState(
                                              () => _selectedCalle = calle,
                                            );
                                          },
                                          onAdvertencia: (message) {
                                            showAdvertence(context, message);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                ],
                              ),
                            ),
                            const SizedBox(width: 60),

                            // Columna derecha (padrón)
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  BuscarPadronWidgetSalida(
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
                                  const SizedBox(height: 30),

                                  //  Colonia
                                  Row(
                                    children: [
                                      Expanded(
                                        child: BuscarColoniaWidget(
                                          idColoniaController:
                                              _idColoniaController,
                                          coloniasController:
                                              _coloniasController,
                                          selectedColonia: _selectedColonia,
                                          onColoniaSeleccionada: (colonia) {
                                            setState(
                                              () => _selectedColonia = colonia,
                                            );
                                          },
                                          onAdvertencia: (message) {
                                            showAdvertence(context, message);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                              (_isGeneratingPDF || _isLoading)
                                  ? null
                                  : () async {
                                    setState(() {
                                      _isGeneratingPDF = true;
                                      _isLoading = true;
                                    });

                                    try {
                                      //  Validar campos
                                      bool datosCompletos = await validarCampos(
                                        context: context,
                                        selectedPadron: _selectedPadron,
                                        selectedTipoProblema:
                                            _selectedTipoProblema,
                                        selectedMedio: _selectedMedio,
                                        selectedPrioridad: _selectedPrioridad,
                                        selectedCalle: _selectedCalle,
                                        selectedColonia: _selectedColonia,
                                        contactoController: _contactoCTR,
                                      );

                                      if (!datosCompletos) {
                                        return;
                                      }
                                      await _guardarOrdenServicio();
                                    } catch (e) {
                                      showError(
                                        context,
                                        'Error al guardar la orden de servicio',
                                      );
                                      print(
                                        'Error al guardar la orden de servicio: $e',
                                      );
                                    } finally {
                                      setState(() {
                                        _isGeneratingPDF = false;
                                        _isLoading = false;
                                      });
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isGeneratingPDF
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
