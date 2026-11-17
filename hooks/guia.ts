// NoNo - la lógica pura: textos, validación y traducción entre el mod y la ventana.
// Autoría intelectual: Felipe Restrepo Vélez; asistido por Claude.
//
// Aquí no toco nada de Claude Code (ni `$` ni JSX): solo funciones que reciben
// datos y devuelven datos. Así las puedo probar solas y el archivo que habla
// con el motor (register.tsx) queda corto.
import type { NonoAccion, NonoEstado, NonoGesto, NonoPaso } from '../types'

export const INICIAL: NonoEstado = {
  abierto: false,
  paso: null,
  demo: 0,
  gesto: 'neutral',
  globo: '',
  pensando: false,
  pendiente: false,
  espera: false,
  rev: 0,
  aviso: '',
}

/** Lo que Claude lee de la herramienta. Corto a propósito: viaja en cada pedido. */
export const DESCRIPCION =
  'NoNo, el acompañante en pantalla del usuario. Úsala cuando lo guíes paso a paso en algo que él ' +
  'hace en su pantalla: una llamada por paso, un paso a la vez, y cierra el turno con una línea. ' +
  'NoNo (mascota y puntero) vuela al punto y muestra qué hacer y por qué. x,y: píxeles físicos de pantalla del punto ' +
  'donde hacer clic o mirar (de una captura o de Windows-MCP Snapshot; omítelos si no los sabes y ' +
  'NoNo se queda posado en su globo). Los mensajes del usuario que empiezan por «[NoNo» vienen de ese globo: ' +
  'empieza tu respuesta con 1 o 2 frases que se entiendan solas (es lo que cabe en el globo) y, si ' +
  'toca, llama otra vez con el paso siguiente o corregido. No todo mensaje de NoNo pide respuesta: si ' +
  'solo te cuenta algo, contesta «Anotado.» y nada más. Con `accion` NoNo lo hace él mismo en x,y ' +
  '(clic; escribir `texto`; scroll `cantidad` muescas, positivo baja): solo si el usuario lo pide o hace ' +
  'falta. Nunca escribas contraseñas ni datos de pago, y antes de un clic irreversible (enviar, pagar, ' +
  'borrar) pide su sí. Después verifica con una captura. fin=true cierra la guía.'

export const ESQUEMA = {
  type: 'object',
  properties: {
    n: { type: 'integer', description: 'Número del paso (1..total).' },
    total: { type: 'integer', description: 'Cuántos pasos tiene la guía.' },
    que: { type: 'string', description: 'Qué hacer, en una frase corta e imperativa.' },
    porque: { type: 'string', description: 'Por qué, en una línea.' },
    x: { type: 'number', description: 'Píxel físico X del punto a señalar.' },
    y: { type: 'number', description: 'Píxel físico Y del punto a señalar.' },
    ancho: { type: 'number', description: 'Ancho del elemento señalado, si lo sabes.' },
    alto: { type: 'number', description: 'Alto del elemento señalado, si lo sabes.' },
    gesto: { type: 'string', enum: ['guino', 'ceja', 'feliz', 'no'], description: 'Cara de NoNo (opcional): guino = aquí es; ceja = duda; feliz = bien hecho; no = así no.' },
    accion: { type: 'string', enum: ['clic', 'escribir', 'scroll'], description: 'NoNo actúa en x,y en vez de solo señalar.' },
    texto: { type: 'string', description: 'Lo que NoNo escribe (accion=escribir).' },
    cantidad: { type: 'integer', description: 'Muescas de rueda (accion=scroll); positivo baja.' },
    fin: { type: 'boolean', description: 'true: la guía terminó; NoNo vuelve al modo libre.' },
  },
} as const

/** La guía de mentira que corre con /nono demo: no gasta tokens ni toca nada. */
export const DEMO: readonly NonoPaso[] = [
  { n: 1, total: 3, que: 'DEMO · Clic en «Agregar proyecto»', porque: 'Firebase guarda todo dentro de un proyecto.', x: 420, y: 300, ancho: 180, alto: 44 },
  { n: 2, total: 3, que: 'DEMO · Escribe el nombre y pulsa «Continuar»', porque: 'El nombre define la dirección web del sitio.', x: 760, y: 460, ancho: 120, alto: 40 },
  { n: 3, total: 3, que: 'DEMO · Abre «Hosting» en el menú', porque: 'Ahí se publica la página. (Las posiciones de la demo son inventadas.)' },
]

const numero = (v: unknown): number | undefined => (typeof v === 'number' && Number.isFinite(v) ? v : undefined)
const texto = (v: unknown, max: number): string => (typeof v === 'string' ? v.replace(/\s+/g, ' ').trim().slice(0, max) : '')

