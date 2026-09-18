<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 agente/guardar_caracteristicas.jsp - Guarda la relacion N:M de la
 propiedad con caracteristicas. Estrategia: borra las relaciones actuales
 de la propiedad e inserta las seleccionadas (con cantidad). Solo sobre
 propiedades de la inmobiliaria del agente. Procesa POST.
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

  Connection con = null;
  PreparedStatement ps = null;
  List<Integer> idsCaracteristicas = new ArrayList<Integer>();
  try {
    con = abrirConexion();
    con.setAutoCommit(false);
    int idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);
    if (idProp <= 0 || idInmobiliaria <= 0 || !esPropiedadDeInmobiliaria(con, idProp, idInmobiliaria)) {
      response.sendRedirect(ctx + "/agente/caracteristicas.jsp?id=" + idProp + "&err=3");
      return;
    }

    ps = con.prepareStatement("SELECT id_caracteristica FROM caracteristica");
    java.sql.ResultSet rs = null;
    try {
      rs = ps.executeQuery();
      while (rs.next()) idsCaracteristicas.add(Integer.valueOf(rs.getInt(1)));
    } finally {
      if (rs != null) rs.close();
    }
    cerrar(ps);

    ps = con.prepareStatement("DELETE FROM propiedad_caracteristica WHERE id_propiedad = ?");
    ps.setInt(1, idProp);
    ps.executeUpdate();
    cerrar(ps);

    int insertadas = 0;
    for (Integer idCar : idsCaracteristicas) {
      if (request.getParameter("car_" + idCar.intValue()) != null) {
        int cantidad = aEntero(request.getParameter("cant_" + idCar.intValue()), 1);
        if (cantidad < 1) cantidad = 1;
        ps = con.prepareStatement(
            "INSERT INTO propiedad_caracteristica (id_propiedad, id_caracteristica, cantidad) VALUES (?, ?, ?)");
        ps.setInt(1, idProp);
        ps.setInt(2, idCar.intValue());
        ps.setInt(3, cantidad);
        ps.executeUpdate();
        cerrar(ps);
        insertadas++;
      }
    }

    con.commit();
    registrarAuditoria(con, idUsuario, "CARACTERISTICA",
        idProp + " caracteristicas guardadas: " + insertadas);
    con.commit();
    response.sendRedirect(ctx + "/agente/caracteristicas.jsp?id=" + idProp + "&ok=4");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(ctx + "/agente/caracteristicas.jsp?id=" + idProp + "&err=2");
  } finally {
    cerrar(ps, con);
  }
%>