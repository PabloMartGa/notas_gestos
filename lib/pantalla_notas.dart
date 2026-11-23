import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'detector_agitado.dart';
import 'detector_inclinacion.dart';
import 'nota.dart';

class PantallaNotas extends StatefulWidget {
  const PantallaNotas({super.key});

  @override
  State<PantallaNotas> createState() => _PantallaNotasState();
}

class _PantallaNotasState extends State<PantallaNotas> {
  final TextEditingController _controlador = TextEditingController();

  final List<Nota> _notas = [];

  /// Notas borradas, la última al final. Es la pestaña «Papelera» y de ella
  /// sale la nota que se recupera al agitar o al pulsar «Deshacer».
  final List<NotaBorrada> _papelera = [];
  int _siguienteId = 1;

  /// Pestaña actual: 0 = Notas, 1 = Papelera.
  int _pestana = 0;

  // Gestos.
  final DetectorAgitado _detectorAgitado = DetectorAgitado();
  final DetectorInclinacion _detectorInclinacion = DetectorInclinacion();
  StreamSubscription<UserAccelerometerEvent>? _subAgitado;
  StreamSubscription<AccelerometerEvent>? _subInclinacion;

  bool _agitarActivo = true;
  bool _inclinarActivo = false;
  bool _sensorDisponible = true;

  @override
  void initState() {
    super.initState();
    _activarAgitado();
  }

  @override
  void dispose() {
    // Paso 4: liberar recursos.
    _subAgitado?.cancel();
    _subInclinacion?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Sensores
  // ---------------------------------------------------------------------------

  /// Agitar: acelerómetro SIN gravedad (userAccelerometer), así en reposo
  /// el módulo es ≈ 0 y el umbral solo se supera con un movimiento real.
  void _activarAgitado() {
    _subAgitado?.cancel();
    try {
      _subAgitado = userAccelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (e) {
          if (_detectorAgitado.procesar(e.x, e.y, e.z, DateTime.now())) {
            _recuperarAgitando();
          }
        },
        onError: (Object _) => _sensorNoDisponible(),
        cancelOnError: true,
      );
    } catch (_) {
      _sensorNoDisponible();
    }
  }

  void _desactivarAgitado() {
    _subAgitado?.cancel();
    _subAgitado = null;
  }

