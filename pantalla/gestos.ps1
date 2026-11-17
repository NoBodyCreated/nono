# NoNo - sus expresiones.
# Autoria intelectual: Felipe Restrepo Velez; asistido por Claude.
#
# NoNo no tiene boca ni manos: es mi isotipo. Se expresa como los robots de
# caricatura que dicen mucho con pocas piezas: ladea la cabeza, cambia la forma
# del ojo, sube o baja las pestanas, se encoge antes de saltar y rebota al caer.
# Cada gesto es un conjunto de "pistas": una pieza, una propiedad y unos puntos
# en el tiempo, unidos con curvas (nunca en linea recta). Ninguno cambia la
# geometria del logo: al terminar, todo vuelve a su sitio.
#
# Regla que me pidio Felipe: siempre debe entenderse POR QUE hace el gesto. Por
# eso cada gesto nace de algo que pasa (escribo, llega una respuesta, no
# encuentro algo) y va con una palabra corta junto a su nombre en el globo.
#
#   hola      aparece                      salta y saluda con un arco
#   guino     muestra un paso ("aqui")     se encoge, ladea y guina
#   escucha   estoy escribiendo            se inclina hacia el globo, ojo grande
#   pensando  Claude trabaja               mira arriba, los arcos giran a pulsos
#   feliz     llego la respuesta           dos saltos y ojo sonriente
#   ceja      no encuentro algo            alza una pestana, baja la otra, busca
#   si        pulse LISTO                  asiente dos veces
#   no        algo fallo                   niega con la cabeza, ojo caido
#   dormido   llevo rato sin usarlo        ojo entrecerrado, respira lento
#   clic      hace clic por mi             se aplasta contra el punto, como un dedo
#   teclea    escribe por mi               repica rapido y el ojo sigue el renglon
#   rueda     desplaza la pagina           los arcos dan una vuelta, como una rueda

$SX = [Windows.Media.ScaleTransform]::ScaleXProperty
$SY = [Windows.Media.ScaleTransform]::ScaleYProperty
$ANG = [Windows.Media.RotateTransform]::AngleProperty
$TX = [Windows.Media.TranslateTransform]::XProperty
$TY = [Windows.Media.TranslateTransform]::YProperty

# Las palabras que acompanan cada gesto (con [char] para no romper el ASCII).
$script:ANIMO = @{
    hola = "$([char]0xA1)hola!"; guino = "aqu$([char]0xED)"; escucha = 'te escucho'
    pensando = 'pensando...'; feliz = "$([char]0xA1)listo!"; ceja = "$([char]0xBF)d$([char]0xF3)nde?"
    clic = 'clic'; teclea = 'escribo'; rueda = 'desplazo'
    si = 'entendido'; no = "algo fall$([char]0xF3)"; dormido = 'zzz'; neutral = ''
}
# Gestos que pasan solos y devuelven la cara neutra.
$script:PASAJEROS = @('hola', 'guino', 'feliz', 'si', 'no', 'clic', 'teclea', 'rueda')

function New-Curva([string]$nombre) {
    switch ($nombre) {
        'rebote' { return New-Object Windows.Media.Animation.BackEase -Property @{ EasingMode = 'EaseOut'; Amplitude = 0.7 } }
        'elastico' { return New-Object Windows.Media.Animation.ElasticEase -Property @{ EasingMode = 'EaseOut'; Oscillations = 2; Springiness = 5 } }
        default { return New-Object Windows.Media.Animation.SineEase -Property @{ EasingMode = 'EaseInOut' } }
    }
}

# Una pista: puntos (milisegundos, valor) unidos con una curva.
# $fin: 'vuelve' (suelta la pieza al terminar), 'queda' (se queda en el ultimo valor) o 'ciclo'.
function Start-Pista($pieza, $prop, [object[]]$puntos, [string]$curva = 'seno', [string]$fin = 'vuelve') {
    $a = New-Object Windows.Media.Animation.DoubleAnimationUsingKeyFrames
    foreach ($p in $puntos) {
        $clave = New-Object Windows.Media.Animation.EasingDoubleKeyFrame
        $clave.KeyTime = [Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds($p[0]))
        $clave.Value = $p[1]
        $clave.EasingFunction = New-Curva $curva
        [void]$a.KeyFrames.Add($clave)
    }
    if ($fin -eq 'vuelve') { $a.FillBehavior = 'Stop' }
    if ($fin -eq 'ciclo') { $a.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever }
    $pieza.BeginAnimation($prop, $a)
}

# Lo mismo en ancho y alto a la vez (crecer o encogerse parejo).
function Start-Par($pieza, [object[]]$puntos, [string]$curva = 'seno', [string]$fin = 'vuelve') {
    Start-Pista $pieza $SX $puntos $curva $fin
    Start-Pista $pieza $SY $puntos $curva $fin
}

