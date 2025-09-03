import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jmas_gestion/controllers/padron_controller.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:jmas_gestion/controllers/medio_controller.dart';
import 'package:jmas_gestion/controllers/tipo_problema_controller.dart';
import 'package:jmas_gestion/controllers/orden_servicio_controller.dart';

class OrdenesPDF {
  static Future<Uint8List> generarPDFMultiplesOrdenes({
    required List<OrdenServicio> ordenes,
    required List<Medios> medios,
    required List<TipoProblema> tiposProblema,
    required List<Padron> padrones,
    required DateTimeRange rangoFechas,
    required TipoProblema? tipoProblemaFiltro,
  }) async {
    final pdf = pw.Document();

    final fechaGeneracion = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.now());

    // Cargar imagen del logo desde assets
    final logoImage = pw.MemoryImage(
      (await rootBundle.load(
        'assets/images/logo_jmas_sf.png',
      )).buffer.asUint8List(),
    );

    // Estilos
    final headerStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );

    final titleStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );
    final normalStyle = const pw.TextStyle(fontSize: 10);
    final boldStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final smallStyle = const pw.TextStyle(fontSize: 8);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 36,
          marginRight: 36,
          marginTop: 36,
          marginBottom: 36,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: pw.Image(logoImage),
                    margin: const pw.EdgeInsets.only(right: 10),
                  ),
                  // Información de la organización
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'JUNTA MUNICIPAL DE AGUA Y SANEAMIENTO DE MEOQUI',
                          style: headerStyle,
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'REPORTE DE ÓRDENES DE SERVICIO',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Divider(thickness: 1),
              pw.SizedBox(height: 15),

              // Información del reporte
              pw.Text('INFORMACIÓN DEL REPORTE', style: titleStyle),
              pw.SizedBox(height: 10),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Rango de fechas:', style: boldStyle),
                      pw.Text(
                        '${DateFormat('dd/MM/yyyy').format(rangoFechas.start)} - ${DateFormat('dd/MM/yyyy').format(rangoFechas.end)}',
                        style: normalStyle,
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 50),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Tipo de servicio:', style: boldStyle),
                      pw.Text(
                        tipoProblemaFiltro != null
                            ? '${tipoProblemaFiltro.idTipoProblema} - ${tipoProblemaFiltro.nombreTP}'
                            : 'Todos',
                        style: normalStyle,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Text('Total de órdenes: ${ordenes.length}', style: boldStyle),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 15),

              // Lista de órdenes
              pw.Text('ÓRDENES DE SERVICIO', style: titleStyle),
              pw.SizedBox(height: 10),

              // Tabla de órdenes - MODIFICADA: quitamos prioridad, medio y estado
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2), // Folio
                  1: const pw.FlexColumnWidth(2), // Fecha
                  2: const pw.FlexColumnWidth(2.5), // Tipo Servicio
                  3: const pw.FlexColumnWidth(1.5), // ID Padrón
                  4: const pw.FlexColumnWidth(3), // Nombre Padrón
                  5: const pw.FlexColumnWidth(3), // Dirección Padrón
                },
                children: [
                  // Encabezado de la tabla - MODIFICADO
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Folio', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Fecha', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Tipo Servicio', style: boldStyle),
                      ),
                      // Nuevos encabezados para padrón
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('ID Padrón', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Nombre Padrón', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Dirección', style: boldStyle),
                      ),
                    ],
                  ),
                  // Datos de las órdenes - MODIFICADO
                  ...ordenes.map((orden) {
                    final tipoProblema = tiposProblema.firstWhere(
                      (tp) => tp.idTipoProblema == orden.idTipoProblema,
                      orElse: () => TipoProblema(),
                    );

                    // Obtener información del padrón
                    final padron = padrones.firstWhere(
                      (p) => p.idPadron == orden.idPadron,
                      orElse: () => Padron(),
                    );

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            orden.folioOS ?? 'N/A',
                            style: smallStyle,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            orden.fechaOS ?? 'N/A',
                            style: smallStyle,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            tipoProblema.nombreTP ?? 'N/A',
                            style: smallStyle,
                          ),
                        ),
                        // Nuevos campos para padrón
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            padron.idPadron?.toString() ?? 'N/A',
                            style: smallStyle,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            padron.padronNombre ?? 'N/A',
                            style: smallStyle,
                            maxLines: 2,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            padron.padronDireccion ?? 'N/A',
                            style: smallStyle,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              // Pie de página
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 1),
              pw.Center(
                child: pw.Text(
                  'Generado el $fechaGeneracion',
                  style: smallStyle,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> descargarPDF({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      // ignore: unused_local_variable
      final anchor =
          html.AnchorElement(href: url)
            ..target = '_blank'
            ..download = fileName
            ..click();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error al descargar PDF: $e');
      throw Exception('Error al descargar el PDF');
    }
  }
}
