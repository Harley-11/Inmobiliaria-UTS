<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 agente/propiedad_estado.jsp - Cambia el estado de una propiedad propia:
 'inactivo' (dar de baja logica, desaparece del listado publico) o
 'disponible' (reactivar). Solo sobre propiedades de la inmobiliaria del
 agente conectado. Procesa POST.
--%>
<%
  String[] rolesPermitidos = { "inmobiliaria" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  int idProp = aEntero(request.getParameter("id"), 0);
  String accion = request.getParameter("accion");
  if (!"inactivar".equals(accion) && !"reactivar".equals(accion)) {
    accion = null;
  }

  Connection con = null;
  PreparedStatement ps = null;
  try {
    if (idProp > 0 && accion != null) {
      con = abrirConexion();
      con.setAutoCommit(false);
      int idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);
      if (idInmobiliaria <= 0 || !esPropiedadDeInmobiliaria(con, idProp, idInmobiliaria)) {
        response.sendRedirect(ctx + "/agente/propiedades.jsp?err=1");
        return;
      }
      String nuevoEstado = "inactivar".equals(accion) ? "inactivo" : "disponible";
      ps = con.prepareStatement("UPDATE propiedad SET estado = ? WHERE id_propiedad = ?");
      ps.setString(1, nuevoEstado);
      ps.setInt(2, idProp);
      ps.executeUpdate();
      cerrar(ps);
      con.commit();
      registrarAuditoria(con, idUsuario, "PROPIEDAD",
          "Propiedad id=" + idProp + " estado -> " + nuevoEstado);
      con.commit();
      response.sendRedirect(ctx + "/agente/propiedades.jsp?ok=2");
      return;
    }
    response.sendRedirect(ctx + "/agente/propiedades.jsp");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(ctx + "/agente/propiedades.jsp?err=2");
  } finally {
    cerrar(ps, con);
  }
%>