import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jmas_gestion/controllers/orden_trabajo_controller.dart';
import 'package:jmas_gestion/ordenTrabajo/details_orden_trabajo.dart';
import 'package:jmas_gestion/widgets/formularios.dart';

class ListOrdenTrabajo extends StatefulWidget {
  const ListOrdenTrabajo({super.key});

  @override
  State<ListOrdenTrabajo> createState() => _ListOrdenTrabajoState();
}

class _ListOrdenTrabajoState extends State<ListOrdenTrabajo> {
  final OrdenTrabajoController _ordenTrabajoController =
      OrdenTrabajoController();

  final TextEditingController _searchController = TextEditingController();

  List<OrdenTrabajo> _ordenes = [];
  List<OrdenTrabajo> _filteredOrdenes = [];
  bool _isLoading = true;

  // Filtros
  String _searchFolio = '';
  String? _selectedEstado;
  String? _selectedMedio;
  String? _selectedTipoProblema;
  String? _selectedPrioridad;
  DateTimeRange? _fechaRange;

  final List<String> _estados = [
    'Todos',
    'Pendiente',
    'Asignada',
    'Revisión',
    'Devuelta',
    'Aprobada',
  ];

  final List<String> _medios = ["Todos", "Wasa", "Fon", "Ventanilla", "Otro"];

  final List<String> _tipoProblemas = [
    "Todos",
    "Problema 1",
    "Problema 2",
    "Problema 3",
    "Problema 4",
  ];

  final List<String> _prioridades = ["Todos", "Baja", "Media", "Alta"];

  @override
  void initState() {
    super.initState();
    _loadOrdenes();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrdenes() async {
    setState(() => _isLoading = true);
    try {
      _ordenes = await _ordenTrabajoController.listOrdenTrabajo();
      _applyFilters();
    } catch (e) {
      print('Error _loadOrdenes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredOrdenes =
          _ordenes.where((orden) {
            // Filtro por folio
            if (query.isNotEmpty &&
                !(orden.folioOT ?? '').toLowerCase().contains(query)) {
              return false;
            }

            // Filtro por estado
            if (_selectedEstado != null &&
                _selectedEstado != 'Todos' &&
                orden.estadoOT != _selectedEstado) {
              return false;
            }

            if (_selectedPrioridad != null &&
                _selectedPrioridad != 'Todos' &&
                orden.prioridadOT != _selectedPrioridad) {
              return false;
            }

            // Filtro por medio
            if (_selectedMedio != null &&
                _selectedMedio != 'Todos' &&
                orden.medioOT != _selectedMedio) {
              return false;
            }

            // Filtro por tipo de problema
            if (_selectedTipoProblema != null &&
                _selectedTipoProblema != 'Todos' &&
                orden.tipoProblemaOT != _selectedTipoProblema) {
              return false;
            }

            // Filtro por fecha - CORRECCIÓN AQUÍ
            if (_fechaRange != null && orden.fechaOT != null) {
              try {
                // Parseamos la fecha correctamente
                final parts = orden.fechaOT!.split(' ');
                final dateParts = parts[0].split('/');
                final timeParts = parts[1].split(':');

                final fechaOT = DateTime(
                  int.parse(dateParts[2]), // año
                  int.parse(dateParts[1]), // mes
                  int.parse(dateParts[0]), // día
                  int.parse(timeParts[0]), // hora
                  int.parse(timeParts[1]), // minuto
                );

                // Ajustamos el rango de fechas para incluir todo el día
                final startDate = DateTime(
                  _fechaRange!.start.year,
                  _fechaRange!.start.month,
                  _fechaRange!.start.day,
                );

                final endDate = DateTime(
                  _fechaRange!.end.year,
                  _fechaRange!.end.month,
                  _fechaRange!.end.day,
                  23,
                  59,
                  59,
                );

                if (fechaOT.isBefore(startDate) || fechaOT.isAfter(endDate)) {
                  return false;
                }
              } catch (e) {
                print('Error al parsear fecha: ${orden.fechaOT} - $e');
                return false;
              }
            }

            return true;
          }).toList();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaRange = picked;
        _applyFilters();
      });
    }
  }

