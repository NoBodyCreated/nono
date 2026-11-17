# NoNo - lo que se dibuja: mi isotipo y sus dos ventanas (WPF).
# Autoria intelectual: Felipe Restrepo Velez; asistido por Claude.
#
# NoNo ES el isotipo de mi marca: el aro del centro y sus cuatro arcos, con la
# geometria exacta de sitio/marca/isotipo.svg (no lo redibujo a ojo). El aro es
# su ojo y los arcos de arriba y de abajo son sus pestanas; cada pieza tiene su
# propia transformacion para que gestos.ps1 la pueda mover.
# ASCII puro: PowerShell 5.1 lee los .ps1 sin BOM como ANSI y me danaria las
# tildes; las de la interfaz van como entidades XAML.

# Mi paleta de marca: tinta, cian, magenta, ambar y un blanco frio para texto.
$script:PALETA = @{ C = '#36E2C4'; K = '#070A0E'; M = '#FF4FB0'; A = '#FFB23E'; W = '#EAF6F4' }

# El isotipo sobre su lienzo original de 400x400. Cada trazo va dos veces: uno
# ancho de tinta debajo y el cian encima, para que se lea igual sobre una pagina
# blanca que sobre una oscura. El centro del logo es (198.61, 199.66).
$script:XAML_NONO = @'
<Canvas xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="400" Height="400">
  <Canvas.Resources>
    <Style x:Key="Tinta" TargetType="Path">
      <Setter Property="Stroke" Value="#070A0E"/><Setter Property="StrokeThickness" Value="56"/>
    </Style>
    <Style x:Key="Cian" TargetType="Path">
      <Setter Property="Stroke" Value="#36E2C4"/><Setter Property="StrokeThickness" Value="31.18"/>
    </Style>
  </Canvas.Resources>
  <Canvas>
    <Canvas.RenderTransform><TransformGroup>
      <ScaleTransform x:Name="Aplasta" CenterX="198.61" CenterY="320"/>
      <RotateTransform x:Name="Ladeo" CenterX="198.61" CenterY="199.66"/>
      <TranslateTransform x:Name="Salto"/>
    </TransformGroup></Canvas.RenderTransform>
    <Canvas>
      <Canvas.RenderTransform><RotateTransform x:Name="GiroAros" CenterX="198.61" CenterY="199.66"/></Canvas.RenderTransform>
      <Canvas>
        <Canvas.RenderTransform><TransformGroup><ScaleTransform x:Name="EscArriba" CenterX="198.61" CenterY="199.66"/><RotateTransform x:Name="GiroArriba" CenterX="198.61" CenterY="199.66"/></TransformGroup></Canvas.RenderTransform>
        <Path Style="{StaticResource Tinta}" Data="M291.26,123.07c-11.78-12.68-26.19-23.3-42.91-30.95-16.72-7.65-34.18-11.62-51.47-12.25"/>
        <Path Style="{StaticResource Cian}" Data="M291.26,123.07c-11.78-12.68-26.19-23.3-42.91-30.95-16.72-7.65-34.18-11.62-51.47-12.25"/>
      </Canvas>
      <Canvas>
        <Canvas.RenderTransform><TransformGroup><ScaleTransform x:Name="EscAbajo" CenterX="198.61" CenterY="199.66"/><RotateTransform x:Name="GiroAbajo" CenterX="198.61" CenterY="199.66"/></TransformGroup></Canvas.RenderTransform>
        <Path Style="{StaticResource Tinta}" Data="M105.29,276.93c11.78,12.68,26.19,23.3,42.91,30.95,16.72,7.65,34.18,11.62,51.47,12.25"/>
        <Path Style="{StaticResource Cian}" Data="M105.29,276.93c11.78,12.68,26.19,23.3,42.91,30.95,16.72,7.65,34.18,11.62,51.47,12.25"/>
      </Canvas>
      <Canvas>
        <Canvas.RenderTransform><TransformGroup><RotateTransform x:Name="GiroDer" CenterX="198.61" CenterY="199.66"/></TransformGroup></Canvas.RenderTransform>
        <Path Style="{StaticResource Tinta}" Data="M275.21,292.99c12.68-11.78,23.3-26.19,30.95-42.91s11.62-34.18,12.25-51.47"/>
        <Path Style="{StaticResource Cian}" Data="M275.21,292.99c12.68-11.78,23.3-26.19,30.95-42.91s11.62-34.18,12.25-51.47"/>
      </Canvas>
      <Canvas>
        <Canvas.RenderTransform><TransformGroup><RotateTransform x:Name="GiroIzq" CenterX="198.61" CenterY="199.66"/></TransformGroup></Canvas.RenderTransform>
        <Path Style="{StaticResource Tinta}" Data="M121.34,107.01c-12.68,11.78-23.3,26.19-30.95,42.91-7.65,16.72-11.62,34.18-12.25,51.47"/>
        <Path Style="{StaticResource Cian}" Data="M121.34,107.01c-12.68,11.78-23.3,26.19-30.95,42.91-7.65,16.72-11.62,34.18-12.25,51.47"/>
      </Canvas>
    </Canvas>
    <Canvas>
      <Canvas.RenderTransform><TransformGroup>
        <ScaleTransform x:Name="EscOjo" CenterX="198.61" CenterY="199.66"/><TranslateTransform x:Name="MiraOjo"/>
      </TransformGroup></Canvas.RenderTransform>
      <Path Style="{StaticResource Tinta}"><Path.Data><EllipseGeometry Center="198.61,199.66" RadiusX="43.08" RadiusY="43.08"/></Path.Data></Path>
      <Path Style="{StaticResource Cian}"><Path.Data><EllipseGeometry Center="198.61,199.66" RadiusX="43.08" RadiusY="43.08"/></Path.Data></Path>
    </Canvas>
  </Canvas>
