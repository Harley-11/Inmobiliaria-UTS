<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 admin/usuario_rol.jsp - Asigna o revoca roles (tabla usuario_rol) de una
 cuenta. Procesa POST desde admin/usuarios.jsp. Estrategia de "sincronizacion":
 se borran los roles actuales del usuario y se insertan los que vienen
 marcados (rol_<id_rol>). Esto cubre asignar y revocar en una sola accion.
   - Valida que el usuario exista.
   - Si entre los roles finales queda 'inmobiliaria' y el usuario NO tiene
     registro en la tabla inmobiliaria, se crea la fila (nombre_comercial y
     NIT que el administrador diligencio en admin/usuarios.jsp) en la MISMA
     transaccion. El NIT debe ser unico (uq_inmobiliaria_nit).
   - Si el rol 'inmobiliaria' se REVOCA, la fila de inmobiliaria NO se borra
     jamas: conserva sus propiedades publicadas (FK propiedad -> inmobiliaria)
     y queda simplemente sin rol, lista para volver a asignarse. Esta es la
     politica anti-perdida de datos.
   - Un administrador NO puede quitarse a si mismo el rol 'administrador'
     (evita que la plataforma quede sin administradores).
   - La operacion es transaccional (crear inmobiliaria + DELETE + INSERTs)
     y queda en auditoria (GESTIONAR_ROL y CREAR_INMOBILIARIA).
   - No emite HTML: solo redirige.
