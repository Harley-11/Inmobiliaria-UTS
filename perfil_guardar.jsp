<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 cliente/perfil_guardar.jsp - Guarda (crea o actualiza) el perfil 1:1 del
 cliente conectado. Usa INSERT ... ON DUPLICATE KEY UPDATE sobre la clave
 unica id_usuario de la tabla perfil.
--%>
<%
  String[] rolesPermitidos = { "cliente" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  request.setCharacterEncoding("UTF-8");
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  String nombres = request.getParameter("nombres");
  String apellidos = request.getParameter("apellidos");
  String documento = request.getParameter("documento");
  String telefono = request.getParameter("telefono");
  String direccion = request.getParameter("direccion");
  String foto = request.getParameter("foto");

  if (nombres == null || nombres.trim().isEmpty()
   || apellidos == null || apellidos.trim().isEmpty()
   || documento == null || documento.trim().isEmpty()) {
    response.sendRedirect(ctx + "/cliente/perfil.jsp?err=datos");
    return;
  }

  Connection con = null;
  PreparedStatement ps = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);
    ps = con.prepareStatement(
        "INSERT INTO perfil (id_usuario, nombres, apellidos, documento, telefono, direccion, foto) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?) " +
        "ON DUPLICATE KEY UPDATE nombres = VALUES(nombres), apellidos = VALUES(apellidos), " +
        "documento = VALUES(documento), telefono = VALUES(telefono), " +
        "direccion = VALUES(direccion), foto = VALUES(foto)");
    ps.setInt(1, idUsuario);
    ps.setString(2, nombres.trim());
    ps.setString(3, apellidos.trim());
    ps.setString(4, documento.trim());
    ps.setString(5, (telefono == null || telefono.trim().isEmpty()) ? null : telefono.trim());
    ps.setString(6, (direccion == null || direccion.trim().isEmpty()) ? null : direccion.trim());
    ps.setString(7, (foto == null || foto.trim().isEmpty()) ? null : foto.trim());
    ps.executeUpdate();
    cerrar(ps);
    con.commit();
    registrarAuditoria(con, idUsuario, "PERFIL", "Perfil de cliente actualizado");
    con.commit();
    response.sendRedirect(ctx + "/cliente/perfil.jsp?ok=1");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(ctx + "/cliente/perfil.jsp?err=servidor");
  } finally {
    cerrar(ps, con);
  }
%>