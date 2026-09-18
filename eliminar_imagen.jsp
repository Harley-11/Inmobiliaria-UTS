<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 agente/eliminar_imagen.jsp - Elimina una imagen de la galeria de una
 propiedad propia (POST). Verifica que la imagen pertenezca a la propiedad
 y que la propiedad pertenezca a la inmobiliaria del agente.
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
  int idImagen = aEntero(request.getParameter("imagen"), 0);

  Connection con = null;
  PreparedStatement ps = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);
    int idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);
    if (idProp <= 0 || idImagen <= 0 || idInmobiliaria <= 0
        || !esPropiedadDeInmobiliaria(con, idProp, idInmobiliaria)) {
      response.sendRedirect(ctx + "/agente/galeria.jsp?id=" + idProp + "&err=3");
      return;
    }
    ps = con.prepareStatement(
        "DELETE FROM imagen_propiedad WHERE id_imagen = ? AND id_propiedad = ?");
    ps.setInt(1, idImagen);
    ps.setInt(2, idProp);
    ps.executeUpdate();
    cerrar(ps);
    con.commit();
    registrarAuditoria(con, idUsuario, "IMAGEN", "Imagen eliminada de propiedad id=" + idProp);
    con.commit();
    response.sendRedirect(ctx + "/agente/galeria.jsp?id=" + idProp + "&ok=3");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(ctx + "/agente/galeria.jsp?id=" + idProp + "&err=2");
  } finally {
    cerrar(ps, con);
  }
%>