# Encoger y estirar: lo que pierde de alto lo gana de ancho, como una gota.
function Start-Gota($n, [object[]]$alto, [string]$curva = 'seno') {
    $ancho = @(); foreach ($p in $alto) { $ancho += , @($p[0], (2 - $p[1])) }
    Start-Pista $n.Aplasta $SY $alto $curva
    Start-Pista $n.Aplasta $SX $ancho $curva
}

function Reset-Cara($n) {
    foreach ($par in @(
            @($n.Aplasta, $SX), @($n.Aplasta, $SY), @($n.Ladeo, $ANG), @($n.Salto, $TX), @($n.Salto, $TY),
            @($n.GiroAros, $ANG), @($n.EscArriba, $SX), @($n.EscArriba, $SY), @($n.GiroArriba, $ANG),
            @($n.EscAbajo, $SX), @($n.EscAbajo, $SY), @($n.GiroAbajo, $ANG), @($n.GiroDer, $ANG),
            @($n.EscOjo, $SX), @($n.EscOjo, $SY), @($n.MiraOjo, $TX), @($n.MiraOjo, $TY))) {
        $par[0].BeginAnimation($par[1], $null)
    }
}

# Parpadeo espontaneo. A veces doble, y a veces una miradita de curiosidad.
function Invoke-Parpadeo($nonos, [int]$dado) {
    foreach ($n in $nonos) {
        if ($dado -lt 25) { Start-Pista $n.EscOjo $SY @(@(0, 1), @(80, 0.08), @(170, 1), @(260, 0.08), @(360, 1)) }
        elseif ($dado -lt 45) { Start-Pista $n.MiraOjo $TX @(@(0, 0), @(260, 16), @(900, 16), @(1200, 0)) 'rebote' }
        else { Start-Pista $n.EscOjo $SY @(@(0, 1), @(90, 0.08), @(200, 1)) }
    }
}

