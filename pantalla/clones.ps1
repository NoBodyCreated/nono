# NoNo - sus clones: varios NoNo de colores para varias tareas a la vez.
# Autoria intelectual: Felipe Restrepo Velez; asistido por Claude.
#
# Cuando hay varias cosas que senalar o hacer, NoNo saca clones con los otros
# colores de mi marca (magenta, ambar, blanco). Cada clon sale volando desde
# donde esta NoNo hasta su punto, con un rotulo corto que dice que le toca.
#
# Limite real que no escondo: Windows tiene UN mouse y UN teclado. Los clones
# SENALAN todos a la vez, pero ACTUAN por turnos, uno cada segundo, cada uno
# con su gesto. Las manos son las mismas de manos.ps1 (Send-Entrada).
# Usa New-NoNo, Get-Mano, Get-Factor, New-Reloj y Set-Gesto.

$script:clones = @{}      # id -> @{ Ventana; NoNo; Punta; Meta; Llego; Dato }
$script:loteHecho = ''    # el ultimo lote de acciones que ya corri
$script:cola = @()        # clones que esperan su turno para actuar

function New-Clon($c) {
    $ventana = [Windows.Markup.XamlReader]::Parse($script:XAML_PUNTERO)
    $nono = New-NoNo ([string]$c.color)
    $ventana.FindName('Cuerpo').Child = $nono.Dibujo
    $talla = $ventana.FindName('Talla'); $talla.ScaleX = 0.62; $talla.ScaleY = 0.62
    # El rotulo: una ficha de tinta con el texto del color del clon, debajo de el.
    $rotulo = New-Object Windows.Controls.TextBlock
    $rotulo.Text = [string]$c.rotulo
    $rotulo.Width = 200; $rotulo.TextAlignment = 'Center'; $rotulo.TextWrapping = 'Wrap'
    $rotulo.FontSize = 11; $rotulo.FontWeight = 'Bold'; $rotulo.Padding = '4,2,4,2'
    $rotulo.FontFamily = New-Object Windows.Media.FontFamily('IBM Plex Mono, Consolas')
    $pinceles = New-Object Windows.Media.BrushConverter
    $rotulo.Foreground = $pinceles.ConvertFromString([string]$c.color)
    $rotulo.Background = $pinceles.ConvertFromString('#E6070A0E')
    [Windows.Controls.Canvas]::SetLeft($rotulo, 20); [Windows.Controls.Canvas]::SetTop($rotulo, 152)
    [void]$ventana.Content.Children.Add($rotulo)
    $ventana.Left = -4000; $ventana.Top = -4000
    $ventana.Show()
    # Siempre atravesable al clic: un clon nunca tapa lo que senala.
    [NoNo.Win]::Estilo((Get-Mano $ventana), (0x20 -bor 0x80 -bor 0x08000000))
    # Nace donde esta NoNo, para que se vea que sale de el.
    $origen = if ($null -ne $script:punta) { @($script:punta[0], $script:punta[1]) } else { @([double]$c.x, [double]$c.y) }
    return @{ Ventana = $ventana; NoNo = $nono; Punta = $origen; Meta = $origen; Llego = $false; Dato = $c }
}

function Set-PuntaClon($k, [double]$x, [double]$y) {
    $k.Punta = @($x, $y)
    $f = Get-Factor $k.Ventana
    [NoNo.Win]::Mover((Get-Mano $k.Ventana), [int]($x - 120 * $f), [int]($y - 120 * $f))
}

# Un solo reloj mueve a todos los clones: cada cuadro avanzan una fraccion de lo que les falta.
$enjambre = New-Reloj 16 {
    $faltan = 0
    foreach ($k in @($script:clones.Values)) {
        if ($k.Llego) { continue }
        $dx = $k.Meta[0] - $k.Punta[0]; $dy = $k.Meta[1] - $k.Punta[1]
        if ([Math]::Abs($dx) -lt 2 -and [Math]::Abs($dy) -lt 2) {
            Set-PuntaClon $k $k.Meta[0] $k.Meta[1]; Set-PuntaClon $k $k.Meta[0] $k.Meta[1]
            $k.Llego = $true
            Set-Gesto @($k.NoNo) 'guino'
        } else {
            Set-PuntaClon $k ($k.Punta[0] + $dx * 0.18) ($k.Punta[1] + $dy * 0.18)
            $faltan++
        }
    }
    if ($faltan -eq 0) { $enjambre.Stop() }
}

# El turno: el siguiente clon de la cola hace su gesto y actua. Al vaciarse la cola aviso al mod.
$turno = New-Reloj 1000 {
    if ($script:cola.Count -eq 0) {
        $turno.Stop()
        Send-Evento @{ t = 'hecho'; id = "lote:$($script:loteHecho)" }
        return
    }
    $id = $script:cola[0]
    $script:cola = @($script:cola | Select-Object -Skip 1)
    $k = $script:clones[$id]
    if (-not $k) { return }
    try {
        Set-Gesto @($k.NoNo) ([string]$script:GESTO_DE[[string]$k.Dato.tipo])
        Send-Entrada $k.Dato
    } catch { [Console]::Error.WriteLine("nono clon ${id}: $($_.Exception.Message)") }
}

# Pongo los clones como dice el estado: creo los que falten, muevo los que ya estan y despido a los que sobran.
function Sync-Clones($e) {
    $vistos = @{}
    foreach ($c in @($e.clones)) {
        if (-not $c) { continue }
        $id = [string]$c.id
        $vistos[$id] = $true
        if (-not $script:clones.ContainsKey($id)) { $script:clones[$id] = New-Clon $c }
        $k = $script:clones[$id]
        $k.Meta = @([double]$c.x, [double]$c.y); $k.Llego = $false; $k.Dato = $c
    }
    foreach ($id in @($script:clones.Keys)) {
        if (-not $vistos.ContainsKey($id)) { $script:clones[$id].Ventana.Close(); $script:clones.Remove($id) }
    }
    if ($script:clones.Count -gt 0) { $enjambre.Start() }
    # Un lote nuevo de acciones: las encolo una sola vez, en orden.
    $lote = [string]$e.lote
    if ($lote -and $lote -ne $script:loteHecho) {
        $script:loteHecho = $lote
        $script:cola = @($script:clones.Keys | Sort-Object | Where-Object { [string]$script:clones[$_].Dato.tipo })
        $turno.Stop(); $turno.Start()
    }
}
