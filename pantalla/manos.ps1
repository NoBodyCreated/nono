# NoNo - sus manos: hacer clic, escribir y desplazar por mi.
# Autoria intelectual: Felipe Restrepo Velez; asistido por Claude.
#
# Cuando Claude le pide una accion, NoNo primero vuela al punto (para que yo
# vea donde va a actuar), hace su gesto y solo entonces mueve el mouse o el
# teclado de verdad. Al terminar avisa al mod con un evento 'hecho', y el mod
# borra la accion para que nunca se repita sola (por ejemplo, al reabrir a NoNo).
# Usa Set-Cara y New-Reloj, que define nono.ps1. Los clones (clones.ps1) usan
# las mismas manos: Send-Entrada es lo unico que toca el mouse y el teclado.
Add-Type -AssemblyName System.Windows.Forms

# El gesto que corresponde a cada accion.
$script:GESTO_DE = @{ clic = 'clic'; escribir = 'teclea'; scroll = 'rueda' }

# Mueve el mouse o el teclado de verdad. $a trae tipo, x, y, texto y cantidad.
function Send-Entrada($a) {
    $hayPunto = ($null -ne $a.x) -and ($null -ne $a.y)
    switch ([string]$a.tipo) {
        'clic' { [NoNo.Win]::Clic([int]$a.x, [int]$a.y) }
        'escribir' {
            if ($hayPunto) { [NoNo.Win]::Clic([int]$a.x, [int]$a.y); Start-Sleep -Milliseconds 180 }
            # SendKeys trata + ^ % ~ ( ) { } [ ] como ordenes: las escapo para que salgan tal cual.
            $texto = [regex]::Replace([string]$a.texto, '[+^%~(){}\[\]]', '{$0}')
            [Windows.Forms.SendKeys]::SendWait($texto.Replace("`r", '').Replace("`n", '{ENTER}'))
        }
        'scroll' { [NoNo.Win]::Rueda([int]$a.x, [int]$a.y, [int]$a.cantidad) }
    }
}

$script:accionHecha = ''
$script:accionPendiente = $null

function Invoke-Accion {
    $a = $script:accionPendiente
    $script:accionPendiente = $null
    if (-not $a) { return }
    try {
        Set-Cara ([string]$script:GESTO_DE[[string]$a.tipo])
        Send-Entrada $a
        Send-Evento @{ t = 'hecho'; id = [string]$a.id }
    } catch {
        Send-Evento @{ t = 'hecho'; id = [string]$a.id; error = $_.Exception.Message }
    }
}

# Espero a que NoNo llegue al punto (el vuelo dura menos de un segundo) y actuo.
$actua = New-Reloj 950 { $actua.Stop(); Invoke-Accion }

function Start-Accion($a) {
    if (-not $a -or -not [string]$a.id -or [string]$a.id -eq $script:accionHecha) { return }
    $script:accionHecha = [string]$a.id
    $script:accionPendiente = $a
    $actua.Stop(); $actua.Start()
}