function Set-Gesto($nonos, [string]$gesto) {
    foreach ($n in $nonos) {
        Reset-Cara $n
        switch ($gesto) {
            'hola' {
                Start-Pista $n.Salto $TY @(@(0, 0), @(130, 20), @(400, -50), @(640, 0), @(760, -12), @(880, 0))
                Start-Gota $n @(@(0, 1), @(130, 0.8), @(400, 1.14), @(640, 0.9), @(880, 1))
                Start-Pista $n.GiroDer $ANG @(@(0, 0), @(420, -30), @(600, 8), @(780, -24), @(960, 6), @(1150, 0))
                Start-Par $n.EscOjo @(@(0, 1), @(380, 1.28), @(1000, 1.28), @(1250, 1)) 'rebote'
            }
            'guino' {
                Start-Gota $n @(@(0, 1), @(120, 0.8), @(320, 1.12), @(620, 1)) 'elastico'
                Start-Pista $n.Ladeo $ANG @(@(0, 0), @(300, 13), @(1000, 13), @(1400, 0)) 'rebote'
                Start-Pista $n.EscOjo $SY @(@(0, 1), @(480, 1), @(600, 0.08), @(940, 0.08), @(1100, 1))
                Start-Pista $n.EscOjo $SX @(@(0, 1), @(480, 1), @(600, 1.2), @(940, 1.2), @(1100, 1))
                Start-Pista $n.GiroArriba $ANG @(@(0, 0), @(480, 0), @(600, 15), @(940, 15), @(1100, 0)) 'rebote'
                Start-Par $n.EscArriba @(@(0, 1), @(480, 1), @(600, 0.9), @(940, 0.9), @(1100, 1))
            }
            'escucha' {
                Start-Pista $n.Ladeo $ANG @(@(0, 0), @(320, 10)) 'rebote' 'queda'
                Start-Par $n.EscOjo @(@(0, 1), @(280, 1.22)) 'rebote' 'queda'
                Start-Par $n.EscArriba @(@(0, 1), @(300, 1.15)) 'rebote' 'queda'
                Start-Par $n.EscAbajo @(@(0, 1), @(300, 1.08)) 'rebote' 'queda'
                Start-Pista $n.MiraOjo $TX @(@(0, 0), @(300, 16)) 'seno' 'queda'
            }
            'pensando' {
                # Los arcos giran a pulsos (media vuelta, pausa, media vuelta) y el ojo mira arriba, de lado a lado.
                Start-Pista $n.GiroAros $ANG @(@(0, 0), @(900, 180), @(1100, 180), @(2000, 360), @(2200, 360)) 'seno' 'ciclo'
                Start-Pista $n.MiraOjo $TY @(@(0, 0), @(300, -18)) 'seno' 'queda'
                Start-Pista $n.MiraOjo $TX @(@(0, -12), @(1300, 12), @(2600, -12)) 'seno' 'ciclo'
                Start-Pista $n.Ladeo $ANG @(@(0, -6), @(1500, 6), @(3000, -6)) 'seno' 'ciclo'
            }
            'feliz' {
                Start-Pista $n.Salto $TY @(@(0, 0), @(110, 16), @(320, -48), @(500, 0), @(610, 10), @(800, -28), @(980, 0))
                Start-Gota $n @(@(0, 1), @(110, 0.8), @(320, 1.15), @(500, 0.88), @(610, 0.9), @(800, 1.08), @(980, 1))
                Start-Pista $n.EscOjo $SY @(@(0, 1), @(160, 0.48), @(1250, 0.48), @(1500, 1)) 'rebote'
                Start-Pista $n.EscOjo $SX @(@(0, 1), @(160, 1.18), @(1250, 1.18), @(1500, 1)) 'rebote'
                Start-Par $n.EscArriba @(@(0, 1), @(320, 1.3), @(620, 1.04), @(800, 1.22), @(1300, 1)) 'elastico'
                Start-Par $n.EscAbajo @(@(0, 1), @(320, 1.3), @(620, 1.04), @(800, 1.22), @(1300, 1)) 'elastico'
                Start-Pista $n.GiroAros $ANG @(@(0, 0), @(320, -16), @(620, 14), @(980, 0))
            }
            'ceja' {
                Start-Pista $n.Ladeo $ANG @(@(0, 0), @(340, -15)) 'rebote' 'queda'
                Start-Par $n.EscArriba @(@(0, 1), @(300, 1.26)) 'rebote' 'queda'
                Start-Pista $n.GiroArriba $ANG @(@(0, 0), @(300, -13)) 'rebote' 'queda'
                Start-Par $n.EscAbajo @(@(0, 1), @(300, 0.82)) 'seno' 'queda'
                Start-Pista $n.GiroAbajo $ANG @(@(0, 0), @(300, 9)) 'seno' 'queda'
                Start-Pista $n.EscOjo $SX @(@(0, 1), @(300, 0.86)) 'seno' 'queda'
                # Busca con la mirada: a un lado, al otro, y vuelve.
                Start-Pista $n.MiraOjo $TX @(@(0, 0), @(500, -24), @(1100, -24), @(1700, 24), @(2300, 24), @(2800, 0)) 'seno' 'ciclo'
            }
            'si' {
                Start-Pista $n.Salto $TY @(@(0, 0), @(130, 18), @(260, 0), @(390, 15), @(540, 0))
                Start-Gota $n @(@(0, 1), @(130, 0.88), @(260, 1.04), @(390, 0.9), @(540, 1))
                Start-Pista $n.EscOjo $SY @(@(0, 1), @(130, 0.55), @(260, 1), @(390, 0.55), @(540, 1))
            }
            'no' {
                Start-Pista $n.Salto $TX @(@(0, 0), @(90, -20), @(200, 20), @(310, -17), @(420, 14), @(520, -8), @(640, 0))
                Start-Pista $n.EscOjo $SY @(@(0, 1), @(140, 0.4), @(1500, 0.4), @(1800, 1))
                Start-Par $n.EscArriba @(@(0, 1), @(220, 0.88), @(1500, 0.88), @(1800, 1))
                Start-Pista $n.GiroArriba $ANG @(@(0, 0), @(220, 11), @(1500, 11), @(1800, 0))
                Start-Gota $n @(@(0, 1), @(220, 0.92), @(1500, 0.92), @(1800, 1))
            }
            'clic' {
                Start-Gota $n @(@(0, 1), @(90, 0.68), @(240, 1.14), @(440, 1)) 'rebote'
                Start-Par $n.EscOjo @(@(0, 1), @(90, 0.7), @(320, 1)) 'rebote'
            }
            'teclea' {
                Start-Pista $n.Salto $TY @(@(0, 0), @(70, 7), @(140, 0), @(210, 7), @(280, 0), @(350, 7), @(420, 0), @(490, 7), @(560, 0))
                Start-Pista $n.MiraOjo $TX @(@(0, -12), @(560, 14), @(720, 0))
            }
            'rueda' {
                Start-Pista $n.GiroAros $ANG @(@(0, 0), @(650, 360))
                Start-Pista $n.Salto $TY @(@(0, 0), @(260, 22), @(650, 0)) 'rebote'
            }
            'dormido' {
                Start-Pista $n.EscOjo $SY @(@(0, 1), @(900, 0.3)) 'seno' 'queda'
                Start-Par $n.EscArriba @(@(0, 1), @(900, 0.9)) 'seno' 'queda'
                Start-Pista $n.GiroArriba $ANG @(@(0, 0), @(900, 9)) 'seno' 'queda'
                Start-Pista $n.Ladeo $ANG @(@(0, 0), @(1100, 11)) 'seno' 'queda'
                Start-Pista $n.Aplasta $SY @(@(0, 1), @(2200, 1.06), @(4400, 1)) 'seno' 'ciclo'
            }
            default { }
        }
    }
}
