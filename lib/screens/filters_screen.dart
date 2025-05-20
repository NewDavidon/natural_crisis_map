import 'package:flutter/material.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({Key? key}) : super(key: key);

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  String _selectedOption = 'opcion1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona una opción'),
        centerTitle: true,
      ),
      body: Center(
        child: DropdownButton<String>(
          value: _selectedOption,
          items: const [
            DropdownMenuItem(value: 'opcion1', child: Text('Opción 1')),
            DropdownMenuItem(value: 'opcion2', child: Text('Opción 2')),
            DropdownMenuItem(value: 'opcion3', child: Text('Opción 3')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedOption = value;
              });
            }
          },
        ),
      ),
    );
  }
}