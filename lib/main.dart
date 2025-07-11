import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comprobante de Pedido',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PedidoPage(),
    );
  }
}

class PedidoPage extends StatefulWidget {
  const PedidoPage({super.key});

  @override
  State<PedidoPage> createState() => _PedidoPageState();
}

class _PedidoPageState extends State<PedidoPage> {
  final clienteCtrl = TextEditingController();
  final ciudadCtrl = TextEditingController();
  final comentarioCtrl = TextEditingController();
  final productos = <Map<String, dynamic>>[];

  final codCtrl = TextEditingController();
  final nomCtrl = TextEditingController();
  final uCtrl = TextEditingController();
  final pCtrl = TextEditingController();

  int get bruto => productos.fold<int>(
      0,
      (acc, p) => acc + ((p['u'] as int) * (p['p'] as double)).toInt());

  Future<void> generarPDF() async {
    final pdf = pw.Document();
    final logo = await imageFromAssetBundle('assets/logo.png');
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Image(logo, width: 150)),
            pw.Text("Comprobante de Pedido", style: pw.TextStyle(fontSize: 20)),
            pw.Text("Fecha: \${now.toLocal()}"),
            pw.Text("Cliente: \${clienteCtrl.text}"),
            pw.Text("Ciudad: \${ciudadCtrl.text}"),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Código', 'Nombre', 'U', 'P', 'Total'],
              data: productos.map((p) {
                final total = (p['u'] as int) * (p['p'] as double);
                return [
                  p['cod'],
                  p['nom'],
                  p['u'].toString(),
                  p['p'].toStringAsFixed(0),
                  total.toStringAsFixed(0)
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Subtotal: \$\${bruto.toString()}"),
            pw.Text("Impuestos (19%): \$\${(bruto * 0.19).toStringAsFixed(0)}"),
            pw.Text("Total: \$\${(bruto * 1.19).toStringAsFixed(0)}"),
            pw.SizedBox(height: 10),
            pw.Text("Comentario: \${comentarioCtrl.text}"),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void agregarProducto() {
    if (codCtrl.text.isEmpty ||
        nomCtrl.text.isEmpty ||
        uCtrl.text.isEmpty ||
        pCtrl.text.isEmpty) return;

    productos.add({
      'cod': codCtrl.text,
      'nom': nomCtrl.text,
      'u': int.parse(uCtrl.text),
      'p': double.parse(pCtrl.text),
    });

    codCtrl.clear();
    nomCtrl.clear();
    uCtrl.clear();
    pCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comprobante de Pedido")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            TextField(controller: clienteCtrl, decoration: const InputDecoration(labelText: 'Cliente')),
            TextField(controller: ciudadCtrl, decoration: const InputDecoration(labelText: 'Ciudad')),
            const SizedBox(height: 10),
            const Text("Agregar producto", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: codCtrl, decoration: const InputDecoration(labelText: 'Código')),
            TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: uCtrl, decoration: const InputDecoration(labelText: 'Unidades'), keyboardType: TextInputType.number),
            TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number),
            ElevatedButton(onPressed: agregarProducto, child: const Text("Agregar")),
            const SizedBox(height: 10),
            Text("Productos: \${productos.length}"),
            const SizedBox(height: 10),
            TextField(controller: comentarioCtrl, decoration: const InputDecoration(labelText: 'Comentario')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: generarPDF, child: const Text("Generar PDF")),
          ],
        ),
      ),
    );
  }
}
