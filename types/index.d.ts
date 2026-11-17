// NoNo - contrato de tipos del mod.
// Autoría intelectual: Felipe Restrepo Vélez; asistido por Claude.

/** Un paso de una guía: qué hago, por qué, y dónde lo señala NoNo en pantalla. */
export type NonoPaso = {
  n: number
  total: number
  que: string
  porque: string
  /** Punto en píxeles físicos de pantalla; sin él, NoNo muestra el globo sin señalador. */
  x?: number
  y?: number
  ancho?: number
  alto?: number
}

/** Algo que NoNo hace por mí en pantalla: un clic, escribir un texto o desplazar la página. */
export type NonoAccion = { id: string; tipo: 'clic' | 'escribir' | 'scroll'; texto?: string; cantidad?: number }

/** Las caras que el mod le puede pedir a NoNo. Escuchar, pensar y dormirse los decide él solo. */
export type NonoGesto = 'neutral' | 'hola' | 'guino' | 'ceja' | 'feliz' | 'si' | 'no'

/** Todo lo que NoNo recuerda de la sesión. Sobrevive a una recarga del mod. */
export type NonoEstado = {
  /** NoNo está en pantalla. */
  abierto: boolean
  /** El paso en curso; null cuando estoy en modo libre (solo pedirle cosas). */
  paso: NonoPaso | null
  /** 0 fuera de la demo; si no, el número del paso de la demo. */
  demo: number
  /** La acción en curso; null cuando no hay o cuando NoNo ya la hizo. */
  accion?: NonoAccion | null
  /** La expresión de NoNo. */
  gesto: NonoGesto
  /** Lo último que NoNo dice en su globo. */
  globo: string
  /** Mandé algo desde NoNo y Claude todavía no contesta. */
  pensando: boolean
  /** Mandé algo y su turno no ha empezado. */
  pendiente: boolean
  /** El turno que corre es el de un mensaje mío desde NoNo: su respuesta va al globo. */
  espera: boolean
  /** Sube con cada cambio; la ventana solo redibuja cuando cambia. */
  rev: number
  /** Por qué no pudo abrirse la ventana, si falló. */
  aviso: string
}

declare module 'claude-code' {
  interface PluginState {
    nono: { estado: NonoEstado }
  }
}
