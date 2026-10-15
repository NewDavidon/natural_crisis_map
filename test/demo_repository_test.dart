import 'package:crisis_map_natural/models/donacion.dart';
import 'package:crisis_map_natural/services/demo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los streams se pueden escuchar varias veces y emiten el estado actual', () async {
    final repo = DemoRepository();
    final stream = repo.donaciones();

    final primera = await stream.first;
    final segunda = await stream.first; // antes: "Stream has already been listened to"
    expect(segunda.length, primera.length);
    expect(primera, isNotEmpty);
  });

  test('los cambios llegan a los oyentes y los nuevos ven el estado actualizado', () async {
    final repo = DemoRepository();
    final inicial = (await repo.donaciones().first).length;

    final cambios = <int>[];
    final sub = repo.donaciones().listen((l) => cambios.add(l.length));
    await Future<void>.delayed(Duration.zero);

    await repo.crearDonacion(Donacion(
      id: '',
      clase: ClaseDonacion.ofrezco,
      categoria: CategoriaDonacion.agua,
      descripcion: 'Garrafas de agua',
      fecha: DateTime(2026),
      userId: 'u',
    ));
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(cambios, [inicial, inicial + 1]);
    expect((await repo.donaciones().first).length, inicial + 1);
  });
}
