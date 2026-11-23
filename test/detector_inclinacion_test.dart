import 'package:flutter_test/flutter_test.dart';
import 'package:notas_gestos/detector_inclinacion.dart';

void main() {
  final inicio = DateTime(2026, 11, 19, 10);
  Duration ms(int n) => Duration(milliseconds: n);

  group('DetectorInclinacion', () {
    test('en posición neutra no detecta nada', () {
      final detector = DetectorInclinacion();
      expect(detector.procesar(0.2, inicio), Inclinacion.ninguna);
      expect(detector.procesar(-0.5, inicio.add(ms(50))), Inclinacion.ninguna);
    });

    test('una inclinación pequeña no cuenta', () {
      final detector = DetectorInclinacion();
      expect(detector.procesar(2.5, inicio), Inclinacion.ninguna);
    });

    test('x positivo es inclinación a la izquierda', () {
      final detector = DetectorInclinacion();
      expect(detector.procesar(6, inicio), Inclinacion.izquierda);
    });

    test('x negativo es inclinación a la derecha', () {
      final detector = DetectorInclinacion();
      expect(detector.procesar(-6, inicio), Inclinacion.derecha);
    });

    test('mantener la inclinación no repite el gesto', () {
      final detector = DetectorInclinacion();
      expect(detector.procesar(6, inicio), Inclinacion.izquierda);
      expect(detector.procesar(6, inicio.add(ms(1000))), Inclinacion.ninguna);
      expect(detector.procesar(6, inicio.add(ms(2000))), Inclinacion.ninguna);
    });

    test('hay que volver a la posición neutra para otro gesto', () {
      final detector = DetectorInclinacion();
      expect(detector.procesar(6, inicio), Inclinacion.izquierda);
      expect(detector.procesar(0, inicio.add(ms(1000))), Inclinacion.ninguna);
      expect(detector.procesar(-6, inicio.add(ms(1100))), Inclinacion.derecha);
    });

    test('dentro de la pausa se ignoran las lecturas', () {
      final detector = DetectorInclinacion();
      expect(detector.procesar(6, inicio), Inclinacion.izquierda);
      expect(detector.procesar(0, inicio.add(ms(100))), Inclinacion.ninguna);
      expect(detector.procesar(-6, inicio.add(ms(300))), Inclinacion.ninguna);
    });
  });
}