/** Valido lo que Claude manda a la herramienta. Devuelvo el paso, el fin, o el error en palabras. */
export function leerEntrada(e: Record<string, unknown>): { paso: NonoPaso; gesto: NonoGesto; accion: Omit<NonoAccion, 'id'> | null } | { fin: true } | { error: string } {
  if (e.fin === true) return { fin: true }
  const tipo = e.accion === 'clic' || e.accion === 'escribir' || e.accion === 'scroll' ? e.accion : null
  const escrito = typeof e.texto === 'string' ? e.texto.slice(0, 2000) : ''
  if (tipo && tipo !== 'escribir' && (numero(e.x) === undefined || numero(e.y) === undefined)) return { error: `Para «${tipo}» faltan x,y.` }
  if (tipo === 'escribir' && !escrito) return { error: 'Para «escribir» falta `texto`.' }
  const accion: Omit<NonoAccion, 'id'> | null = tipo ? { tipo, ...(tipo === 'escribir' ? { texto: escrito } : {}), ...(tipo === 'scroll' ? { cantidad: Math.round(numero(e.cantidad) ?? 3) } : {}) } : null
  const que = texto(e.que, 180) || (tipo === 'clic' ? 'Hago clic aquí por ti' : tipo === 'escribir' ? 'Escribo esto por ti' : tipo === 'scroll' ? 'Desplazo la página' : '')
  if (!que) return { error: 'Falta «que»: qué debe hacer el usuario en este paso.' }
  const n = Math.max(1, Math.round(numero(e.n) ?? 1))
  const total = Math.max(n, Math.round(numero(e.total) ?? n))
  const x = numero(e.x)
  const y = numero(e.y)
  const hayPunto = x !== undefined && y !== undefined
  const gesto: NonoGesto = e.gesto === 'ceja' || e.gesto === 'feliz' || e.gesto === 'no' ? e.gesto : 'guino'
  return {
    gesto,
    accion,
    paso: {
      n,
      total,
      que,
      porque: texto(e.porque, 220),
      ...(hayPunto ? { x, y } : {}),
      ...(hayPunto && numero(e.ancho) ? { ancho: numero(e.ancho) } : {}),
      ...(hayPunto && numero(e.alto) ? { alto: numero(e.alto) } : {}),
    },
  }
}

/** Lo que le devuelvo a Claude después de mostrar un paso. */
export function resultadoPaso(paso: NonoPaso, aviso: string, accion: string | null = null): string {
  if (accion && !aviso) return `NoNo va al punto y hace «${accion}» en un segundo. No esperes confirmación: verifica el resultado con una captura.`
  const donde = paso.x === undefined ? 'sin señalar (no diste x,y)' : `señalando (${paso.x}, ${paso.y})`
  const falla = aviso ? ` OJO: la ventana de NoNo no abrió (${aviso}); el paso quedó en el panel /nono panel.` : ''
  return `Paso ${paso.n}/${paso.total} en pantalla, ${donde}.${falla} Cierra el turno con una línea; el usuario contestará desde NoNo (LISTO, NO LO VEO o un mensaje).`
}

/** Un evento de la ventana: una línea JSON de su salida estándar. */
export type NonoEvento = { t: 'viva' | 'listo' | 'nolo' | 'cerrar' | 'hecho' } | { t: 'msg'; texto: string }

export function leerEvento(linea: string): NonoEvento | null {
  try {
    const o = JSON.parse(linea) as { t?: unknown; texto?: unknown }
    if (o.t === 'msg') return typeof o.texto === 'string' && o.texto.trim() ? { t: 'msg', texto: o.texto.trim() } : null
    if (o.t === 'viva' || o.t === 'listo' || o.t === 'nolo' || o.t === 'cerrar' || o.t === 'hecho') return { t: o.t }
  } catch {
    // Una línea que no es JSON (un aviso de PowerShell) no es un evento.
  }
  return null
}

/** El mensaje que entra a la sesión por un evento. El prefijo [NoNo le dice a Claude de dónde viene. */
export function mensajeDe(ev: NonoEvento, g: NonoEstado): string | null {
  const marca = g.paso ? `[NoNo · paso ${g.paso.n}/${g.paso.total}]` : '[NoNo]'
  if (ev.t === 'msg') return `${marca} ${ev.texto}`
  if (!g.paso) return null
  if (ev.t === 'listo') return `${marca} Listo, ya hice este paso.`
  if (ev.t === 'nolo') return `${marca} No encuentro lo que señalas. Mira mi pantalla y ubícame.`
  return null
}

/** Dejo una respuesta de Claude del tamaño de un globo: sin markdown y hasta ~max caracteres. */
export function recortar(respuesta: string, max = 280): string {
  const plano = respuesta
    .replace(/```[\s\S]*?```/g, ' (código en el chat) ')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/[*_`#>|]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
  if (!plano) return 'Hecho. Mira el chat.'
  if (plano.length <= max) return plano
  const corte = plano.slice(0, max)
  // Prefiero cortar al final de una frase; si no hay, en un espacio.
  const frase = Math.max(corte.lastIndexOf('. '), corte.lastIndexOf('? '), corte.lastIndexOf('! '))
  const hasta = frase > max * 0.4 ? frase + 1 : corte.lastIndexOf(' ')
  return `${corte.slice(0, hasta > 0 ? hasta : max).trim()} … (sigue en el chat)`
}

/** Lo que la ventana lee del archivo de estado. */
export function aPantalla(g: NonoEstado): Record<string, unknown> {
  const p = g.paso
  return {
    rev: g.rev,
    fin: !g.abierto,
    guia: p !== null,
    paso: p?.n ?? 0,
    total: p?.total ?? 0,
    que: p?.que ?? 'Dime.',
    porque: p ? p.porque : 'Lo que escribas le llega a Claude. Si solo es un aviso, no te contesto.',
    x: p?.x ?? null,
    y: p?.y ?? null,
    ancho: p?.ancho ?? 0,
    alto: p?.alto ?? 0,
    accion: g.accion ? { ...g.accion, x: p?.x ?? null, y: p?.y ?? null } : null,
    gesto: g.gesto,
    globo: g.globo,
    pensando: g.pensando,
  }
}