  /// Inclinar (ampliación): acelerómetro CON gravedad, eje x.
  void _activarInclinacion() {
    _subInclinacion?.cancel();
    try {
      _subInclinacion = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (e) {
          switch (_detectorInclinacion.procesar(e.x, DateTime.now())) {
            case Inclinacion.izquierda:
              _irAPestana(0);
            case Inclinacion.derecha:
              _irAPestana(1);
            case Inclinacion.ninguna:
              break;
          }
        },
        onError: (Object _) => _sensorNoDisponible(),
        cancelOnError: true,
      );
    } catch (_) {
      _sensorNoDisponible();
    }
  }

  void _desactivarInclinacion() {
    _subInclinacion?.cancel();
    _subInclinacion = null;
  }

  /// Sin sensor (por ejemplo, en escritorio): se desactivan los interruptores.
  void _sensorNoDisponible() {
    _desactivarAgitado();
    _desactivarInclinacion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _agitarActivo = false;
        _inclinarActivo = false;
        _sensorDisponible = false;
      });
      _mostrar('Este dispositivo no tiene acelerómetro');
    });
  }

  void _cambiarAgitar(bool activo) {
    setState(() => _agitarActivo = activo);
    if (activo) {
      _activarAgitado();
    } else {
      _desactivarAgitado();
    }
  }

  void _cambiarInclinar(bool activo) {
    setState(() => _inclinarActivo = activo);
    if (activo) {
      _activarInclinacion();
    } else {
      _desactivarInclinacion();
    }
  }

  void _irAPestana(int indice) {
    if (!mounted || _pestana == indice) return;
    setState(() => _pestana = indice);
  }

  // ---------------------------------------------------------------------------
  // Notas
  // ---------------------------------------------------------------------------

  void _anadir() {
    final texto = _controlador.text.trim();
    if (texto.isEmpty) return;
    setState(() => _notas.add(Nota(id: _siguienteId++, texto: texto)));
    _controlador.clear();
  }

  /// Borra la nota guardándola, con su posición, para poder recuperarla.
  void _borrar(int indice) {
    if (indice < 0 || indice >= _notas.length) return;
    final borrada = NotaBorrada(_notas[indice], indice);
    setState(() {
      _notas.removeAt(indice);
      _papelera.add(borrada);
    });
    _mostrar(
      'Nota borrada',
      accion: SnackBarAction(
        label: 'Deshacer', // alternativa táctil al gesto
        onPressed: () {
          if (_papelera.contains(borrada)) _restaurar(borrada);
        },
      ),
    );
  }

  /// Devuelve la nota a su posición (o al final si la lista es ahora menor).
  void _restaurar(NotaBorrada borrada) {
    setState(() {
      _papelera.remove(borrada);
      final posicion = math.min(borrada.posicion, _notas.length);
      _notas.insert(posicion, borrada.nota);
    });
  }

  /// Si hay una nota que recuperar, la restaura; si no, no hace nada.
  void _recuperarAgitando() {
    if (_papelera.isEmpty) return;
    _restaurar(_papelera.last);
    _mostrar('Nota recuperada al agitar');
  }

  void _mostrar(String texto, {SnackBarAction? accion}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto), action: accion));
  }

  // ---------------------------------------------------------------------------
  // Interfaz
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas con gestos'),
        actions: [
          _IndicadorGesto(
            icono: Icons.vibration,
            activo: _agitarActivo,
            textoActivo: 'Agitar para deshacer: activado',
            textoInactivo: 'Agitar para deshacer: desactivado',
          ),
          _IndicadorGesto(
            icono: Icons.screen_rotation,
            activo: _inclinarActivo,
            textoActivo: 'Inclinar para cambiar de pestaña: activado',
            textoInactivo: 'Inclinar para cambiar de pestaña: desactivado',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            dense: true,
            secondary: const Icon(Icons.vibration),
            title: const Text('Agitar para deshacer'),
            subtitle: Text(_sensorDisponible
                ? 'Agita el móvil para recuperar la última nota borrada'
                : 'Este dispositivo no tiene acelerómetro'),
            value: _agitarActivo,
            onChanged: _sensorDisponible ? _cambiarAgitar : null,
          ),
          SwitchListTile(
            dense: true,
            secondary: const Icon(Icons.screen_rotation),
            title: const Text('Inclinar para cambiar de pestaña'),
            subtitle: const Text('Izquierda: Notas · Derecha: Papelera'),
            value: _inclinarActivo,
            onChanged: _sensorDisponible ? _cambiarInclinar : null,
          ),
          const Divider(height: 1),
          Expanded(child: _pestana == 0 ? _vistaNotas() : _vistaPapelera()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Notas',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _papelera.isNotEmpty,
              label: Text('${_papelera.length}'),
              child: const Icon(Icons.delete_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: _papelera.isNotEmpty,
              label: Text('${_papelera.length}'),
              child: const Icon(Icons.delete),
            ),
            label: 'Papelera',
          ),
        ],
      ),
    );
  }

  Widget _vistaNotas() {
    final tema = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controlador,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _anadir(),
                  decoration: const InputDecoration(
                    labelText: 'Nueva nota',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Añadir nota',
                icon: const Icon(Icons.add),
                onPressed: _anadir,
              ),
            ],
          ),
        ),
        Expanded(
          child: _notas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No hay notas.\nEscribe una y pulsa «Añadir nota».\n'
                      'Desliza una nota para borrarla.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _notas.length,
                  itemBuilder: (context, i) {
                    final nota = _notas[i];
                    return Dismissible(
                      key: ValueKey(nota.id),
                      background: _fondoBorrar(Alignment.centerLeft),
                      secondaryBackground: _fondoBorrar(Alignment.centerRight),
                      onDismissed: (_) =>
                          _borrar(_notas.indexWhere((n) => n.id == nota.id)),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(nota.texto),
                          trailing: IconButton(
                            tooltip: 'Borrar nota',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _borrar(i),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _fondoBorrar(Alignment alineacion) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alineacion,
      decoration: BoxDecoration(
        color: colores.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete, color: colores.onErrorContainer),
    );
  }

  Widget _vistaPapelera() {
    final tema = Theme.of(context);
    if (_papelera.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'La papelera está vacía.\nLas notas que borres aparecerán aquí.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyLarge,
          ),
        ),
      );
    }
    // La última borrada, la primera de la lista.
    final borradas = _papelera.reversed.toList();
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextButton.icon(
              onPressed: () => setState(_papelera.clear),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Vaciar papelera'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: borradas.length,
            itemBuilder: (context, i) {
              final borrada = borradas[i];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(borrada.nota.texto),
                  subtitle: Text(i == 0
                      ? 'Última borrada · se recupera al agitar'
                      : 'Posición original: ${borrada.posicion + 1}'),
                  trailing: IconButton(
                    tooltip: 'Restaurar nota',
                    icon: const Icon(Icons.restore),
                    onPressed: () => _restaurar(borrada),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Icono de la AppBar que indica si un gesto está activo.
class _IndicadorGesto extends StatelessWidget {
  const _IndicadorGesto({
    required this.icono,
    required this.activo,
    required this.textoActivo,
    required this.textoInactivo,
  });

  final IconData icono;
  final bool activo;
  final String textoActivo;
  final String textoInactivo;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Tooltip(
      message: activo ? textoActivo : textoInactivo,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icono,
          color: activo ? colores.primary : colores.onSurface.withAlpha(97),
        ),
      ),
    );
  }
}
