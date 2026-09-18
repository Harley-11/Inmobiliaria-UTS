<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 cliente/favorito_toggle.jsp - Agrega o quita una propiedad de los favoritos
 del cliente conectado (PK de favorito: id_usuario + id_propiedad).
 Acepta GET (desde la ficha publica) o POST (desde el panel). Redirige
 segun el origen.
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
  String origen = request.getParameter("origen");

  Connection con = null;
  PreparedStatement ps = null;
  String destino = (origen != null && "favoritos".equals(origen))
      ? ctx + "/cliente/favoritos.jsp" : ctx + "/propiedad.jsp?id=" + idProp;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);
    if (idProp <= 0) {
      response.sendRedirect(ctx + "/propiedades.jsp");
      return;
    }

    ps = con.prepareStatement("INSERT IGNORE INTO favorito (id_usuario, id_propiedad) VALUES (?, ?)");
    ps.setInt(1, idUsuario);
    ps.setInt(2, idProp);
    int insertadas = ps.executeUpdate();
    cerrar(ps);

    if (insertadas == 0) {
      ps = con.prepareStatement("DELETE FROM favorito WHERE id_usuario = ? AND id_propiedad = ?");
      ps.setInt(1, idUsuario);
      ps.setInt(2, idProp);
      ps.executeUpdate();
      cerrar(ps);
      con.commit();
      registrarAuditoria(con, idUsuario, "FAVORITO", "Quitado favorito propiedad id=" + idProp);
      con.commit();
      if ("favoritos".equals(origen)) { response.sendRedirect(destino + "?ok=2"); return; }
    } else {
      con.commit();
      registrarAuditoria(con, idUsuario, "FAVORITO", "Agregado favorito propiedad id=" + idProp);
      con.commit();
      if ("favoritos".equals(origen)) { response.sendRedirect(destino + "?ok=1"); return; }
    }
    response.sendRedirect(destino);
  } catch (Exception e) {
    e.printStackTrace();
    if ("favoritos".equals(origen)) { response.sendRedirect(destino + "?err=2"); return; }
    response.sendRedirect(ctx + "/propiedades.jsp");
  } finally {
    cerrar(ps, con);
  }
%>