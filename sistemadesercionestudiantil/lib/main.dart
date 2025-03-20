import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subir y Leer CSV',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const CSVReaderScreen(),
    );
  }
}

class CSVReaderScreen extends StatefulWidget {
  const CSVReaderScreen({super.key});

  @override
  _CSVReaderScreenState createState() => _CSVReaderScreenState();
}

class _CSVReaderScreenState extends State<CSVReaderScreen> {
  List<List<String>> _csvData = [];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString(encoding: utf8);

      // Corregimos posibles saltos de línea incorrectos
      content = content.replaceAll('\r', '\n');

      List<List<String>> csvTable = const LineSplitter()
          .convert(content)
          .map((line) => line.split(','))
          .toList();

      // Filtramos filas vacías y aseguramos que todas tengan el mismo número de columnas
      if (csvTable.isNotEmpty) {
        int columnCount = csvTable[0].length;
        csvTable = csvTable.where((row) => row.length == columnCount).toList();
      }

      setState(() {
        _csvData = csvTable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir y Leer CSV')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Seleccionar Archivo CSV'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _csvData.isNotEmpty
                    ? DataTable(
                        columns: _csvData[0]
                            .map((header) => DataColumn(label: Text(header)))
                            .toList(),
                        rows: _csvData
                            .skip(1)
                            .map((row) => DataRow(
                                  cells: row
                                      .map((cell) => DataCell(Text(cell)))
                                      .toList(),
                                ))
                            .toList(),
                      )
                    : const Text('No hay datos cargados'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}