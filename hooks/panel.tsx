// NoNo - el panel dentro de Claude (/nono panel).
// Autoría intelectual: Felipe Restrepo Vélez; asistido por Claude.
//
// Es el respaldo de la ventana: muestra el mismo paso, el porqué y lo último que
// dijo NoNo, por si la ventana no pudo abrirse (otra máquina, una sesión remota)
// o prefiero verlo al lado del chat. Solo lee el estado; no llama al modelo.
import { atom, read } from 'claude-code'
import type { On } from 'claude-code'

import { INICIAL } from './guia'
import { NONO_ASCII, nonoSvg } from './personaje'

// El mismo valor que usa register.tsx. Lo declaro también aquí porque el motor
// exige que quien lee un valor lo declare en su propio archivo.
const estado = atom({ plugin: 'nono', key: 'estado' } as const, INICIAL)

const TINTA = '#070A0E'
const CIAN = '#36E2C4'
const MAGENTA = '#FF4FB0'
const AMBAR = '#FFB23E'

export function registrarPanel(on: On): void {
  on('ui.render', { component: 'Pane', requestId: 'nono' }, async ($, e) => {
    const g = { ...INICIAL, ...(await read($, estado)) }
    const paso = g.paso
    const titulo = paso ? `PASO ${paso.n}/${paso.total}` : g.abierto ? 'MODO LIBRE' : 'DORMIDO'
    const que = paso ? paso.que : g.abierto ? 'Escríbeme en mi globo y se lo paso a Claude.' : 'Despiértame con /nono.'

    if (e.surface === 'terminal') {
      const { Box, Text } = $.ui.resolve(e)
      return (
        <Box flexDirection="column">
          {NONO_ASCII.map(linea => (
            <Text color={CIAN}>{linea}</Text>
          ))}
          <Text bold color={AMBAR}>
            NONO · {titulo}
          </Text>
          <Text bold>{que}</Text>
          {paso?.porque ? <Text dimColor>POR QUÉ: {paso.porque}</Text> : null}
          {g.pensando ? <Text color={AMBAR}>NoNo se lo pasa a Claude...</Text> : null}
          {g.globo ? <Text color={AMBAR}>&gt; {g.globo}</Text> : null}
          {g.aviso ? <Text color={MAGENTA}>La ventana no abrió: {g.aviso}</Text> : null}
        </Box>
      )
    }

    const { Box, Text } = $.ui.resolve(e)
    const dibujo = nonoSvg(g.gesto, g.pensando)
    // El Svg solo existe en la app de escritorio y en el editor; en el celular va sin dibujo.
    const cara =
      e.surface === 'desktop' || e.surface === 'vscode'
        ? (() => {
            const { Svg } = $.ui.resolve(e)
            return <Svg source={dibujo.source} alt="NoNo" width={dibujo.width} height={dibujo.height} isInteractive />
          })()
        : null
    return (
      <Box flexDirection="column" backgroundColor={TINTA} borderStyle="single" borderColor={CIAN} padding={1}>
        {cara}
        <Text bold color={AMBAR}>
          NONO · {titulo}
        </Text>
        <Text bold>{que}</Text>
        {paso?.porque ? (
          <Text>
            <Text bold color={MAGENTA}>
              POR QUÉ{' '}
            </Text>
            {paso.porque}
          </Text>
        ) : null}
        {g.pensando ? <Text color={AMBAR}>NoNo se lo pasa a Claude...</Text> : null}
        {g.globo ? <Text color={AMBAR}>&gt; {g.globo}</Text> : null}
        {g.aviso ? <Text color={MAGENTA}>La ventana no abrió: {g.aviso}</Text> : null}
        <Text dimColor>/nono abre a NoNo en pantalla · /nono demo · /nono fin</Text>
      </Box>
    )
  })
}
