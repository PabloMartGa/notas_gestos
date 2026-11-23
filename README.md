# Actividad 2 · Agitar para deshacer

**Módulo:** 0488 Desarrollo de interfaces · 2º DAM · **UT2** Generación de interfaces naturales
**Criterios:** RA2.b (interfaz natural) y RA2.d (detección del movimiento del cuerpo)

App de notas en la que agitar el móvil recupera la última nota borrada. El gesto es opcional y siempre tiene una alternativa táctil, como exige el criterio 2.5.4 (Activación mediante movimiento) de WCAG 2.2.

## Puesta en marcha

Este `.zip` contiene el código (`lib/`, `test/`) y el `pubspec.yaml`. Las carpetas de plataforma las genera Flutter:

```bash
cd notas_gestos
flutter create --project-name notas_gestos --platforms=android,ios .
rm -f test/widget_test.dart      # test de ejemplo del generador; no aplica a esta app
flutter pub get
flutter test                      # pruebas de los dos detectores
flutter run                       # con un móvil Android (o emulador con Virtual sensors)
```

> `flutter create .` no sobrescribe los archivos que ya existen. En Android no hace falta ningún permiso para el acelerómetro con la frecuencia de muestreo usada (`SensorInterval.gameInterval`).

Paquete usado: `sensors_plus`.

## Estructura

| Archivo | Contenido |
| --- | --- |
| `lib/detector_agitado.dart` | `DetectorAgitado` (Dart puro): umbral 15 m/s², pausa 1 s, `procesar(x, y, z, instante)`. |
| `lib/detector_inclinacion.dart` | Ampliación: `DetectorInclinacion` (Dart puro) con el eje x. |
| `lib/nota.dart` | `Nota` y `NotaBorrada` (nota + posición que ocupaba). |
| `lib/pantalla_notas.dart` | Pantalla: lista, `Dismissible`, `SnackBar` con «Deshacer», sensores, interruptores, `NavigationBar`. |
| `test/detector_agitado_test.dart` | 8 pruebas: reposo, sacudida, módulo de 3 ejes, umbral exacto, segunda sacudida dentro de la pausa, sacudida pasada la pausa, pausa desde la sacudida, parámetros propios. |
| `test/detector_inclinacion_test.dart` | 7 pruebas de la ampliación. |

## Qué cumple cada punto del enunciado

- **Detector** (paso 2): `procesar` calcula √(x²+y²+z²), devuelve `true` si **supera** el umbral y, tras detectar, ignora las lecturas durante la pausa. Recibe el instante como parámetro para probar la pausa sin esperar.
- **Interfaz** (paso 3): lista de notas con campo para añadir; cada nota se borra deslizándola (`Dismissible`) o con un `IconButton` con tooltip. Al borrar se guarda la nota **y su posición**, y sale un `SnackBar` «Nota borrada» con la acción «Deshacer». Al agitar, si hay algo que recuperar, se restaura en su posición y sale «Nota recuperada al agitar»; si no hay nada, no pasa nada.
- **Buenas prácticas** (paso 4):
  - *Se puede desactivar*: `SwitchListTile` «Agitar para deshacer» arriba del todo; desactivado, se cancela la suscripción y la app no escucha el sensor.
  - *Feedback visible*: icono en la `AppBar` (coloreado si está activo) con tooltip.
  - *Sin sensor*: si el flujo da error, se desactivan los interruptores y aparece «Este dispositivo no tiene acelerómetro».
  - *Liberar recursos*: la suscripción se cancela en `dispose()` y al desactivar el interruptor.
- **Ampliación**: `NavigationBar` con **Notas** y **Papelera** (la papelera es la lista de notas borradas, con botón «Restaurar» y «Vaciar papelera»). Con el interruptor «Inclinar para cambiar de pestaña» (desactivado por defecto), inclinar a la izquierda va a Notas y a la derecha a Papelera, con `accelerometerEventStream` y el eje x. La lógica está en `DetectorInclinacion`, con sus pruebas.
  - Si en tu móvil las direcciones salen invertidas, cambia los dos `case` de `_activarInclinacion` en `pantalla_notas.dart`.

La papelera guarda todas las notas borradas, no solo la última: cada sacudida recupera la más reciente, y el «Deshacer» del `SnackBar` recupera la nota concreta que acabas de borrar.

## Reflexión

### 1. Umbrales de 10, 15 y 25 m/s² caminando con el móvil en la mano

✍️ Rellena la tabla con tus pruebas (cambia `DetectorAgitado(umbral: …)` en `pantalla_notas.dart`):

| Umbral | Falsos positivos al caminar | ¿Se detecta una sacudida intencionada? |
| --- | --- | --- |
| 10 m/s² | ❌ | ❌ |
| 15 m/s² | ❌ | ❌ |
| 25 m/s² |❌ | ❌ |

Hipótesis para contrastar con tus resultados: con 10 m/s² es fácil que caminar o gesticular lo dispare (falsos positivos); con 25 m/s² hay que sacudir muy fuerte y fallará con gestos normales (falsos negativos); 15 m/s² suele ser un compromiso razonable. **Mi elección:** _(escribe cuál eliges y por qué, según lo que hayas medido)._

### 2. ¿Por qué `userAccelerometerEventStream` y no `accelerometerEventStream`?

`accelerometerEventStream` mide la aceleración **incluida la gravedad**, y `userAccelerometerEventStream` la mide **sin ella**, es decir, solo la causada por el movimiento del usuario.

Con el móvil en reposo, el acelerómetro con gravedad marca siempre un módulo de ≈ 9,8 m/s² (repartido entre los ejes según cómo esté inclinado). Eso tiene dos consecuencias:

- El detector parte de un valor base de 9,8 m/s² en lugar de 0. Cualquier pequeño movimiento ya queda muy cerca de un umbral de 10 m/s², con lo que el margen real para distinguir un gesto de un movimiento cualquiera es mínimo.
- Con un umbral por debajo de 9,8 m/s², el detector daría `true` continuamente con el móvil quieto sobre la mesa y la app restauraría notas sin parar (aunque la pausa de 1 s lo frenaría a una por segundo).

Con `userAccelerometer`, en reposo el módulo es ≈ 0 y el umbral solo se supera con un movimiento real, sin importar la orientación del móvil.

(Por el mismo motivo, la ampliación de inclinar sí usa `accelerometerEventStream`: ahí la gravedad es justo la señal que interesa, porque indica hacia dónde está inclinado el móvil.)

### 3. Las dos condiciones de WCAG 2.5.4 (Activación mediante movimiento)

El criterio exige que la funcionalidad que se activa con el movimiento del dispositivo:

1. **Se pueda hacer también con componentes de la interfaz**: recuperar una nota se puede hacer con la acción «Deshacer» del `SnackBar` y con el botón «Restaurar» de la Papelera, sin mover el móvil. Borrar también tiene alternativa al deslizamiento: el botón de borrar de cada nota.
2. **Se pueda desactivar la respuesta al movimiento** para evitar activaciones accidentales: los interruptores «Agitar para deshacer» e «Inclinar para cambiar de pestaña» desactivan el gesto (y dejan de escuchar el sensor), y los iconos de la `AppBar` muestran su estado.
