// NoNo - el módulo de hooks: lo que conecta a NoNo con la sesión de Claude.
// Autoría intelectual: Felipe Restrepo Vélez; asistido por Claude.
//
// Qué hace este archivo:
//   1. Le da a Claude una herramienta (`guia`) para mostrar cada paso en pantalla.
//   2. Lanza la ventana de NoNo (pantalla/nono.ps1) y le pasa el estado por un archivo.
//   3. Lee lo que yo le escribo a NoNo y lo mete a la sesión como un mensaje mío.
//   4. Cuando Claude contesta ese mensaje, pone el comienzo de la respuesta en el globo.
// Dibujar a NoNo no llama al modelo: el mod no gasta tokens por sí mismo. Lo único
// que viaja en cada pedido es la descripción de la herramienta (unas 200 palabras).
import { atom, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { NonoEstado } from '../types'
import { DEMO, DESCRIPCION, ESQUEMA, INICIAL, aPantalla, leerEntrada, leerEvento, mensajeDe, recortar, resultadoPaso } from './guia'
import type { NonoEvento } from './guia'
import { registrarPanel } from './panel'

const estado = atom({ plugin: 'nono', key: 'estado' } as const, INICIAL)
const HERRAMIENTA = 'mcp__nono__guia'

// Si la ventana de NoNo está viva. Es una variable del módulo a propósito: una
// recarga del mod mata la ventana y también reinicia esta variable.
let pantallaViva = false

/** Cambio el estado y devuelvo el nuevo, con la revisión subida para que la ventana redibuje. */
async function cambiar($: EngineInterface, fn: (g: NonoEstado) => NonoEstado): Promise<NonoEstado> {
  let nuevo: NonoEstado = INICIAL
  await update($, estado, previo => {
    const g = { ...INICIAL, ...previo }
    nuevo = { ...fn(g), rev: g.rev + 1 }
    return nuevo
  })
  return nuevo
}

/** Un archivo de estado por sesión, para que dos sesiones no se pisen a NoNo. */
async function rutaEstado($: EngineInterface): Promise<string> {
  const casa = (await $.env.get('USERPROFILE')) ?? '.'
  return `${casa}\\.claude\\nono\\estado-${await $.session.id()}.json`
}

/** Escribo el estado para la ventana y me aseguro de que esté abierta. */
async function mostrar($: EngineInterface, g: NonoEstado): Promise<void> {
  const ruta = await rutaEstado($)
  await $.fs.write(ruta, JSON.stringify(aPantalla(g)))
  if (g.abierto) abrirPantalla($, ruta)
}

/**
 * Lanzo la ventana y me quedo leyendo su salida: cada línea es algo que hice en
 * el globo. El bucle vive lo que viva la ventana; si no arranca, lo anoto en
 * `aviso` para decírselo a Claude y que el paso quede al menos en el panel.
 */
function abrirPantalla($: EngineInterface, ruta: string): void {
  if (pantallaViva) return
  pantallaViva = true
  void (async () => {
    let resto = ''
    try {
      if ((await $.env.get('OS')) !== 'Windows_NT') throw new Error('la ventana de NoNo solo existe en Windows')
      const guion = `${$.plugin.root}/pantalla/nono.ps1`
      const hijo = $.process.spawn({
        argv: ['powershell.exe', '-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', guion, '-Estado', ruta],
      })
      for await (const trozo of hijo) {
        if (trozo.stream !== 'stdout') continue
        // La salida llega en trozos, no en líneas: junto y corto por salto de línea.
        resto += trozo.text
        const lineas = resto.split('\n')
        resto = lineas.pop() ?? ''
        for (const linea of lineas) await recibir($, leerEvento(linea))
      }
    } catch (error) {
      const aviso = error instanceof Error ? error.message : String(error)
      // Si el mod se está descargando, el motor ya no acepta escrituras: no pasa nada.
      await cambiar($, g => ({ ...g, aviso: aviso.slice(0, 200) })).catch(() => undefined)
    } finally {
      pantallaViva = false
    }
  })()
}

/** Atiendo un evento de la ventana (o del panel): cerrar, avanzar la demo, o hablarle a Claude. */
async function recibir($: EngineInterface, ev: NonoEvento | null): Promise<void> {
  if (!ev) return
  if (ev.t === 'hecho') {
    // NoNo ya actuó: borro la acción para que no se repita si la ventana se reabre.
    await mostrar($, await cambiar($, g => ({ ...g, accion: null })))
    return
  }
  if (ev.t === 'viva') {
    await cambiar($, g => ({ ...g, aviso: '' }))
    return
  }
  const { value } = await $.state.get({ plugin: 'nono', key: 'estado' } as const)
  const g = { ...INICIAL, ...value }
  if (ev.t === 'cerrar') {
    // La ventana ya se cerró sola; dejo todo en cero sin avisarle a Claude.
    await cambiar($, () => ({ ...INICIAL }))
    return
  }
  if (g.demo > 0) {
    // La demo no sale de mi PC: LISTO avanza, y un mensaje recibe una respuesta fija.
    const sigue = ev.t === 'listo' ? DEMO[g.demo] : DEMO[g.demo - 1]
    const globo = ev.t === 'msg' ? 'Esto es la demo: en una guía real, tu mensaje le llega a Claude.' : ''
    const fin = ev.t === 'listo' && !sigue
    const n = await cambiar($, x =>
      fin
        ? { ...x, demo: 0, paso: null, gesto: 'feliz', globo: 'Fin de la demo. Así se ve una guía conmigo.' }
        : { ...x, demo: ev.t === 'listo' ? x.demo + 1 : x.demo, paso: sigue ?? x.paso, gesto: ev.t === 'nolo' ? 'ceja' : 'guino', globo },
    )
    await mostrar($, n)
    return
  }
  const texto = mensajeDe(ev, g)
  if (!texto) return
  const n = await cambiar($, x => ({ ...x, pensando: true, pendiente: true, globo: '', gesto: ev.t === 'nolo' ? 'ceja' : 'neutral' }))
  await mostrar($, n)
  // `asUser`: son mis palabras, no las del mod. Si Claude está ocupado, queda en cola.
  await $.prompt.submit({ text: texto, asUser: true })
}

/** /nono, /nono demo, /nono fin, /nono panel. */
async function comando($: EngineInterface, args: string): Promise<string> {
  const orden = args.trim().toLowerCase()
  if (orden === 'panel') {
    await $.ui.open({ id: 'nono', title: 'NoNo' })
    return 'Panel de NoNo abierto.'
  }
  if (orden === 'fin' || orden === 'off' || orden === 'cerrar') {
    await mostrar($, await cambiar($, () => ({ ...INICIAL })))
    return 'NoNo se fue. Vuelve con /nono.'
  }
  if (orden === 'demo') {
    await mostrar($, await cambiar($, () => ({ ...INICIAL, abierto: true, demo: 1, paso: DEMO[0] ?? null, gesto: 'hola' })))
    return 'Demo de NoNo en pantalla: tres pasos de mentira, sin gastar tokens. Pulsa LISTO para avanzar.'
  }
  await mostrar($, await cambiar($, g => ({ ...g, abierto: true, demo: 0, gesto: 'hola' })))
  return 'NoNo está en pantalla. Escríbele ahí y le llega a esta sesión. /nono fin lo cierra; /nono demo muestra una guía de prueba.'
}

export const register: Register = on => {
  registrarPanel(on)

  on('session.start', async ($, e, next) => {
    await $.tool.register({ name: 'guia', description: DESCRIPCION, inputSchema: ESQUEMA })
    await $.command.register({ name: 'nono', description: 'NoNo, mi acompañante en pantalla', argumentHint: '[demo | fin | panel]' })
    // Tras una recarga del mod la ventana murió: si NoNo estaba abierto, lo vuelvo a sacar.
    const { value } = await $.state.get({ plugin: 'nono', key: 'estado' } as const)
    if (value?.abierto) await mostrar($, await cambiar($, g => ({ ...g, pensando: false, accion: null })))
    return next(e)
  })

  on('command.run', { command: 'nono' }, async ($, e) => ({ text: await comando($, e.args) }))

  // Claude muestra un paso (o cierra la guía).
  on('tool.call', { tool: HERRAMIENTA }, async ($, e) => {
    const leido = leerEntrada(e as unknown as Record<string, unknown>)
    if ('error' in leido) return { result: leido.error, isError: true }
    if ('fin' in leido) {
      await mostrar($, await cambiar($, g => ({ ...g, paso: null, demo: 0, gesto: 'feliz' })))
      return { result: 'Guía cerrada. NoNo sigue en pantalla en modo libre (el usuario lo cierra con la X o /nono fin).' }
    }
    const accion = leido.accion ? { ...leido.accion, id: String(Date.now()) } : null
    const g = await cambiar($, x => ({ ...x, abierto: true, demo: 0, paso: leido.paso, accion, gesto: leido.gesto, globo: x.espera ? x.globo : '' }))
    await mostrar($, g)
    return { result: resultadoPaso(leido.paso, g.aviso, leido.accion?.tipo ?? null) }
  })

  // Un mensaje mío desde NoNo queda `pendiente`; cuando arranca su turno pasa a `espera`.
  // Así no confundo su respuesta con la de un turno que ya venía corriendo.
  on('turn.start', async ($, e, next) => {
    if (e.agentId === undefined) {
      const { value } = await $.state.get({ plugin: 'nono', key: 'estado' } as const)
      if (value?.pendiente) await cambiar($, g => ({ ...g, pendiente: false, espera: true }))
    }
    return next(e)
  })

  // Claude terminó de contestar lo que mandé desde NoNo: el comienzo va al globo.
  on('turn.complete', async ($, e, next) => {
    const fin = await next(e)
    if (e.agentId !== undefined) return fin
    const { value } = await $.state.get({ plugin: 'nono', key: 'estado' } as const)
    if (value?.espera && value.abierto) {
      // Si el turno murió por un error (sin conexión, sesión vencida) no digo «hecho»: digo que falló.
      const fallo = e.reason === 'error' || e.reason === 'refusal'
      const globo = e.isAborted ? 'Se interrumpió. Mira el chat.' : fallo ? 'Claude no pudo contestar. Mira el chat.' : recortar(e.answer)
      // No todo mensaje pide respuesta: si Claude solo acusa recibo («Anotado.»), NoNo asiente y no abre globo.
      const acuse = !fallo && !e.isAborted && globo.length <= 24
      const g = await cambiar($, x => ({ ...x, espera: false, pensando: x.pendiente, globo: acuse ? '' : globo, gesto: fallo ? 'no' : acuse ? 'si' : 'feliz' }))
      await mostrar($, g)
    }
    return fin
  })

  // Al cerrar la sesión, NoNo se va con ella.
  on('session.end', async ($, e, next) => {
    const { value } = await $.state.get({ plugin: 'nono', key: 'estado' } as const)
    if (value?.abierto) await $.fs.write(await rutaEstado($), JSON.stringify({ rev: value.rev + 1, fin: true }))
    return next(e)
  })
}
