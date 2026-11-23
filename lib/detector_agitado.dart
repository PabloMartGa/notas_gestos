import 'dart:math' as math;

/// Detecta sacudidas a partir de lecturas del acelerómetro.
///
/// Es Dart puro (no usa sensores ni Flutter) y recibe el instante como
/// parámetro, de modo que se puede probar sin esperar a que pase la pausa.
class DetectorAgitado {
  DetectorAgitado({
    this.umbral = 15,
    this.pausa = const Duration(seconds: 1),
  });

  /// Aceleración (m/s²) que hay que superar para contar una sacudida.
  final double umbral;

  /// Tiempo durante el que se ignoran las lecturas tras una sacudida.
  final Duration pausa;

  DateTime? _ultimaSacudida;

  /// Módulo de la aceleración: √(x² + y² + z²).
  static double modulo(double x, double y, double z) =>
      math.sqrt(x * x + y * y + z * z);

  /// Procesa una lectura y devuelve `true` si es una sacudida.
  ///
  /// Una lectura cuenta como sacudida si su módulo **supera** el umbral y no
  /// estamos dentro de la pausa que sigue a la sacudida anterior.
  bool procesar(double x, double y, double z, DateTime instante) {
    final ultima = _ultimaSacudida;
    if (ultima != null && instante.difference(ultima) < pausa) {
      return false;
    }
    if (modulo(x, y, z) > umbral) {
      _ultimaSacudida = instante;
      return true;
    }
    return false;
  }
}
