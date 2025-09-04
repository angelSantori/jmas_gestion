import 'package:flutter/material.dart';
import 'package:jmas_gestion/controllers/padron_controller.dart';
import 'package:jmas_gestion/ordenServicio/widgets/widgets_detalles.dart';

//  Sección Padrón
Widget buildPadronSection(Padron? padron) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Padrón',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 10),
          if (padron != null) ...[
            buildInfoRow('ID', padron.idPadron?.toString()),
            buildInfoRow('Nombre', padron.padronNombre),
            buildInfoRow('Dirección', padron.padronDireccion),
            //const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
}