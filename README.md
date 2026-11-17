# NoNo

Mi acompañante en pantalla para Claude Code (Windows 11). NoNo es el isotipo de mi marca, no.body.lab: mascota y puntero a la vez.

Autoría intelectual: Felipe Restrepo Vélez; asistido por Claude.

## Qué hace

- **Me guía paso a paso.** Cuando Claude me guía en algo que yo hago en pantalla, NoNo vuela al punto exacto (sobre cualquier aplicación) y su globo dice qué hacer y por qué.
- **Le escribo con un clic.** NoNo descansa solo, sin cuadro. Un clic sobre él (o sobre su carita en el globo, cuando está señalando) despliega el cuadro de texto; `Enter` envía, `Esc` o otro clic lo pliega. Lo que escribo entra a la sesión de Claude como un mensaje mío. `Win+H` me deja dictarlo.
- **Actúa por mí.** Si se lo pido o hace falta, NoNo hace clic, escribe o desplaza la página él mismo: vuela al punto, hace su gesto (*clic*, *escribo*, *desplazo*) y solo entonces mueve el mouse o el teclado. No escribe contraseñas ni datos de pago, y antes de un clic irreversible Claude me pide el sí.
- **No todo pide respuesta.** Si solo le cuento algo, Claude contesta «Anotado.», NoNo asiente y no abre globo.
- **Me contesta en el globo.** El comienzo de la respuesta de Claude aparece ahí; si es larga, dice «sigue en el chat».
- **Modo libre.** Con `/nono` lo saco cuando quiera para pedirle cosas: explicaciones, tareas, favores.
- **Se expresa, y siempre se entiende por qué.** Cada cara nace de algo que pasa y lleva una palabra junto a su nombre: saluda al aparecer (*¡hola!*), guiña al mostrar un paso (*aquí*), se inclina mientras escribo (*te escucho*), asiente cuando pulso LISTO (*entendido*), gira sus arcos mientras Claude trabaja (*pensando…*), salta cuando llega la respuesta (*¡listo!*), alza una pestaña buscando (*¿dónde?*), niega si algo falla (*algo falló*) y se adormece si lo dejo solo (*zzz*). Mientras espera, de vez en cuando sigue mi mouse con la mirada. Como puntero se ajusta al tamaño de lo que señala, para no taparlo.

## Instalar

Requisitos: Windows 11 y Claude Code (la terminal o la app de escritorio). La ventana de NoNo usa PowerShell 5.1 y WPF, que vienen con Windows: no hay nada más que instalar. En Windows 10 debería funcionar igual, pero no lo he probado.

En la terminal de Claude Code:

```
/plugin install nono --marketplace NoBodyCreated/nono
```

Responde `y` para agregar el marketplace y elige el alcance (usuario o proyecto).

Desde una consola:

```
claude plugin install nono --marketplace NoBodyCreated/nono
```

En la app de escritorio, donde `/plugin` no corre: el **+** junto al cuadro de texto, luego **Plugins**, **Add marketplace** con `NoBodyCreated/nono`, y **Add plugin**.

Después abre una sesión nueva (o `/reload-plugins`).

## Cómo se usa

| Quiero | Hago |
|---|---|
| Sacar a NoNo | `/nono` |
| Ver una guía de mentira (sin gastar tokens) | `/nono demo` |
| Cerrarlo | la `X` del globo, o `/nono fin` |
| Verlo en un panel al lado del chat | `/nono panel` |
| Que Claude me guíe con él | pedirle «guíame paso a paso con NoNo» |
| Mover el globo | arrastrarlo por la cabecera (se queda donde lo deje) |

Botones del globo en una guía: **LISTO >** (ya hice el paso) y **NO LO VEO** (Claude mira la pantalla y me reubica).

## Estado

- **0.3.2 (esta):** guía paso a paso, globo, mensajes a la sesión, gestos, mirada y acciones con el mouse real.
- **0.4.0 (en prueba, sin publicar):** manos que actúan sin quitar el mouse ni el foco (mensajes de Windows y accesibilidad) y clones de colores, uno por cada agente que trabaja a la vez. Sale cuando pase su revisión.

## Cómo está hecho

| Archivo | Qué es |
|---|---|
| `hooks/register.tsx` | Conecta a NoNo con la sesión: herramienta `guia`, comando `/nono`, mensajes y respuestas. |
| `hooks/guia.ts` | Lógica pura: textos, validación, recorte de respuestas. |
| `hooks/panel.tsx`, `hooks/personaje.ts` | El panel dentro de Claude y NoNo como SVG. |
| `pantalla/nono.ps1` | La ventana transparente sobre otras apps (PowerShell + WPF). |
| `pantalla/dibujo.ps1`, `gestos.ps1`, `vuelo.ps1`, `win32.ps1` | El isotipo y el globo, las expresiones, el vuelo entre mascota y puntero, y el puente con Windows. |
| `pantalla/manos.ps1` | Las acciones: clic, escribir y rueda. |
| `pantalla/clones.ps1` | Borrador de los clones de la 0.4.0; en esta versión no se carga. |
| `pantalla/autoprueba.ps1` | NoNo pulsa sus propios botones si existe la variable `NONO_PRUEBA` (para probar sin tocar el mouse). |
| `tests/guia.test.ts` | Pruebas del recorrido contra el motor. |

El mod y la ventana se hablan por dos canales simples: el mod escribe `~/.claude/nono/estado-<sesión>.json` y la ventana le devuelve una línea JSON por cada cosa que hago en el globo.

## Límites (lo que NO hace)

- **Un mod no puede dibujar fuera de Claude.** Por eso NoNo en pantalla es un proceso aparte de Windows que el mod lanza. Solo Windows.
- **NoNo no ve la pantalla.** Señala donde Claude le diga. Claude saca las coordenadas de una captura; si no las tiene, NoNo muestra el paso posado en su globo, sin señalar.
- **No sigue el scroll.** Si muevo la página, el punto queda donde estaba hasta el siguiente paso. `NO LO VEO` lo corrige.
- **El globo es corto.** Muestra unos 280 caracteres de la respuesta; el resto está en el chat.
- **Costo.** Dibujar y animar a NoNo no gasta tokens. Lo que sí viaja en cada pedido es la descripción de la herramienta (unas 200 palabras) y, claro, cada mensaje que le mando a Claude es un turno normal.
- **Voz.** No tiene micrófono propio: el dictado es el de Windows (`Win+H`) sobre su cuadro de texto.
- **En una sesión remota** la ventana no existe; queda el panel.
- **Cada sesión saca su propio NoNo.** Si dos sesiones lo usan a la vez, se ven dos.

## Licencia

- **Código:** PolyForm Strict 1.0.0 con permisos adicionales (`LICENSE`). Puedes verlo, instalarlo y usarlo sin fines comerciales, tomar fragmentos pequeños con crédito y proponer mejoras; no puedes redistribuirlo, publicar versiones modificadas ni venderlo. Para trabajo pagado, licencia comercial: no.body.created.v0@gmail.com.
- **Documentos:** CC BY-NC-SA 4.0 (`LICENSE-docs.md`).
- **Marca:** NoNo, no.body.lab, by.no.one y el isotipo de no.body.lab no se licencian: todos los derechos reservados.

a tool created by no.body.lab · © 2026 Felipe Restrepo Vélez
