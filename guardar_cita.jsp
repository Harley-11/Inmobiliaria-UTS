<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 cliente/guardar_cita.jsp - Registra la cita (visita) del cliente conectado
 sobre una propiedad disponible. FK id_cliente = sesion. La tabla cita tiene
 UNIQUE (id_propiedad, fecha_hora) -> error duplicada.
--%>
<%
  String[] rolesPermitidos = { "cliente" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  int idProp = aEntero(request.getParameter("propiedad"), 0);
  String fechaHoraRaw = request.getParameter("fecha_hora");

  String fechaHora = null;
  if (fechaHoraRaw != null && fechaHoraRaw.trim().length() >= 16) {
    fechaHora = fechaHoraRaw.trim().replace("T", " ") + ":00";
  }

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);

    ps = con.prepareStatement(
        "SELECT 1 FROM propiedad WHERE id_propiedad = ? AND estado = 'disponible'");
    ps.setInt(1, idProp);
    rs = ps.executeQuery();
    boolean propValida = rs.next();
    cerrar(rs, ps);

    if (!propValida || fechaHora == null) {
      response.sendRedirect(ctx + "/cliente/solicitar_visita.jsp?propiedad=" + idProp + "&err=fecha");
      return;
    }

    ps = con.prepareStatement(
        "INSERT INTO cita (id_propiedad, id_cliente, fecha_hora, estado) VALUES (?, ?, ?, 'pendiente')");
    ps.setInt(1, idProp);
    ps.setInt(2, idUsuario);
    ps.setString(3, fechaHora);
    ps.executeUpdate();
    cerrar(ps);
    con.commit();
    registrarAuditoria(con, idUsuario, "CITA",
        "Visita agendada a propiedad id=" + idProp + " el " + fechaHora);
    con.commit();
    response.sendRedirect(ctx + "/cliente/mis_citas.jsp?ok=1");
  } catch (java.sql.SQLIntegrityConstraintViolationException e) {
    response.sendRedirect(ctx + "/cliente/solicitar_visita.jsp?propiedad=" + idProp + "&err=duplicada");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(ctx + "/cliente/solicitar_visita.jsp?propiedad=" + idProp + "&err=servidor");
  } finally {
    cerrar(rs, ps, con);
  }
%>