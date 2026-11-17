// NoNo - pruebas del recorrido completo contra el motor, sin ventana real.
// Autoría intelectual: Felipe Restrepo Vélez; asistido por Claude.
//
// Aquí los hooks de `on` hacen de motor: capturo lo que el mod escribe para la
// ventana y lo que mete a la sesión, y hago de ventana devolviendo eventos.
import { expect, test } from 'claude-code/testing'

import { leerEntrada, leerEvento, recortar } from '../hooks/guia'

type Pantalla = { rev: number; fin: boolean; guia: boolean; paso: number; total: number; que: string; x: number | null; globo: string; pensando: boolean; gesto: string }

test('la lógica pura: entrada, eventos y recorte', async () => {
  expect('error' in leerEntrada({})).toBe(true)
  const leido = leerEntrada({ n: 2, total: 3, que: ' Clic  aquí ', porque: 'porque sí', x: 10, y: 20 })
  expect('paso' in leido && leido.paso.que).toBe('Clic aquí')
  expect('paso' in leido && leido.paso.x).toBe(10)
  // Sin y no hay punto: NoNo no señala a medias.
  const sinPunto = leerEntrada({ que: 'Mira', x: 10 })
  expect('paso' in sinPunto && sinPunto.paso.x).toBe(undefined)
  expect(leerEvento('{"t":"msg","texto":"\\u00bfcuesta?"}')).toEqual({ t: 'msg', texto: '¿cuesta?' })
  expect(leerEvento('ruido de powershell')).toBe(null)
  expect(recortar('**Sí**, es `gratis`.')).toBe('Sí, es gratis.')
  expect(recortar('Una frase. '.repeat(60)).endsWith('(sigue en el chat)')).toBe(true)
})

test('un paso llega a la pantalla, mi mensaje entra a la sesión y la respuesta vuelve al globo', async ($, on) => {
  const pantallas: Pantalla[] = []
  const enviados: string[] = []
  on('tool.register', () => ({ value: { tool: 'mcp__nono__guia' } }))
  on('command.register', () => ({ value: { command: 'nono' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('env.get', (_, e) => ({ value: e.name === 'OS' ? 'Windows_NT' : 'C:\\Users\\prueba' }))
  on('fs.write', (_, e) => {
    pantallas.push(JSON.parse(e.text) as Pantalla)
    return { value: undefined }
  })
  // Hago de ventana: arranco, y "escribo" un mensaje en el globo.
  on('process.spawn', async function* () {
    yield { stream: 'stdout' as const, text: '{"t":"viva"}\n{"t":"msg","te' }
    yield { stream: 'stdout' as const, text: 'xto":"\\u00bfesto cuesta?"}\n' }
    return { value: { code: 0, signal: null } }
  })
  on('prompt.submit', (_, e) => {
    enviados.push(e.text)
    return { text: e.text }
  })
  on('session.id', () => ({ value: 'sesion-de-prueba' }))
  on('turn.start', (_, e) => ({ turnId: e.turnId }))
  on('turn.complete', (_, e) => ({ text: e.answer }))

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  const llamada = await $.tool.call({ tool: 'mcp__nono__guia', n: 1, total: 3, que: 'Clic en Agregar app', porque: 'Para registrar el sitio.', x: 468, y: -898 })
  expect(String(llamada.text ?? llamada.result)).toContain('Paso 1/3')

  // Dejo que el bucle de la ventana procese sus dos líneas.
  for (let i = 0; i < 2000 && enviados.length === 0; i++) await Promise.resolve()
  expect(enviados).toEqual(['[NoNo · paso 1/3] ¿esto cuesta?'])
  const trasMensaje = pantallas[pantallas.length - 1]
  expect(trasMensaje?.pensando).toBe(true)
  expect(trasMensaje?.x).toBe(468)

  // El turno de ese mensaje arranca y termina: la respuesta va al globo.
  await $.turn.start({ turnId: 't1', text: '[NoNo · paso 1/3] ¿esto cuesta?' } as never)
  await $.turn.complete({ turnId: 't1', answer: 'No, **es gratis** en el plan Spark.', durationMs: 1, isAborted: false, reason: 'answer' } as never)
  const final = pantallas[pantallas.length - 1]
  expect(final?.globo).toBe('No, es gratis en el plan Spark.')
  expect(final?.pensando).toBe(false)
  expect(final?.gesto).toBe('feliz')
  expect(final?.guia).toBe(true)
})
