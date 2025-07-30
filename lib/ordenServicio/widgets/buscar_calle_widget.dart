//Librerías
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jmas_gestion/controllers/calles_controller.dart';
import 'package:jmas_gestion/widgets/formularios.dart';
import 'package:jmas_gestion/widgets/generales.dart';
import 'package:jmas_gestion/widgets/mensajes.dart';

class BuscarCalleWidget extends StatefulWidget {
  final TextEditingController idCalleController;
  final CallesController callesController;
  final Calles? selectedCalle;
  final Function(Calles?) onCalleSeleccionada;
  final Function(String) onAdvertencia;
  final bool mostrarOpcionAgregar;

  const BuscarCalleWidget({
    super.key,
    required this.idCalleController,
    required this.callesController,
    this.selectedCalle,
    required this.onCalleSeleccionada,
    required this.onAdvertencia,
    this.mostrarOpcionAgregar = true,
  });

  @override
  State<BuscarCalleWidget> createState() => _BuscarCalleWidgetState();
}

class _BuscarCalleWidgetState extends State<BuscarCalleWidget> {
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final TextEditingController _nombreCalle = TextEditingController();
  List<Calles> _callesSugeridas = [];
  Timer? _debounce;
  bool _mostrarFomrularioAgregar = false;
  final TextEditingController _nuevoNombreCalle = TextEditingController();

  @override
  void dispose() {
    _nombreCalle.dispose();
    _nuevoNombreCalle.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _buscarCalle() async {
    final idCalle = widget.idCalleController.text;
    if (idCalle.isNotEmpty) {
      widget.onCalleSeleccionada(null);
      _isLoading.value = true;

      try {
        final calle =
            await widget.callesController.getCalleXId(int.parse(idCalle));
        if (calle != null) {
          widget.onCalleSeleccionada(calle);
        } else {
          widget.onAdvertencia('Calle con ID: $idCalle, no encontrada');
        }
      } catch (e) {
        widget.onAdvertencia('Error al buscar calle: $e');
      } finally {
        _isLoading.value = false;
      }
    } else {
      widget.onAdvertencia('Por favor, ingrese un ID de calle');
    }
  }

  Future<void> _getCalleXNombre(String query) async {
    if (query.isEmpty) {
      setState(() => _callesSugeridas = []);
      return;
    }
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () async {
        try {
          final calles = await widget.callesController.calleXNombre(query);
          if (mounted) {
            setState(() => _callesSugeridas = calles);
          }
        } catch (e) {
          widget.onAdvertencia('Errir al buscar calle: $e');
          setState(() => _callesSugeridas = []);
        }
      },
    );
  }

  void _seleccionarCalle(Calles calle) {
    widget.idCalleController.text = calle.idCalle.toString();
    widget.onCalleSeleccionada(calle);
    setState(() {
      _callesSugeridas = [];
      _nombreCalle.clear();
      _mostrarFomrularioAgregar = false;
    });
  }

  void _toggleFormularioAgregar() {
    setState(() {
      _mostrarFomrularioAgregar = !_mostrarFomrularioAgregar;
      if (!_mostrarFomrularioAgregar) {
        _nuevoNombreCalle.clear();
      }
    });
  }

  Future<void> _agregarNuevaCalle() async {
    if (_nuevoNombreCalle.text.isEmpty) {
      widget.onAdvertencia('Por favor, ingrese un nombre para la calle');
      return;
    }

    _isLoading.value = true;
    try {
      final nuevaCalle = Calles(
        idCalle: 0,
        calleNombre: _nuevoNombreCalle.text,
      );
      final resultado = await widget.callesController.addCalles(nuevaCalle);

      if (resultado) {
        final calles =
            await widget.callesController.calleXNombre(_nuevoNombreCalle.text);
        if (calles.isNotEmpty) {
          final calleAgregada = calles.first;
          _seleccionarCalle(calleAgregada);
          showOk(context, 'Calle agregada exitosamente');
        } else {
          widget.onAdvertencia('Calle agregada pero no se pudo recuperar');
        }
      } else {
        widget.onAdvertencia('Error al agregar la calle');
      }
    } catch (e) {
      print('Error al agregar la calle: $e');
      widget.onAdvertencia('Error al agregar la colonia: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Widget _buildBuscarXNombre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextFielTexto(
                controller: _nombreCalle,
                labelText: 'Escribe el nombre de la calle',
                prefixIcon: Icons.search,
                onChanged: _getCalleXNombre,
              ),
            ),
            if (widget.mostrarOpcionAgregar && !_mostrarFomrularioAgregar)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Agregar nueva calle',
                onPressed: _toggleFormularioAgregar,
              ),
          ],
        ),
        if (_mostrarFomrularioAgregar)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextFielTexto(
                    controller: _nuevoNombreCalle,
                    labelText: 'Nombre de la nueva calle',
                    prefixIcon: Icons.stream,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _agregarNuevaCalle,
                      child: const Text('Guardar'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _toggleFormularioAgregar,
                      child: const Text('Cancelar'),
                    ),
                  ],
                )
              ],
            ),
          ),
        if (_callesSugeridas.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 500),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _callesSugeridas.length,
              itemBuilder: (context, index) {
                final calle = _callesSugeridas[index];
                return ListTile(
                  title: Text(calle.calleNombre ?? 'Sin nombre'),
                  subtitle: Text(
                      'Id: ${calle.idCalle} \nNombre: ${calle.calleNombre}'),
                  onTap: () => _seleccionarCalle(calle),
                );
              },
            ),
          ),
        if (_callesSugeridas.isEmpty &&
            _nombreCalle.text.isNotEmpty &&
            !_mostrarFomrularioAgregar &&
            widget.mostrarOpcionAgregar)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Text('No se encontraron calles.'),
                TextButton(
                  onPressed: _toggleFormularioAgregar,
                  child: const Text('¿Desea agregar una nueva colonia?'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DividerWithText(text: 'Selección de Calle'),
        const SizedBox(height: 20),
        _buildBuscarXNombre(),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Campo para el ID
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: CustomTextFieldNumero(
                    controller: widget.idCalleController,
                    prefixIcon: Icons.search,
                    labelText: 'Id Calle',
                    onFieldSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _buscarCalle();
                      }
                    },
                  ),
                )
              ],
            ),
            const SizedBox(width: 15),

            //Infotmación
            if (widget.selectedCalle != null)
              Expanded(
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la Calle:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'ID: ${widget.selectedCalle!.idCalle ?? 'No disponible'}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Nombre: ${widget.selectedCalle!.calleNombre ?? 'No disponible'}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )),
                ],
              ))
            else
              const Expanded(
                  flex: 2,
                  child: Text(
                    'No se ha buscado una calle',
                    style: TextStyle(fontSize: 14),
                  ))
          ],
        )
      ],
    );
  }
}
