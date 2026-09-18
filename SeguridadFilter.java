package filtros;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * SeguridadFilter - Control de acceso obligatorio por rol.
 *
 * Se registra en web.xml sobre las rutas privadas:
 *   /admin/*   -> solo rol "administrador"
 *   /agente/*  -> solo rol "inmobiliaria"
 *   /cliente/* -> solo rol "cliente"
 *
 * Comportamiento en doFilter():
 *  - Sin sesion activa (o sesion vencida): redirige a
 *      acceso-denegado.jsp?motivo=sesion
 *  - Sesion activa pero sin el rol requerido: redirige a
 *      acceso-denegado.jsp?motivo=rol&rol=...
 *  - Rol correcto: deja continuar la cadena (chain.doFilter).
 *
 * La sesion guarda:
 *  idUsuario (Integer), nombre (String), correo (String),
 *  rol (String, rol principal) y roles (String CSV con todos los roles).
 */
public class SeguridadFilter implements Filter {

  public void init(FilterConfig config) throws ServletException {
    // No requiere inicializacion especial.
  }

  public void doFilter(ServletRequest request, ServletResponse response,
                       FilterChain chain) throws IOException, ServletException {

    HttpServletRequest req = (HttpServletRequest) request;
    HttpServletResponse resp = (HttpServletResponse) response;
    HttpSession sesion = req.getSession(false);
    String ctx = req.getContextPath();

    String uri = req.getRequestURI();
    if (uri.startsWith(ctx)) {
      uri = uri.substring(ctx.length());
    }

    String rolRequerido = rolDeRuta(uri);
    if (rolRequerido == null) {
      chain.doFilter(request, response);
      return;
    }

    if (sesion == null || sesion.getAttribute("idUsuario") == null) {
      resp.sendRedirect(ctx + "/acceso-denegado.jsp?motivo=sesion");
      return;
    }

    String rolesCsv = (String) sesion.getAttribute("roles");
    String rolUnico = (String) sesion.getAttribute("rol");
    boolean tieneAcceso = tieneRol(rolesCsv, rolRequerido)
                          || (rolUnico != null && rolUnico.equalsIgnoreCase(rolRequerido));

    if (!tieneAcceso) {
      resp.sendRedirect(ctx + "/acceso-denegado.jsp?motivo=rol&rol=" + rolRequerido);
      return;
    }

    chain.doFilter(request, response);
  }

  /**
   * Devuelve el rol exigido segun el prefijo de la ruta, o null si la
   * ruta no esta protegida por este filtro.
   */
  private String rolDeRuta(String uri) {
    if (uri.startsWith("/admin/"))   return "administrador";
    if (uri.startsWith("/agente/"))  return "inmobiliaria";
    if (uri.startsWith("/cliente/")) return "cliente";
    return null;
  }

  /** Valida si el String CSV de roles contiene el rol buscado. */
  private boolean tieneRol(String rolesCsv, String rolBuscado) {
    if (rolesCsv == null) return false;
    for (String r : rolesCsv.split(",")) {
      if (r.trim().equalsIgnoreCase(rolBuscado)) {
        return true;
      }
    }
    return false;
  }

  public void destroy() {
    // Sin recursos que liberar.
  }
}