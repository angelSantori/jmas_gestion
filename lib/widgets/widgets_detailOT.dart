// Librerías
import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart';

// Prioridad Colores
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

// Estado Colores
Color getEstadoColor(String? estado) {
  if (estado == null) return Colors.grey;
  switch (estado.toLowerCase()) {
    case 'pendiente':
      return Colors.orange;
    case 'aprobada - s/a':
      return Colors.green;
    case 'aprobada - a':
      return Colors.green.shade900;
    case 'revisión':
      return Colors.purple;
    case 'devuelta':
      return Colors.red;
    case 'cerrada':
      return Colors.blue.shade900;
    default:
      return Colors.grey;
  }
}

// Format Date
String formatDate(String? dateString) {
  if (dateString == null) return 'No disponible';
  try {
    final date = DateFormat('dd/MM/yyyy HH:mm').parse(dateString);
    return DateFormat('dd/MM/yyyy - HH:mm').format(date);
  } catch (e) {
    return dateString;
  }
}

// Maps
void openGoogleMaps(String location) {
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

//Mostrar imagen
void showImageDialog(BuildContext context, String imageBase64, String title) {
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
