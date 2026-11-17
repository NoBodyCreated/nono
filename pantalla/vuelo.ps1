# NoNo - como se mueve por la pantalla: de mascota a puntero y de vuelta.
# Autoria intelectual: Felipe Restrepo Velez; asistido por Claude.
#
# NoNo tiene dos oficios y pasa de uno a otro sin cortes:
#   mascota  posado sobre la esquina de su globo, grande, flotando
#   puntero  sobre el punto exacto que senala, del tamano de una mira, latiendo
# Al volar se inclina hacia donde va y al llegar se aplasta y rebota, como algo
# con peso. Todo se mueve en pixeles fisicos (ver win32.ps1).
# Este archivo usa las ventanas y piezas que crea nono.ps1 ($puntero, $globo, $grande).

$talla = $puntero.FindName('Talla')
$respira = $puntero.FindName('Respira')
$flote = $puntero.FindName('Flote')
$inclina = $puntero.FindName('Inclina')
$aterriza = $puntero.FindName('Aterriza')

# El ancla es el centro de NoNo: el punto de su ventana que cae sobre el objetivo.
$ANCLA_X = 120; $ANCLA_Y = 120
$script:modo = ''            # 'mascota' o 'puntero'
$script:punta = $null        # donde esta hoy el ancla, en pixeles fisicos
$script:meta = $null         # a donde va

function Get-Mano($ventana) { (New-Object Windows.Interop.WindowInteropHelper($ventana)).Handle }

# Cuantos pixeles fisicos mide hoy una unidad WPF de esa ventana. Lo mido en
# vez de suponerlo, porque cambia segun el monitor donde este.
function Get-Factor($ventana) {
    $c = [NoNo.Win]::Caja((Get-Mano $ventana))
    if ($ventana.ActualWidth -gt 0) { return ($c.R - $c.L) / $ventana.ActualWidth }
    return 1.0
}

function Set-Punta([double]$x, [double]$y) {
    $script:punta = @($x, $y)
    $f = Get-Factor $puntero
    [NoNo.Win]::Mover((Get-Mano $puntero), [int]($x - $ANCLA_X * $f), [int]($y - $ANCLA_Y * $f))
}

# Cambio de tamano con un rebote. 1.2 es la mascota; como puntero se ajusta a lo
# que senala (ver Update-Vista) para no tapar un icono chico ni perderse en un boton grande.
$script:tallaHoy = 1.2
function Set-Talla([double]$k) {
    if ([Math]::Abs($k - $script:tallaHoy) -lt 0.02) { return }
    Start-Par $talla @(@(0, $script:tallaHoy), @(420, $k)) 'rebote' 'queda'
    $script:tallaHoy = $k
}

# Cambio de oficio: cambia de talla mientras vuela y, al llegar, late o flota.
function Set-Modo([string]$modo) {
    if ($modo -eq $script:modo) { return }
    $script:modo = $modo
    if ($modo -eq 'puntero') {
        Set-Talla 0.78
        $flote.BeginAnimation($TY, $null)
        Start-Par $respira @(@(0, 1), @(650, 1.14), @(1300, 1)) 'seno' 'ciclo'
    } else {
        Set-Talla 1.2
        $respira.BeginAnimation($SX, $null); $respira.BeginAnimation($SY, $null)
        Start-Pista $flote $TY @(@(0, -3), @(1600, 3), @(3200, -3)) 'seno' 'ciclo'
    }
}

# El vuelo: cada cuadro avanza una fraccion de lo que falta (arranca rapido y frena suave).
$desliz = New-Object Windows.Threading.DispatcherTimer
$desliz.Interval = [TimeSpan]::FromMilliseconds(16)
$desliz.Add_Tick({
        $dx = $script:meta[0] - $script:punta[0]; $dy = $script:meta[1] - $script:punta[1]
        if ([Math]::Abs($dx) -lt 2 -and [Math]::Abs($dy) -lt 2) {
            Set-Punta $script:meta[0] $script:meta[1]
            Set-Punta $script:meta[0] $script:meta[1]   # dos veces: al cambiar de monitor cambia el factor
            $desliz.Stop()
            # Aterriza: se endereza con un rebote y se aplasta un instante.
            Start-Pista $inclina $ANG @(@(0, $script:inclinado), @(520, 0)) 'elastico'
            Start-Pista $aterriza $SY @(@(0, 1), @(90, 0.78), @(260, 1.1), @(480, 1)) 'rebote'
            Start-Pista $aterriza $SX @(@(0, 1), @(90, 1.2), @(260, 0.93), @(480, 1)) 'rebote'
            return
        }
        Set-Punta ($script:punta[0] + $dx * 0.22) ($script:punta[1] + $dy * 0.22)
    })