</Canvas>
'@

# Creo un NoNo nuevo y devuelvo su dibujo junto con sus piezas moviles:
#   Aplasta/Ladeo/Salto  el cuerpo entero (encogerse, ladear la cabeza, saltar)
#   GiroAros             los cuatro arcos girando juntos
#   Esc*/Giro*           cada pestana por separado (subir, bajar, caer)
#   EscOjo/MiraOjo       la forma del ojo y hacia donde mira
function New-NoNo {
    $lienzo = [Windows.Markup.XamlReader]::Parse($script:XAML_NONO)
    $n = @{ Dibujo = $lienzo }
    foreach ($nombre in 'Aplasta', 'Ladeo', 'Salto', 'GiroAros', 'EscArriba', 'GiroArriba', 'EscAbajo', 'GiroAbajo', 'GiroDer', 'GiroIzq', 'EscOjo', 'MiraOjo') {
        $n[$nombre] = $lienzo.FindName($nombre)
    }
    return $n
}

# La ventana del globo. Fondo tinta, borde cian y una sombra dura magenta
# corrida 6 px, como una ficha pixel. Los botones llevan plantilla plana.
$script:XAML_GLOBO = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="NoNo" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" ShowInTaskbar="False" ShowActivated="False" ResizeMode="NoResize"
        SizeToContent="Height" Width="356" FontFamily="IBM Plex Mono, Consolas, Courier New"
        UseLayoutRounding="True" SnapsToDevicePixels="True">
  <Window.Resources>
    <Style TargetType="Button">
      <Setter Property="Foreground" Value="#36E2C4"/>
      <Setter Property="Background" Value="#070A0E"/>
      <Setter Property="FontFamily" Value="Silkscreen, IBM Plex Mono, Consolas"/>
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Caja" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding Foreground}"
                    BorderThickness="2" Padding="8,4">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Caja" Property="Background" Value="#12312C"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <Grid Margin="0,0,6,6">
    <Border Background="#FF4FB0" Margin="6,6,-6,-6"/>
    <Border Background="#070A0E" BorderBrush="#36E2C4" BorderThickness="2">
      <StackPanel Margin="10,8,10,10">
        <DockPanel x:Name="Cabeza" Background="#070A0E" LastChildFill="True">
          <Button x:Name="Cerrar" DockPanel.Dock="Right" Content="X" Foreground="#FF4FB0" ToolTip="Cerrar a NoNo"/>
          <TextBlock x:Name="Paso" DockPanel.Dock="Right" Foreground="#FFB23E" FontWeight="Bold" FontSize="12"
                     FontFamily="Silkscreen, IBM Plex Mono, Consolas" VerticalAlignment="Center" Margin="0,0,10,0"/>
          <Viewbox x:Name="Mini" DockPanel.Dock="Left" Width="30" Height="30" Cursor="Hand" ToolTip="Clic: escribirle a NoNo"/>
          <TextBlock DockPanel.Dock="Left" Text="NONO" Foreground="#36E2C4" FontWeight="Bold" FontSize="14"
                     FontFamily="Silkscreen, IBM Plex Mono, Consolas" VerticalAlignment="Center" Margin="8,0,0,0"/>
          <TextBlock x:Name="Animo" Foreground="#9FB3B0" FontSize="11" VerticalAlignment="Center" Margin="10,0,0,0"/>
        </DockPanel>
        <TextBlock x:Name="Que" TextWrapping="Wrap" Foreground="#EAF6F4" FontSize="14" FontWeight="Bold" Margin="0,8,0,0"/>
        <TextBlock x:Name="PorqueBloque" TextWrapping="Wrap" Foreground="#9FB3B0" FontSize="12" Margin="0,6,0,0">
          <Run x:Name="PorqueRotulo" Foreground="#FF4FB0" FontWeight="Bold" Text="POR QU&#201;  "/><Run x:Name="Porque"/>
        </TextBlock>
        <Border x:Name="GloboCaja" BorderBrush="#FFB23E" BorderThickness="2" Padding="6" Margin="0,8,0,0" Visibility="Collapsed">
          <TextBlock x:Name="Globo" TextWrapping="Wrap" Foreground="#FFB23E" FontSize="12"/>
        </Border>
        <StackPanel x:Name="Escribir" Visibility="Collapsed">
        <TextBox x:Name="Entrada" Background="#0D131A" Foreground="#EAF6F4" BorderBrush="#36E2C4" BorderThickness="2"
                 CaretBrush="#36E2C4" SelectionBrush="#FF4FB0" Margin="0,8,0,0" Padding="4,3" FontSize="12"
                 FontFamily="IBM Plex Mono, Consolas"/>
        <TextBlock Text="Escr&#237;beme aqu&#237;: Enter se lo env&#237;a a Claude  |  Win+H dicta" Foreground="#5E7572" FontSize="10" Margin="0,3,0,0"/>
        </StackPanel>
        <StackPanel x:Name="Botones" Orientation="Horizontal" Margin="0,8,0,0">
          <Button x:Name="Listo" Content="LISTO &gt;" Margin="0,0,8,0"/>
          <Button x:Name="NoVeo" Content="NO LO VEO" Foreground="#FFB23E"/>
        </StackPanel>
      </StackPanel>
    </Border>
  </Grid>
