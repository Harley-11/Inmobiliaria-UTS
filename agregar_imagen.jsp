<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%--
 agente/agregar_imagen.jsp - Agrega una imagen a la galeria de una
 propiedad propia (POST). Verifica propiedad y unicidad de matricula no
 aplica; solo controla que la URL no este vacia.
--%>
<%
  String[] rolesPermitidos = { "inmobiliaria" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  request.setCharacterEncoding("UTF-8");
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  int idProp = aEntero(request.getParameter("id"), 0);
  String url = request.getParameter("url");
  int orden = aEntero(request.getParameter("orden"), 1);
  if (orden < 1) orden = 1;

  Connection con = null;
  PreparedStatement ps = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);
    int idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);
    if (idProp <= 0 || idInmobiliaria <= 0 || url == null || url.trim().isEmpty()
        || !esPropiedadDeInmobiliaria(con, idProp, idInmobiliaria)) {
      response.sendRedirect(ctx + "/agente/galeria.jsp?id=" + idProp + "&err=3");
      return;
    }
    ps = con.prepareStatement(
        "INSERT INTO imagen_propiedad (id_propiedad, url_imagen, orden) VALUES (?, ?, ?)");
    ps.setInt(1, idProp);
    ps.setString(2, url.trim());
    ps.setInt(3, orden);
    ps.executeUpdate();
    cerrar(ps);
    con.commit();
    registrarAuditoria(con, idUsuario, "IMAGEN", "Imagen agregada a propiedad id=" + idProp);
    con.commit();
    response.sendRedirect(ctx + "/agente/galeria.jsp?id=" + idProp + "&ok=3");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(ctx + "/agente/galeria.jsp?id=" + idProp + "&err=2");
  } finally {
    cerrar(ps, con);
  }
%>