$script:inclinado = 0

# Como puntero dejo pasar los clics (0x20) para no tapar lo que senalo; como
# mascota los recibo, porque un clic sobre NoNo despliega el cuadro de texto.
function Set-Atravesable {
    $mano = Get-Mano $puntero
    if ($script:modo -eq 'puntero') { [NoNo.Win]::Estilo($mano, 0x20) } else { [NoNo.Win]::SinEstilo($mano, 0x20) }
}

function Move-Puntero([double]$x, [double]$y) {
    $script:meta = @($x, $y)
    if ($null -eq $script:punta) {
        $puntero.Left = -4000; $puntero.Top = -4000
        $puntero.Show()
        # 0x80 fuera de Alt+Tab, 0x08000000 nunca toma el foco.
        [NoNo.Win]::Estilo((Get-Mano $puntero), (0x80 -bor 0x08000000))
        Set-Atravesable
        Set-Punta $x $y; Set-Punta $x $y
        return
    }
    $tramo = $x - $script:punta[0]
    if ([Math]::Abs($tramo) -gt 40 -or [Math]::Abs($y - $script:punta[1]) -gt 40) {
        # Se inclina hacia donde va, mas cuanto mas lejos.
        $script:inclinado = [Math]::Max(-18, [Math]::Min(18, $tramo / 30))
        Start-Pista $inclina $ANG @(@(0, 0), @(160, $script:inclinado)) 'seno' 'queda'
    }
    Set-Atravesable
    $desliz.Start()
}

# Ubico el globo: junto al punto si lo hay; si no, en la esquina de abajo a la derecha.
function Set-Globo($e, [bool]$hayPunto) {
    $mano = Get-Mano $globo
    foreach ($vuelta in 1, 2) {   # dos vueltas: si cambio de monitor, cambia de tamano
        $c = [NoNo.Win]::Caja($mano); $gw = $c.R - $c.L; $gh = $c.B - $c.T
        $f = Get-Factor $globo
        if ($hayPunto) {
            $z = [NoNo.Win]::Zona([int]$e.x, [int]$e.y)
            $sep = 64 * $f
            $izq = [double]$e.x + $sep
            if ($izq + $gw -gt $z.R) { $izq = [double]$e.x - $sep - $gw }
            $arr = [double]$e.y - 70 * $f
        } else {
            $z = [NoNo.Win]::Zona(0, 0)
            $izq = $z.R - $gw - 16 * $f; $arr = $z.B - $gh - 16 * $f
        }
        $izq = [Math]::Max($z.L + 8, [Math]::Min($izq, $z.R - $gw - 8))
        $arr = [Math]::Max($z.T + 8, [Math]::Min($arr, $z.B - $gh - 8))
        [NoNo.Win]::Mover($mano, [int]$izq, [int]$arr)
    }
}

# La percha: donde se posa NoNo cuando es mascota, sobre la esquina del globo.
function Get-Percha {
    $c = [NoNo.Win]::Caja((Get-Mano $globo))
    $f = Get-Factor $globo
    return @(($c.L + 34 * $f), ($c.T - 32 * $f))
}

# Cuando el globo cruza a un monitor con otra escala, Windows lo reacomoda un
# instante despues y me lo deja corrido (lo vi en la prueba: quedo a la izquierda
# del punto). Por eso lo vuelvo a ubicar una vez mas, 200 ms despues.
$script:ultimo = $null
$reubica = New-Object Windows.Threading.DispatcherTimer
$reubica.Interval = [TimeSpan]::FromMilliseconds(200)
$reubica.Add_Tick({
        $reubica.Stop()
        if ($null -eq $script:ultimo) { return }
        $hay = ($null -ne $script:ultimo.x) -and ($null -ne $script:ultimo.y)
        if (-not $script:fijo) { Set-Globo $script:ultimo $hay }
        if (-not $hay) { $percha = Get-Percha; Move-Puntero $percha[0] $percha[1] }
    })
