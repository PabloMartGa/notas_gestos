/// Hacia dónde se ha inclinado el móvil.
enum Inclinacion { ninguna, izquierda, derecha }

/// Detecta inclinaciones laterales del móvil con el eje x del acelerómetro
/// (el que **incluye** la gravedad).
///
/// Con el móvil en vertical x ≈ 0. Al inclinarlo a la izquierda (borde
/// izquierdo hacia abajo) x se vuelve positivo, y al inclinarlo a la derecha,
/// negativo. Para que un solo gesto no cambie varias veces de pestaña:
///  * tras detectar una inclinación se ignoran las lecturas durante [pausa];
///  * hasta que el móvil no vuelve cerca de la posición neutra (|x| menor que
///    la mitad del [umbral]) no se acepta otra inclinación.
///
/// Es Dart puro y recibe el instante como parámetro, igual que
/// `DetectorAgitado`.
class DetectorInclinacion {
  DetectorInclinacion({
    this.umbral = 4,
    this.pausa = const Duration(milliseconds: 800),
  });

  /// Valor de x (m/s²) que hay que superar en valor absoluto. Con g ≈ 9,8 m/s²,
  /// 4 m/s² equivale a inclinar el móvil unos 24°.
  final double umbral;

  /// Tiempo durante el que se ignoran las lecturas tras una inclinación.
  final Duration pausa;

  DateTime? _ultima;
  bool _armado = true;

  Inclinacion procesar(double x, DateTime instante) {
    final ultima = _ultima;
    if (ultima != null && instante.difference(ultima) < pausa) {
      return Inclinacion.ninguna;
    }
    if (x.abs() < umbral / 2) {
      _armado = true; // de vuelta a la posición neutra
      return Inclinacion.ninguna;
    }
    if (!_armado) return Inclinacion.ninguna;

    Inclinacion resultado = Inclinacion.ninguna;
    if (x > umbral) {
      resultado = Inclinacion.izquierda;
    } else if (x < -umbral) {
      resultado = Inclinacion.derecha;
    }
    if (resultado != Inclinacion.ninguna) {
      _armado = false;
      _ultima = instante;
    }
    return resultado;
  }
}
