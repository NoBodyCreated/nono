# NoNo - autoprueba: NoNo pulsa sus propios botones.
# Autoria intelectual: Felipe Restrepo Velez; asistido por Claude.
#
# Sirve para probar el recorrido completo (ventana -> mod -> sesion -> ventana)
# sin que nadie toque el mouse. Solo corre si la variable de entorno
# NONO_PRUEBA trae una lista de eventos separados por punto y coma, por ejemplo
#   NONO_PRUEBA = "listo;msg:esto cuesta algo;nolo;listo"
# Cada 4 segundos emite el siguiente, igual que si yo lo hubiera hecho en el globo.
# En el uso normal la variable no existe y este archivo no hace nada.
if ($env:NONO_PRUEBA) {
    $script:colaPrueba = @($env:NONO_PRUEBA -split ';' | Where-Object { $_ })
    $script:indicePrueba = 0
    $script:relojPrueba = New-Object Windows.Threading.DispatcherTimer
    $script:relojPrueba.Interval = [TimeSpan]::FromSeconds(4)
    $script:relojPrueba.Add_Tick({
            if ($script:indicePrueba -ge $script:colaPrueba.Count) { $script:relojPrueba.Stop(); return }
            $orden = [string]$script:colaPrueba[$script:indicePrueba]
            $script:indicePrueba++
            if ($orden -like 'msg:*') { Send-Evento @{ t = 'msg'; texto = $orden.Substring(4) } }
            else { Send-Evento @{ t = $orden } }
        })
    $script:relojPrueba.Start()
}
