# NoNo - el acompanante en pantalla (ventanas WPF sobre cualquier app).
# Autoria intelectual: Felipe Restrepo Velez; asistido por Claude.
#
# Este proceso lo lanza mi mod de Claude Code. No sabe nada de Claude: solo
#   1. lee un archivo de estado (JSON) que el mod reescribe en cada cambio, y
#   2. escribe por la salida estandar, una linea JSON por evento, lo que yo
#      hago en el globo (un mensaje, LISTO, NO LO VEO, cerrar).
# Asi el mod y la ventana quedan desacoplados y puedo probar esta parte sola:
#   powershell -STA -ExecutionPolicy Bypass -File nono.ps1 -Estado <ruta.json>
#
# ASCII puro a proposito (ver nota en dibujo.ps1).
param([Parameter(Mandatory = $true)][string]$Estado)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'win32.ps1')
$modoEscala = [NoNo.Win]::Escala()   # antes de cargar WPF, o ya no se puede cambiar
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
. (Join-Path $PSScriptRoot 'dibujo.ps1')
. (Join-Path $PSScriptRoot 'gestos.ps1')

# Un solo NoNo por archivo de estado: si quedo uno viejo mio, lo cierro.
# Compruebo la linea de comandos para no matar un PowerShell ajeno.
$pidArchivo = "$Estado.pid"
if (Test-Path $pidArchivo) {
    $viejo = 0
    [void][int]::TryParse(([IO.File]::ReadAllText($pidArchivo)).Trim(), [ref]$viejo)
    if ($viejo -gt 0 -and $viejo -ne $PID) {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$viejo" -ErrorAction SilentlyContinue
        if ($proc -and $proc.CommandLine -like '*nono.ps1*') {
            Stop-Process -Id $viejo -Force -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}
[IO.File]::WriteAllText($pidArchivo, "$PID")

# Escribo un evento para el mod. Escapo lo que no sea ASCII a \uXXXX para que
# la codificacion de la tuberia nunca me dane una tilde.
function Send-Evento($objeto) {
    $json = $objeto | ConvertTo-Json -Compress
    $json = [regex]::Replace($json, '[^\x20-\x7E]', { param($m) '\u{0:x4}' -f [int][char]$m.Value })
    [Console]::Out.WriteLine($json)
    [Console]::Out.Flush()
}

function Read-Estado {
    try {
        if (-not (Test-Path $Estado)) { return $null }
        return ([IO.File]::ReadAllText($Estado, [Text.Encoding]::UTF8) | ConvertFrom-Json)
    } catch { return $null }  # El mod puede estar a medio escribir: reintento en el proximo tic.
}

# --- Ventanas -----------------------------------------------------------------
$globo = [Windows.Markup.XamlReader]::Parse($script:XAML_GLOBO)
$puntero = [Windows.Markup.XamlReader]::Parse($script:XAML_PUNTERO)
$ui = @{}
foreach ($n in 'Cabeza', 'Cerrar', 'Paso', 'Mini', 'Que', 'PorqueBloque', 'Porque', 'GloboCaja', 'Globo', 'Entrada', 'Listo', 'NoVeo', 'Botones', 'PorqueRotulo', 'Animo', 'Escribir') {
    $ui[$n] = $globo.FindName($n)
}
# Dos NoNo: el grande, que es mascota y puntero, y el chico de la cabecera del
# globo. Hacen los mismos gestos a la vez.
$grande = New-NoNo
$chico = New-NoNo
$puntero.FindName('Cuerpo').Child = $grande.Dibujo
$ui.Mini.Child = $chico.Dibujo
$nonos = @($grande, $chico)
. (Join-Path $PSScriptRoot 'vuelo.ps1')

$script:gesto = ''
$script:rev = -1
$script:fijo = $false        # true cuando arrastre el globo: ya no lo muevo yo
$script:faltas = 0

function Set-Pensando {
    $ui.Globo.Text = 'NoNo se lo pasa a Claude...'
    $ui.GloboCaja.Visibility = 'Visible'
}

# Pongo una cara y su palabra. Los gestos pasajeros devuelven la cara neutra solos.
function Set-Cara([string]$g) {
    $script:gesto = $g
    Set-Gesto $nonos $g
    $ui.Animo.Text = [string]$script:ANIMO[$g]
    $vuelve.Stop()
    if ($script:PASAJEROS -contains $g) { $vuelve.Start() }
}
function New-Reloj([int]$ms, [scriptblock]$alSonar) {
    $r = New-Object Windows.Threading.DispatcherTimer
    $r.Interval = [TimeSpan]::FromMilliseconds($ms)
    $r.Add_Tick($alSonar)
    return $r
}
$vuelve = New-Reloj 2600 { $vuelve.Stop(); $script:gesto = 'neutral'; $ui.Animo.Text = '' }
# Deje de escribir hace un momento: NoNo deja de "escuchar".
$callado = New-Reloj 1500 { $callado.Stop(); if ($script:gesto -eq 'escucha') { Set-Cara 'neutral' } }
# Minuto y medio sin que pase nada mientras descansa en su globo: se adormece.
$sueno = New-Reloj 90000 { $sueno.Stop(); if ($script:modo -eq 'mascota' -and $script:gesto -eq 'neutral') { Set-Cara 'dormido' } }

# El globo solo esta a la vista cuando tiene algo que decir o cuando le abri el
# cuadro de texto. En modo libre, sin nada pendiente, NoNo descansa solo.
function Sync-Globo {
    $e = $script:ultimo
    $hace = ($ui.Escribir.Visibility -eq 'Visible') -or ($e -and ($e.guia -or $e.pensando -or [string]$e.globo))
    if ($hace -and -not $globo.IsVisible) { $globo.Show() }
    if (-not $hace -and $globo.IsVisible) { $globo.Hide() }
}
# Un clic sobre NoNo despliega el cuadro para escribirle; otro clic lo pliega.
function Switch-Escribir {
    if ($ui.Escribir.Visibility -eq 'Visible') { $ui.Escribir.Visibility = 'Collapsed' }
    else { $ui.Escribir.Visibility = 'Visible' }
    Sync-Globo
    if ($ui.Escribir.Visibility -eq 'Visible') { [void]$globo.Activate(); [void]$ui.Entrada.Focus(); Set-Cara 'escucha'; $callado.Stop(); $callado.Start() }
    $globo.UpdateLayout()
    $reubica.Stop(); $reubica.Start()
}

function Update-Vista($e) {
    if ($e.fin) { $app.Shutdown(); return }
    $ui.Paso.Text = if ($e.guia -and $e.total -gt 0) { "PASO $($e.paso)/$($e.total)" } else { '' }
    $ui.Que.Text = [string]$e.que
    $ui.Porque.Text = [string]$e.porque
    $ui.PorqueRotulo.Text = if ($e.guia) { "POR QU$([char]0xC9)  " } else { '' }
    $ui.PorqueBloque.Visibility = if ([string]$e.porque) { 'Visible' } else { 'Collapsed' }
    # Fuera de una guia soy solo el cuadro para pedirle cosas a Claude: sin LISTO ni NO LO VEO.
    $ui.Botones.Visibility = if ($e.guia) { 'Visible' } else { 'Collapsed' }
    if ($e.pensando) { Set-Pensando }
    elseif ([string]$e.globo) { $ui.Globo.Text = [string]$e.globo; $ui.GloboCaja.Visibility = 'Visible' }
    else { $ui.GloboCaja.Visibility = 'Collapsed' }
    # La cara la decide lo que esta pasando: si Claude trabaja, piensa; si no, la que pida el mod.
    $pedido = if ($e.pensando -and [string]$e.gesto -ne 'ceja') { 'pensando' } else { [string]$e.gesto }
    if (-not $pedido) { $pedido = 'neutral' }
    if ($pedido -ne $script:gesto -or $script:PASAJEROS -contains $pedido) { Set-Cara $pedido }
    $sueno.Stop(); $sueno.Start()
    $globo.UpdateLayout()

    $hayPunto = ($null -ne $e.x) -and ($null -ne $e.y)
    if (-not $script:fijo) { Set-Globo $e $hayPunto }
    $script:ultimo = $e
    Sync-Globo
    $reubica.Stop(); $reubica.Start()
    if ($hayPunto) {
        Set-Modo 'puntero'
        Move-Puntero ([double]$e.x) ([double]$e.y)
        # Si se el tamano de lo que senalo, me ajusto a el: mido 72 unidades a talla 1.
        $k = 0.78
        if ($e.ancho -and $e.alto) {
            $menor = [Math]::Min([double]$e.ancho, [double]$e.alto) / (Get-Factor $puntero)
            $k = [Math]::Max(0.42, [Math]::Min(0.9, $menor * 1.5 / 72))
        }
        Set-Talla $k
        Start-Accion $e.accion
    } else {
        Set-Modo 'mascota'
        $percha = Get-Percha
        Move-Puntero $percha[0] $percha[1]
        Start-Accion $e.accion
    }
}

. (Join-Path $PSScriptRoot 'manos.ps1')

# --- Lo que yo hago en el globo -------------------------------------------------
$ui.Cabeza.Add_MouseLeftButtonDown({ $script:fijo = $true; $globo.DragMove() })
$globo.Add_LocationChanged({
        if ($script:fijo -and $script:modo -eq 'mascota' -and $null -ne $script:punta) {
            $percha = Get-Percha
            $script:meta = $percha
            Set-Punta $percha[0] $percha[1]
        }
    })
$puntero.Add_MouseLeftButtonDown({ Switch-Escribir })
$ui.Mini.Add_MouseLeftButtonDown({ param($origen, $clic) $clic.Handled = $true; Switch-Escribir })
$ui.Cerrar.Add_Click({ Send-Evento @{ t = 'cerrar' }; $app.Shutdown() })
$ui.Listo.Add_Click({ Send-Evento @{ t = 'listo' }; Set-Pensando; Set-Cara 'si' })
$ui.NoVeo.Add_Click({ Send-Evento @{ t = 'nolo' }; Set-Pensando; Set-Cara 'ceja' })
$ui.Entrada.Add_KeyDown({
        param($origen, $tecla)
        if ($tecla.Key -eq 'Escape') { Switch-Escribir; return }
        if ($tecla.Key -ne 'Return') { return }
        $texto = $ui.Entrada.Text.Trim()
        if ($texto) { Send-Evento @{ t = 'msg'; texto = $texto }; $ui.Entrada.Text = ''; Set-Pensando; Set-Cara 'si'; $ui.Escribir.Visibility = 'Collapsed' }
        $tecla.Handled = $true
    })

# Mientras escribo, NoNo me escucha: se inclina hacia el globo y abre el ojo.
$ui.Entrada.Add_TextChanged({
        if (-not $ui.Entrada.Text) { return }
        if ($script:gesto -ne 'escucha' -and $script:gesto -ne 'pensando') { Set-Cara 'escucha' }
        $callado.Stop(); $callado.Start()
        $sueno.Stop(); $sueno.Start()
    })

# --- Arranque y bucle -------------------------------------------------------------
$app = New-Object Windows.Application
$app.ShutdownMode = 'OnExplicitShutdown'
$globo.Left = -4000; $globo.Top = -4000   # fuera de vista hasta saber donde va
$globo.Show()
[NoNo.Win]::Estilo((Get-Mano $globo), 0x80)

$reloj = New-Object Windows.Threading.DispatcherTimer
$reloj.Interval = [TimeSpan]::FromMilliseconds(250)
$reloj.Add_Tick({
        try {
            $e = Read-Estado
            if ($null -eq $e) {
                # Si el archivo desaparece ~5 s, el mod ya no esta: me cierro solo.
                $script:faltas++
                if ($script:faltas -gt 20) { $app.Shutdown() }
                return
            }
            $script:faltas = 0
            if ($e.rev -ne $script:rev) { $script:rev = $e.rev; Update-Vista $e }
        } catch {
            [Console]::Error.WriteLine("nono: $($_.Exception.Message)")
        }
    })
$reloj.Start()
$azar = New-Object Random
# Cuando espera instrucciones, de vez en cuando sigue mi mouse con la mirada unos
# segundos: el ojo se corre hacia donde esta el cursor y luego vuelve al centro.
$script:ticsMirada = 0
$script:ojo = @(0.0, 0.0)
$mirada = New-Reloj 90 {
    $script:ticsMirada--
    $meta = @(0.0, 0.0)
    if ($script:ticsMirada -gt 6 -and $script:gesto -eq 'neutral') {
        $cursor = [Windows.Forms.Cursor]::Position
        $dx = $cursor.X - $script:punta[0]; $dy = $cursor.Y - $script:punta[1]
        $largo = [Math]::Max(1, [Math]::Sqrt($dx * $dx + $dy * $dy))
        $meta = @((24 * $dx / $largo), (24 * $dy / $largo))
    }
    $script:ojo = @(($script:ojo[0] + ($meta[0] - $script:ojo[0]) * 0.3), ($script:ojo[1] + ($meta[1] - $script:ojo[1]) * 0.3))
    if ($script:ticsMirada -le 0) { $mirada.Stop(); $script:ojo = @(0.0, 0.0) }
    foreach ($n in $nonos) { $n.MiraOjo.X = $script:ojo[0]; $n.MiraOjo.Y = $script:ojo[1] }
}
$parpado = New-Object Windows.Threading.DispatcherTimer
$parpado.Interval = [TimeSpan]::FromMilliseconds(3200)
$parpado.Add_Tick({
        if ($script:gesto -in 'dormido', 'escucha', 'pensando') { return }
        $dado = $azar.Next(0, 100)
        if ($dado -lt 40 -and $script:gesto -eq 'neutral' -and $script:modo -eq 'mascota' -and $null -ne $script:punta) {
            $script:ticsMirada = 45; $mirada.Start()
        } else { Invoke-Parpadeo $nonos $dado }
        $parpado.Interval = [TimeSpan]::FromMilliseconds($azar.Next(2800, 6000))
    })
$parpado.Start()
. (Join-Path $PSScriptRoot 'autoprueba.ps1')   # no hace nada salvo que NONO_PRUEBA exista
Send-Evento @{ t = 'viva'; escala = $modoEscala }
[void]$app.Run()
Remove-Item $pidArchivo -Force -ErrorAction SilentlyContinue