  Color _getEstadoColor(String? estado) {
    if (estado == null) return Colors.grey;

    switch (estado.toLowerCase()) {
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.grey.shade800;
      case 'pendiente':
        return Colors.orange;
      case 'asignada':
        return Colors.blue;
      case 'revisión':
        return Colors.purple;
      case 'devuelta':
        return Colors.red;
      case 'cerrada':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  Color _getPrioridadColor(String? prioridad) {
    if (prioridad == null) return Colors.grey;
    switch (prioridad.toLowerCase()) {
      case 'baja':
        return Colors.blue;
      case 'media':
        return Colors.orange;
      case 'alta':
        return Colors.red;
      case 'cerrada':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchFolio = '';
      _selectedEstado = null;
      _selectedPrioridad = null;
      _selectedMedio = null;
      _selectedTipoProblema = null;
      _fechaRange = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Listado de Órdenes de Trabajo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrdenes),
          if (_searchFolio.isNotEmpty ||
              _selectedEstado != null ||
              _selectedPrioridad != null ||
              _selectedMedio != null ||
              _selectedTipoProblema != null ||
              _fechaRange != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Limpiar todos los filtros',
              onPressed: _clearAllFilters,
            ),
        ],
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  // Buscador de folio
                  Row(
                    children: [
                      //Folio
                      Expanded(
                        child: CustomTextFielTexto(
                          controller: _searchController,
                          labelText: 'Buscar por folio',
                          prefixIcon: Icons.search,
                        ),
                      ),
                      const SizedBox(width: 20),

                      //Fecha
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.blue.shade300),
                          ),
                          onPressed: () => _selectDateRange(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _fechaRange == null
                                    ? 'Rango de fechas'
                                    : '${DateFormat('dd/MM/yyyy').format(_fechaRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_fechaRange!.end)}',
                                style: TextStyle(color: Colors.blue.shade900),
                              ),
                              if (_fechaRange != null)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _fechaRange = null;
                                      _applyFilters();
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      //Prioridad
                      Expanded(
                        child: CustomListaDesplegable(
                          value: _selectedPrioridad,
                          labelText: 'Prioridad',
                          items: _prioridades,
                          onChanged: (value) {
                            setState(() {
                              _selectedPrioridad = value;
                              _applyFilters();
                            });
                          },
                          trailingIcon:
                              _selectedPrioridad != null
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _selectedPrioridad = null;
                                      _applyFilters();
                                    },
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 20),

                      //Estado
                      Expanded(
                        child: CustomListaDesplegable(
                          value: _selectedEstado,
                          labelText: 'Estado',
                          items: _estados,
                          onChanged: (value) {
                            setState(() {
                              _selectedEstado = value;
                              _applyFilters();
                            });
                          },
                          trailingIcon:
                              _selectedEstado != null
                                  ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _selectedEstado = null;
                                        _applyFilters();
                                      });
                                    },
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 20),

                      //Medio
                      Expanded(
                        child: CustomListaDesplegable(
                          value: _selectedMedio,
                          labelText: 'Medio',
                          items: _medios,
                          onChanged: (value) {
                            setState(() {
                              _selectedMedio = value;
                              _applyFilters();
                            });
                          },
                          trailingIcon:
                              _selectedMedio != null
                                  ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _selectedMedio = null;
                                        _applyFilters();
                                      });
                                    },
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CustomListaDesplegable(
                          value: _selectedTipoProblema,
                          labelText: 'Tipo Problema',
                          items: _tipoProblemas,
                          onChanged: (value) {
                            setState(() {
                              _selectedTipoProblema = value;
                              _applyFilters();
                            });
                          },
                          trailingIcon:
                              _selectedTipoProblema != null
                                  ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _selectedTipoProblema = null;
                                        _applyFilters();
                                      });
                                    },
                                  )
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Listado
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue.shade900,
                        ),
                      )
                      : _filteredOrdenes.isEmpty
                      ? const Center(
                        child: Text(
                          'No hay órdenes que coincidan con los filtros',
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredOrdenes.length,
                        separatorBuilder:
                            (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final orden = _filteredOrdenes[index];

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade50, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.work_outline,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Información
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Folio
                                        Text(
                                          'Folio: ${orden.folioOT ?? 'No disponible'}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Estado
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(
                                                orden.prioridadOT ??
                                                    'No disponible',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor:
                                                  _getPrioridadColor(
                                                    orden.prioridadOT,
                                                  ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                            ),
                                            const SizedBox(width: 20),
                                            Chip(
                                              label: Text(
                                                orden.estadoOT ??
                                                    'No disponible',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor: _getEstadoColor(
                                                orden.estadoOT,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Fecha
                                        Text(
                                          'Fecha: ${orden.fechaOT ?? 'No disponible'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Medio y Problema
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Medio: ${orden.medioOT ?? 'No disponible'}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Problema: ${orden.tipoProblemaOT ?? 'No disponible'}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        Text(
                                          'Dirección: ${orden.direccionOT}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botón de acción
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => DetailsOrdenTrabajo(
                                                ordenTrabajo: orden,
                                              ),
                                        ),
                                      );
                                      if (result == true) {
                                        await _loadOrdenes();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
