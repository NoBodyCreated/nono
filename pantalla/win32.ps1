# NoNo - el puente con Windows (user32) para mover ventanas en pixeles fisicos.
# Autoria intelectual: Felipe Restrepo Velez; asistido por Claude.
#
# Tengo dos monitores con escalas distintas (125 % y 100 %). Si dejo que WPF
# ubique las ventanas, convierte con una sola escala y el senalador cae corrido
# en el otro monitor. Por eso declaro el proceso "consciente por monitor" y muevo
# las ventanas con SetWindowPos, que ahi si recibe pixeles fisicos reales: los
# mismos que da una captura de pantalla.
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace NoNo {
  public static class Win {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] public struct MONITORINFO {
      public int cb; public RECT rcMonitor; public RECT rcWork; public int flags;
    }
    [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr v);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
    [DllImport("user32.dll")] static extern int SetWindowLong(IntPtr h, int i, int v);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr tras, int x, int y, int cx, int cy, uint f);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromPoint(POINT p, uint f);
    [DllImport("user32.dll")] static extern bool GetMonitorInfo(IntPtr m, ref MONITORINFO i);
    [DllImport("user32.dll")] static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] static extern void mouse_event(uint f, uint dx, uint dy, int dato, UIntPtr extra);

    // Devuelve "monitor" si quedo consciente por monitor, o "sistema" si solo pude lo basico.
    public static string Escala() {
      try { if (SetProcessDpiAwarenessContext(new IntPtr(-4))) return "monitor"; } catch { }
      SetProcessDPIAware();
      return "sistema";
    }
    // Suma estilos extendidos a una ventana (atravesable, fuera de Alt+Tab, sin foco).
    public static void Estilo(IntPtr h, int extra) { SetWindowLong(h, -20, GetWindowLong(h, -20) | extra); }
    public static void SinEstilo(IntPtr h, int extra) { SetWindowLong(h, -20, GetWindowLong(h, -20) & ~extra); }
    // Las manos de NoNo: un clic izquierdo, y la rueda (muescas positivas bajan la pagina).
    public static void Clic(int x, int y) { SetCursorPos(x, y); mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero); mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero); }
    public static void Rueda(int x, int y, int muescas) { SetCursorPos(x, y); mouse_event(0x0800, 0, 0, -120 * muescas, UIntPtr.Zero); }
    // Mueve sin cambiar tamano, orden ni foco.
    public static void Mover(IntPtr h, int x, int y) { SetWindowPos(h, IntPtr.Zero, x, y, 0, 0, 0x0001 | 0x0004 | 0x0010); }
    public static RECT Caja(IntPtr h) { RECT r; GetWindowRect(h, out r); return r; }
    // Area util (sin la barra de tareas) del monitor donde cae el punto.
    public static RECT Zona(int x, int y) {
      POINT p = new POINT(); p.X = x; p.Y = y;
      MONITORINFO i = new MONITORINFO(); i.cb = Marshal.SizeOf(typeof(MONITORINFO));
      GetMonitorInfo(MonitorFromPoint(p, 2), ref i);
      return i.rcWork;
    }
  }
}
'@
