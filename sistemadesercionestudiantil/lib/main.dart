import 'dart:convert'; // Para manejar la codificación y decodificación de texto (UTF-8).
import 'dart:io'; // Para trabajar con archivos y rutas del sistema.
import 'package:file_picker/file_picker.dart'; // Para permitir la selección de archivos desde el dispositivo.
import 'package:flutter/material.dart'; // Para construir la interfaz de usuario.

void main() {
  runApp(const MyApp()); // Inicia la aplicación Flutter.
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configura la aplicación principal con un tema y una pantalla inicial.
    return MaterialApp(
      title: 'Subir y Leer CSV', // Título de la aplicación.
      theme: ThemeData(primarySwatch: Colors.deepPurple), // Tema de la aplicación.
      home: const CSVReaderScreen(), // Pantalla inicial.
    );
  }
}

class CSVReaderScreen extends StatefulWidget {
  const CSVReaderScreen({super.key});

  @override
  _CSVReaderScreenState createState() => _CSVReaderScreenState(); // Crea el estado de la pantalla.
}

class _CSVReaderScreenState extends State<CSVReaderScreen> {
  List<List<String>> _csvData = []; // Almacena los datos del CSV cargado.
  List<List<String>> _studentsAtRisk = []; // Almacena los datos de los alumnos en riesgo de deserción.

  // Función para seleccionar y cargar un archivo CSV.
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'], // Solo permite archivos con extensión CSV.
    );

    if (result != null) {
      File file = File(result.files.single.path!); // Obtiene el archivo seleccionado.
      String content = await file.readAsString(encoding: utf8); // Lee el contenido del archivo en formato UTF-8.

      // Corrige posibles saltos de línea incorrectos.
      content = content.replaceAll('\r', '\n');

      // Convierte el contenido del CSV en una lista de listas (tabla).
      List<List<String>> csvTable = const LineSplitter()
          .convert(content)
          .map((line) => line.split(',')) // Divide cada línea por comas.
          .toList();

      // Filtra filas vacías y asegura que todas tengan el mismo número de columnas.
      if (csvTable.isNotEmpty) {
        int columnCount = csvTable[0].length;
        csvTable = csvTable.where((row) => row.length == columnCount).toList();
      }

      // Actualiza el estado con los datos del CSV y limpia la lista de alumnos en riesgo.
      setState(() {
        _csvData = csvTable;
        _studentsAtRisk.clear();
      });

      // Muestra un mensaje indicando que el archivo se ha subido correctamente.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archivo CSV subido correctamente.'),
          backgroundColor: Colors.green, // Color de fondo del mensaje.
        ),
      );
    }
  }

  // Función para identificar alumnos en riesgo de deserción.
  void _findStudentsAtRisk() {
    if (_csvData.isNotEmpty) {
      // Filtra los alumnos con un promedio menor o igual a 7.
      List<List<String>> filteredStudents = _csvData.skip(1).where((row) {
        List<double> grades = row.sublist(2).map((grade) => double.tryParse(grade) ?? 0).toList(); // Convierte las calificaciones a números.
        double average = grades.reduce((a, b) => a + b) / grades.length; // Calcula el promedio.
        return average <= 7; // Retorna true si el promedio es menor o igual a 7.
      }).toList();

      // Actualiza el estado con los alumnos en riesgo, incluyendo los encabezados.
      setState(() {
        _studentsAtRisk = [
          _csvData[0] // Encabezados
        ] + filteredStudents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construye la interfaz de usuario.
    return Scaffold(
      appBar: AppBar(title: const Text('Subir y Leer CSV')), // Barra superior de la aplicación.
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Espaciado interno.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alineación de los elementos.
          children: [
            // Botón para seleccionar un archivo CSV.
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Seleccionar Archivo CSV'),
            ),
            const SizedBox(height: 10), // Espacio entre botones.
            // Botón para buscar alumnos en riesgo de deserción.
            ElevatedButton(
              onPressed: _findStudentsAtRisk,
              child: const Text('Buscar alumnos en peligro de deserción'),
            ),
            const SizedBox(height: 20), // Espacio adicional.
            // Área para mostrar los datos del CSV o los alumnos en riesgo.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Permite desplazamiento horizontal.
                child: _studentsAtRisk.isNotEmpty
                    ? DataTable(
                        // Crea una tabla con los encabezados.
                        columns: _studentsAtRisk[0]
                            .map((header) => DataColumn(label: Text(header)))
                            .toList(),
                        // Crea las filas de la tabla con los datos de los alumnos en riesgo.
                        rows: _studentsAtRisk
                            .skip(1)
                            .map((row) => DataRow(
                                  cells: row
                                      .map((cell) => DataCell(Text(cell)))
                                      .toList(),
                                ))
                            .toList(),
                      )
                    : const Text('No hay alumnos en peligro de deserción.'), // Mensaje si no hay datos.
              ),
            ),
          ],
        ),
      ),
    );
  }
}