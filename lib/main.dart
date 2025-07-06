import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: ComprobanteForm()));
}

class ComprobanteForm extends StatefulWidget {
  const ComprobanteForm({super.key});

  @override
  State<ComprobanteForm> createState() => _ComprobanteFormState();
}

class _ComprobanteFormState extends State<ComprobanteForm> {
  final _formKey = GlobalKey<FormState>();

  String cliente = '';
  String negocio = '';
  String ciudad = '';
  String telefono = '';
  String comentario = '';
  List<Map<String, dynamic>> productos = [];

  final TextEditingController codigoController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController unidadesController = TextEditingController();
  final TextEditingController precioController = TextEditingController();

  static const double tasaIVA = 0.19;

  void addProducto() {
    if (codigoController.text.isEmpty ||
        nombreController.text.isEmpty ||
        unidadesController.text.isEmpty ||
        precioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❗ Completa todos los campos del producto.')));
      return;
    }

    setState(() {
      productos.add({
        "codigo": codigoController.text,
        "nombre": nombreController.text,
        "u": int.tryParse(unidadesController.text) ?? 0,
        "p": int.tryParse(precioController.text) ?? 0,
      });
      codigoController.clear();
      nombreController.clear();
      unidadesController.clear();
      precioController.clear();
    });
  }

  int get bruto => productos.fold(0, (acc, p) => acc + ((p['u'] * p['p']).toInt()));
  int get impuestos => (bruto * tasaIVA).toInt();
  int get total => bruto + impuestos;

  Future<void> exportPDF() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❗ Completa todos los campos obligatorios.')));
      return;
    }

    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final pdf = pw.Document();
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/comprobante_pedido.pdf");

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("DULCENET - COMPROBANTE DE PEDIDO",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Fecha: $now"),
              pw.Text("Cliente: $cliente"),
              pw.Text("Negocio: $negocio"),
              pw.Text("Ciudad: $ciudad"),
              pw.Text("Teléfono: $telefono"),
              pw.SizedBox(height: 10),
              pw.Text("Productos:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Column(
                children: productos.map((p) {
                  final t = p['u'] * p['p'];
                  return pw.Text("${p['codigo']} ${p['nombre']} - ${p['u']} x \$${p['p']} = \$${t}");
                }).toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Text("VALOR BRUTO: \$${bruto}"),
              pw.Text("IMPUESTOS: \$${impuestos}"),
              pw.Text("GRAN TOTAL: \$${total}"),
              pw.SizedBox(height: 10),
              pw.Text("Comentarios: $comentario"),
            ],
          );
        },
      ),
    );

    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📄 PDF guardado en: ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Formulario de Pedido")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Image.asset('assets/logo.png', height: 100),
              TextFormField(
                decoration: const InputDecoration(labelText: "Cliente"),
                onChanged: (v) => cliente = v,
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Negocio"),
                onChanged: (v) => negocio = v,
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Ciudad"),
                onChanged: (v) => ciudad = v,
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Teléfono"),
                onChanged: (v) => telefono = v,
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              const Text("Agregar Producto", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: codigoController, decoration: const InputDecoration(labelText: "Código")),
              TextField(controller: nombreController, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(
                controller: unidadesController,
                decoration: const InputDecoration(labelText: "Unidades"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: precioController,
                decoration: const InputDecoration(labelText: "Precio"),
                keyboardType: TextInputType.number,
              ),
              ElevatedButton(onPressed: addProducto, child: const Text("Agregar producto")),
              const SizedBox(height: 10),
              const Text("Productos agregados:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...productos.asMap().entries.map((entry) {
                final index = entry.key;
                final p = entry.value;
                return ListTile(
                  title: Text(p["nombre"]),
                  subtitle: Text("Unidades: ${p["u"]} - Precio: \$${p["p"]}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Total: \$${p["u"] * p["p"]}"),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            productos.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
              TextFormField(
                decoration: const InputDecoration(labelText: "Comentario"),
                onChanged: (v) => comentario = v,
              ),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: exportPDF, child: const Text("📄 Generar PDF")),
            ],
          ),
        ),
      ),
    );
  }
}