--%>
<%
  String[] rolesPermitidos = { "administrador" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  request.setCharacterEncoding("UTF-8");
  int idUsuarioSesion = ((Integer) session.getAttribute("idUsuario")).intValue();
  int idUsuario = aEntero(request.getParameter("id_usuario"), 0);

  if (idUsuario <= 0) {
    response.sendRedirect(ctx + "/admin/usuarios.jsp?err=1");
    return;
  }

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);

    ps = con.prepareStatement("SELECT correo, estado FROM usuario WHERE id_usuario = ?");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    if (!rs.next()) {
      response.sendRedirect(ctx + "/admin/usuarios.jsp?err=1");
      return;
    }
    String correoObjetivo = rs.getString(1);
    cerrar(rs, ps);

    // Roles disponibles en el sistema (id y nombre).
    List<Object[]> rolesSistema = new ArrayList<Object[]>();
    ps = con.prepareStatement("SELECT id_rol, nombre_rol FROM rol");
    rs = ps.executeQuery();
    while (rs.next()) rolesSistema.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    cerrar(rs, ps);

    // Roles marcados en el formulario.
    List<Object[]> seleccionados = new ArrayList<Object[]>();
    boolean quedaAdministrador = false;
    boolean asignaInmobiliaria = false;
    for (Object[] rol : rolesSistema) {
      Integer idRol = (Integer) rol[0];
      if (request.getParameter("rol_" + idRol.intValue()) != null) {
        seleccionados.add(rol);
        if ("administrador".equalsIgnoreCase((String) rol[1])) quedaAdministrador = true;
        if ("inmobiliaria".equalsIgnoreCase((String) rol[1])) asignaInmobiliaria = true;
      }
    }

    // Proteccion: el administrador en sesion no puede quitarse su propio rol.
    if (idUsuario == idUsuarioSesion
        && !quedaAdministrador
        && yaTieneRolAdmin(con, idUsuarioSesion)) {
      response.sendRedirect(ctx + "/admin/usuarios.jsp?err=3");
      return;
    }

    // Si se asigna el rol 'inmobiliaria' y el usuario no tiene registro en
    // la tabla inmobiliaria, crearlo aqui (misma transaccion).
    String nombreComercial = null;
    String nit = null;
    boolean inmobiliariaCreada = false;
    if (asignaInmobiliaria) {
      boolean yaTieneInmobiliaria = false;
      ps = con.prepareStatement(
          "SELECT id_inmobiliaria FROM inmobiliaria WHERE id_usuario = ?");
      ps.setInt(1, idUsuario);
      rs = ps.executeQuery();
      yaTieneInmobiliaria = rs.next();
      cerrar(rs, ps);

      if (!yaTieneInmobiliaria) {
        String nc = request.getParameter("nombre_comercial");
        nombreComercial = (nc == null) ? "" : nc.trim();
        String n = request.getParameter("nit");
        nit = (n == null) ? null : n.trim();
        if (nit != null && nit.isEmpty()) nit = null;

        if (nombreComercial.isEmpty()) {
          if (con != null) { try { con.rollback(); } catch (Exception ignorada) { } }
          response.sendRedirect(ctx + "/admin/usuarios.jsp?err=5");
          return;
        }
        if (nombreComercial.length() > 100) nombreComercial = nombreComercial.substring(0, 100);
        if (nit != null && nit.length() > 20) nit = nit.substring(0, 20);

        // El NIT es unico (uq_inmobiliaria_nit): avisar antes del INSERT.
        if (nit != null) {
          ps = con.prepareStatement(
              "SELECT id_inmobiliaria FROM inmobiliaria WHERE nit = ?");
          ps.setString(1, nit);
          rs = ps.executeQuery();
          boolean nitDuplicado = rs.next();
          cerrar(rs, ps);
          if (nitDuplicado) {
            if (con != null) { try { con.rollback(); } catch (Exception ignorada) { } }
            response.sendRedirect(ctx + "/admin/usuarios.jsp?err=6");
            return;
          }
        }

        ps = con.prepareStatement(
            "INSERT INTO inmobiliaria (id_usuario, nombre_comercial, nit) VALUES (?, ?, ?)");
        ps.setInt(1, idUsuario);
        ps.setString(2, nombreComercial);
        ps.setString(3, nit);
        ps.executeUpdate();
        cerrar(ps);
        inmobiliariaCreada = true;
      }
    }

    // Sincronizacion de roles: siempre se borran y se reinsertan los marcados.
    ps = con.prepareStatement("DELETE FROM usuario_rol WHERE id_usuario = ?");
    ps.setInt(1, idUsuario);
    ps.executeUpdate();
    cerrar(ps);

    StringBuilder detalleRoles = new StringBuilder();
    for (Object[] rol : seleccionados) {
      ps = con.prepareStatement(
          "INSERT INTO usuario_rol (id_usuario, id_rol) VALUES (?, ?)");
      ps.setInt(1, idUsuario);
      ps.setInt(2, ((Integer) rol[0]).intValue());
      ps.executeUpdate();
      cerrar(ps);
      detalleRoles.append(rol[1]).append(",");
    }

    if (inmobiliariaCreada) {
      registrarAuditoria(con, idUsuarioSesion, "CREAR_INMOBILIARIA",
          "Inmobiliaria creada para el usuario " + idUsuario + " ("
          + correoObjetivo + "): " + nombreComercial
          + (nit != null ? " NIT " + nit : ""));
    }

    con.commit();
    registrarAuditoria(con, idUsuarioSesion, "GESTIONAR_ROL",
        "Roles del usuario " + idUsuario + " (" + correoObjetivo + ") quedaron en: "
        + detalleRoles.toString());
    con.commit();
    response.sendRedirect(ctx + "/admin/usuarios.jsp?"
        + (inmobiliariaCreada ? "ok=4" : "ok=1"));
  } catch (Exception e) {
    if (con != null) { try { con.rollback(); } catch (Exception ignorada) { } }
    e.printStackTrace();
    response.sendRedirect(ctx + "/admin/usuarios.jsp?err=2");
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%!
  public boolean yaTieneRolAdmin(Connection con, int idUsuario) {
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
      ps = con.prepareStatement(
          "SELECT 1 FROM usuario_rol ur JOIN rol r ON r.id_rol = ur.id_rol " +
          "WHERE ur.id_usuario = ? AND r.nombre_rol = 'administrador'");
      ps.setInt(1, idUsuario);
      rs = ps.executeQuery();
      return rs.next();
    } catch (Exception ignorada) {
      return true;
    } finally {
      cerrar(rs, ps);
    }
  }
%>