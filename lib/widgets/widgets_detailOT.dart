import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color getPrioridadColor(String? prioridad) {
  if (prioridad == null) return Colors.grey;
  switch (prioridad.toLowerCase()) {
    case 'baja':
      return Colors.blue;
    case 'media':
      return Colors.orange;
    case 'alta':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

Color getEstadoColor(String? estado) {
  if (estado == null) return Colors.grey;
  switch (estado.toLowerCase()) {
    case 'aprobada':
      return Colors.green;
    case 'pendiente':
      return Colors.orange;
    case 'asignada':
      return Colors.blue;
    case 'revisión':
      return Colors.purple;
    case 'devuelta':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String formatDate(String? dateString) {
  if (dateString == null) return 'No disponible';
  try {
    final date = DateFormat('dd/MM/yyyy HH:mm').parse(dateString);
    return DateFormat('dd/MM/yyyy - HH:mm').format(date);
  } catch (e) {
    return dateString;
  }
}