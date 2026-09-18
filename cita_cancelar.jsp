<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 cliente/cita_cancelar.jsp - Cancela una cita propia en estado pendiente.
 Verifica dueño de la cita (id_cliente = sesion). Procesa POST.
--%>
<%
  String[] rolesPermitidos = { "cliente" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  int idCita = aEntero(request.getParameter("id"), 0);

  Connection con = null;
  PreparedStatement ps = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);
    ps = con.prepareStatement(
        "UPDATE cita SET estado = 'cancelada' WHERE id_cita = ? AND id_cliente = ? AND estado = 'pendiente'");
    ps.setInt(1, idCita);
    ps.setInt(2, idUsuario);
    int filas = ps.executeUpdate();
    cerrar(ps);
    con.commit();
    if (filas > 0) {
      registrarAuditoria(con, idUsuario, "CITA", "Cita cancelada id=" + idCita);
      con.commit();
      response.sendRedirect(ctx + "/cliente/mis_citas.jsp?err=1");
      return;
    }
    response.sendRedirect(ctx + "/cliente/mis_citas.jsp");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(ctx + "/cliente/mis_citas.jsp?err=2");
  } finally {
    cerrar(ps, con);
  }
%>