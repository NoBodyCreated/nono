// NoNo - el personaje como SVG, para el panel dentro de Claude.
// Autoría intelectual: Felipe Restrepo Vélez; asistido por Claude.
//
// NoNo es el isotipo de mi marca: el aro del centro (su ojo) y los cuatro arcos
// (los de arriba y abajo son sus pestañas). La geometría es la de
// sitio/marca/isotipo.svg, sin redibujar. La misma está en pantalla/dibujo.ps1
// (la ventana sobre otras apps); si cambio una, cambio la otra.
import type { NonoGesto } from '../types'

const CIAN = '#36E2C4'
const CENTRO = '198.61 199.66'
const ARCO_ARRIBA = 'M291.26,123.07c-11.78-12.68-26.19-23.3-42.91-30.95-16.72-7.65-34.18-11.62-51.47-12.25'
const ARCO_ABAJO = 'M105.29,276.93c11.78,12.68,26.19,23.3,42.91,30.95,16.72,7.65,34.18,11.62,51.47,12.25'
const ARCO_DERECHA = 'M275.21,292.99c12.68-11.78,23.3-26.19,30.95-42.91s11.62-34.18,12.25-51.47'
const ARCO_IZQUIERDA = 'M121.34,107.01c-12.68,11.78-23.3,26.19-30.95,42.91-7.65,16.72-11.62,34.18-12.25,51.47'

/** NoNo en texto, para la terminal, donde no hay SVG. */
export const NONO_ASCII = [' .-   ', "'  () .", "   -' "]

// Escalo una pieza desde el centro del logo: así una pestaña "sube" o "baja".
const escala = (k: number): string => `translate(198.61 199.66) scale(${k}) translate(-198.61 -199.66)`

/**
 * Dibujo a NoNo con una expresión. El panel no corre scripts, así que el
 * movimiento va con animaciones SMIL del propio SVG: parpadea solo cada 4 s y,
 * mientras Claude piensa, los arcos giran alrededor del ojo.
 */
export function nonoSvg(gesto: NonoGesto, pensando: boolean, lado = 72): { source: string; width: number; height: number } {
  // El panel es una foto de la cara, no la animación completa: la ventana en pantalla es la que actúa.
  const duda = gesto === 'ceja' || gesto === 'no'
  const alegre = gesto === 'feliz' || gesto === 'hola' || gesto === 'si'
  const arriba = duda ? escala(1.24) : alegre ? escala(1.14) : ''
  const abajo = duda ? escala(0.82) : alegre ? escala(1.14) : ''
  const ladeo = duda ? `rotate(-14 ${CENTRO})` : gesto === 'guino' ? `rotate(12 ${CENTRO})` : ''
  const giro = pensando
    ? `<animateTransform attributeName="transform" type="rotate" from="0 ${CENTRO}" to="360 ${CENTRO}" dur="2.6s" repeatCount="indefinite"/>`
    : ''
  // El guiño es un ojo que se queda medio cerrado; el parpadeo, uno que se cierra un instante.
  const ojo =
    gesto === 'guino'
      ? `<ellipse cx="198.61" cy="199.66" rx="43.08" ry="9"/>`
      : `<ellipse cx="198.61" cy="199.66" rx="43.08" ry="43.08"><animate attributeName="ry" values="43.08;43.08;4;43.08" keyTimes="0;0.94;0.97;1" dur="4s" repeatCount="indefinite"/></ellipse>`
  const source =
    `<svg xmlns="http://www.w3.org/2000/svg" width="${lado}" height="${lado}" viewBox="0 0 400 400" style="max-width:100%;height:auto">` +
    `<g fill="none" stroke="${CIAN}" stroke-width="31.18">` +
    `<g transform="${ladeo}">${giro}` +
    `<path transform="${arriba}" d="${ARCO_ARRIBA}"/><path transform="${abajo}" d="${ARCO_ABAJO}"/>` +
    `<path d="${ARCO_DERECHA}"/><path d="${ARCO_IZQUIERDA}"/></g>${ojo}</g></svg>`
  return { source, width: lado, height: lado }
}
