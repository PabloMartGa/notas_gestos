import 'package:flutter_test/flutter_test.dart';
import 'package:notas_gestos/detector_agitado.dart';

void main() {
  final inicio = DateTime(2026, 11, 19, 10);

  group('DetectorAgitado', () {
    test('en reposo no detecta sacudida', () {
      final detector = DetectorAgitado();
      expect(detector.procesar(0.1, -0.2, 0.1, inicio), isFalse);
      expect(
        detector.procesar(0.3, 0.1, -0.2, inicio.add(const Duration(milliseconds: 20))),
        isFalse,
      );
    });

    test('una sacudida fuerte se detecta', () {
      final detector = DetectorAgitado();
      expect(detector.procesar(20, 0, 0, inicio), isTrue);
    });

    test('usa el módulo de los tres ejes', () {
      final detector = DetectorAgitado();
      // √(10² + 10² + 10²) ≈ 17,3 > 15 aunque ningún eje llegue a 15.
      expect(detector.procesar(10, 10, 10, inicio), isTrue);
      // √(5² + 5² + 5²) ≈ 8,7 < 15.
      expect(
        DetectorAgitado().procesar(5, 5, 5, inicio),
        isFalse,
      );
    });

    test('un valor justo en el umbral no cuenta (hay que superarlo)', () {
      final detector = DetectorAgitado();
      expect(detector.procesar(15, 0, 0, inicio), isFalse);
    });

    test('una segunda sacudida dentro de la pausa se ignora', () {
      final detector = DetectorAgitado();
      expect(detector.procesar(20, 0, 0, inicio), isTrue);
      expect(
        detector.procesar(20, 0, 0, inicio.add(const Duration(milliseconds: 500))),
        isFalse,
      );
    });

    test('una sacudida pasada la pausa se detecta de nuevo', () {
      final detector = DetectorAgitado();
      expect(detector.procesar(20, 0, 0, inicio), isTrue);
      expect(
        detector.procesar(20, 0, 0, inicio.add(const Duration(milliseconds: 1100))),
        isTrue,
      );
    });

    test('la pausa se cuenta desde la sacudida, no desde las lecturas ignoradas',
        () {
      final detector = DetectorAgitado();
      expect(detector.procesar(20, 0, 0, inicio), isTrue);
      // Lecturas ignoradas dentro de la pausa: no la alargan.
      expect(
        detector.procesar(20, 0, 0, inicio.add(const Duration(milliseconds: 600))),
        isFalse,
      );
      expect(
        detector.procesar(20, 0, 0, inicio.add(const Duration(milliseconds: 900))),
        isFalse,
      );
      expect(
        detector.procesar(20, 0, 0, inicio.add(const Duration(milliseconds: 1000))),
        isTrue,
      );
    });

    test('admite umbral y pausa personalizados', () {
      final detector = DetectorAgitado(
        umbral: 25,
        pausa: const Duration(milliseconds: 200),
      );
      expect(detector.procesar(20, 0, 0, inicio), isFalse);
      expect(detector.procesar(30, 0, 0, inicio), isTrue);
      expect(
        detector.procesar(30, 0, 0, inicio.add(const Duration(milliseconds: 250))),
        isTrue,
      );
    });
  });
}