</Window>
'@

# La ventana de NoNo: transparente, sin borde, y despues la vuelvo "atravesable"
# solo cuando senala (para no tapar el boton que hay debajo); cuando descansa
# se le puede hacer clic para desplegar el cuadro de texto. NoNo es mascota y
# puntero a la vez: su centro (el ancla, 120,120) es el punto que senala, y el
# aro deja ver a traves lo que hay debajo. Tres transformaciones separadas para
# que no se pisen: Talla (grande de mascota, chico de mira), Respira (el latido
# sobre el punto), Aterriza e Inclina (el vuelo) y Flote (el vaiven cuando descansa).
$script:XAML_PUNTERO = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="NoNo senalador" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" ShowInTaskbar="False" ShowActivated="False" ResizeMode="NoResize"
        Width="240" Height="240" Focusable="False">
  <Canvas>
    <Ellipse Width="96" Height="96" Canvas.Left="72" Canvas.Top="72" Fill="#01000000" Cursor="Hand"/>
    <Viewbox x:Name="Cuerpo" Width="72" Height="72" Canvas.Left="84" Canvas.Top="84" RenderTransformOrigin="0.5,0.5">
      <Viewbox.RenderTransform>
        <TransformGroup>
          <ScaleTransform x:Name="Talla" ScaleX="1.2" ScaleY="1.2"/>
          <ScaleTransform x:Name="Respira"/>
          <ScaleTransform x:Name="Aterriza"/>
          <RotateTransform x:Name="Inclina"/>
          <TranslateTransform x:Name="Flote"/>
        </TransformGroup>
      </Viewbox.RenderTransform>
    </Viewbox>
  </Canvas>
</Window>
'@
