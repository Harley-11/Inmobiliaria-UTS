<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 agente/solicitud_estado.jsp - Aprueba o rechaza una solicitud (POST) siempre
 que la solicitud pertenezca a una propiedad de la inmobiliaria del agente
 conectado y siga en estado 'pendiente'. Ejecuta actualizacion logica del
 campo estado ('aprobada' / 'rechazada').
 AL APROBAR una solicitud, la propiedad deja de estar disponible en la MISMA
 transaccion:
   - tipo 'compra'   -> propiedad.estado = 'vendida'
   - tipo 'arriendo' -> propiedad.estado = 'arrendada'
 Asi una propiedad vendida/arrendada desaparece del catalogo publico y no se
 le pueden agendar citas ni radicar nuevas solicitudes (las acciones
 cliente/guardar_cita.jsp y cliente/guardar_solicitud.jsp exigen
 estado='disponible').
 AL RECHAZAR, la propiedad NO cambia de estado: se mantiene 'disponible'.
--%>
<%
  String[] rolesPermitidos = { "inmobiliaria" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  int idSolicitud = aEntero(request.getParameter("id_solicitud"), 0);
  String accion = request.getParameter("accion");

  String nuevoEstado = "aprobar".equals(accion) ? "aprobada"
                     : "rechazar".equals(accion) ? "rechazada" : null;

  if (idSolicitud <= 0 || nuevoEstado == null) {
    response.sendRedirect(ctx + "/agente/solicitudes.jsp?err=2");
    return;
  }

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);
    int idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);

    ps = con.prepareStatement(
        "SELECT s.estado, s.tipo, s.id_propiedad FROM solicitud s " +
        "JOIN propiedad p ON p.id_propiedad = s.id_propiedad AND p.id_inmobiliaria = ? " +
        "WHERE s.id_solicitud = ?");
    ps.setInt(1, idInmobiliaria);
    ps.setInt(2, idSolicitud);
    rs = ps.executeQuery();
    boolean existe = rs.next();
    String estadoActual = existe ? rs.getString(1) : null;
    String tipoSolicitud = existe ? rs.getString(2) : null;
    int idPropiedad = existe ? rs.getInt(3) : 0;
    cerrar(rs, ps);

    if (idInmobiliaria <= 0 || !existe || !"pendiente".equals(estadoActual)) {
      response.sendRedirect(ctx + "/agente/solicitudes.jsp?err=1");
      return;
    }

    ps = con.prepareStatement("UPDATE solicitud SET estado = ? WHERE id_solicitud = ?");
    ps.setString(1, nuevoEstado);
    ps.setInt(2, idSolicitud);
    ps.executeUpdate();
    cerrar(ps);

    // Al aprobar, la propiedad deja de estar disponible en la misma
    // transaccion (compra -> vendida, arriendo -> arrendada).
    String estadoPropiedad = null;
    if ("aprobada".equals(nuevoEstado)) {
      estadoPropiedad = "compra".equals(tipoSolicitud) ? "vendida" : "arrendada";
      ps = con.prepareStatement("UPDATE propiedad SET estado = ? WHERE id_propiedad = ?");
      ps.setString(1, estadoPropiedad);
      ps.setInt(2, idPropiedad);
      ps.executeUpdate();
      cerrar(ps);
    }

    con.commit();
    registrarAuditoria(con, idUsuario, nuevoEstado.equals("aprobada") ? "APROBAR_SOLIC" : "RECHAZAR_SOLIC",
        nuevoEstado.equals("aprobada")
            ? "Aprobo solicitud id=" + idSolicitud + "; propiedad id=" + idPropiedad
              + " paso a estado '" + estadoPropiedad + "'"
            : "Rechazo solicitud id=" + idSolicitud + "; propiedad id=" + idPropiedad
              + " sigue disponible");
    con.commit();
    response.sendRedirect(ctx + "/agente/solicitudes.jsp?ok=" + ("aprobada".equals(nuevoEstado) ? "1" : "2"));
  } catch (Exception e) {
    if (con != null) { try { con.rollback(); } catch (Exception ignorada) { } }
    e.printStackTrace();
    response.sendRedirect(ctx + "/agente/solicitudes.jsp?err=2");
  } finally {
    cerrar(rs, ps, con);
  }
%>