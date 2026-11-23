/// Una nota de la lista.
class Nota {
  const Nota({required this.id, required this.texto});

  final int id;
  final String texto;
}

/// Una nota borrada junto con la posición que ocupaba, para poder
/// devolverla a su sitio.
class NotaBorrada {
  const NotaBorrada(this.nota, this.posicion);

  final Nota nota;
  final int posicion;
}
