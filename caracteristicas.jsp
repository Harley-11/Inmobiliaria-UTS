<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 agente/caracteristicas.jsp - Gestiona las caracteristicas de una propiedad
 propia. La relacion N:M se guarda en propiedad_caracteristica. Muestra la
 lista de caracteristicas del sistema con checkbox y cantidad, preseleccion
 con los valores actuales. Envia POST a guardar_caracteristicas.jsp.
--%>
<%
  String[] rolesPermitidos = { "inmobiliaria" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  int idProp = aEntero(request.getParameter("id"), 0);
  String okMsj = request.getParameter("ok");
  String errMsj = request.getParameter("err");

  String tituloPropiedad = null;
  List<Object[]> caracteristicas = new ArrayList<Object[]>();

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    int idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);
    if (idProp <= 0 || idInmobiliaria <= 0 || !esPropiedadDeInmobiliaria(con, idProp, idInmobiliaria)) {
      response.sendRedirect(ctx + "/agente/propiedades.jsp?err=1");
      return;
    }
    ps = con.prepareStatement("SELECT titulo FROM propiedad WHERE id_propiedad = ?");
    ps.setInt(1, idProp);
    rs = ps.executeQuery();
    if (rs.next()) tituloPropiedad = rs.getString(1);
    cerrar(rs, ps);

    ps = con.prepareStatement(
        "SELECT c.id_caracteristica, c.nombre_caracteristica, " +
        "COALESCE(pc.cantidad, 0) AS cantidad " +
        "FROM caracteristica c " +
        "LEFT JOIN propiedad_caracteristica pc " +
        "  ON pc.id_caracteristica = c.id_caracteristica AND pc.id_propiedad = ? " +
        "ORDER BY c.id_caracteristica");
    ps.setInt(1, idProp);
    rs = ps.executeQuery();
    while (rs.next()) caracteristicas.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2), Integer.valueOf(rs.getInt(3))});
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudo cargar las caracteristicas.";
  } finally {
    cerrar(rs, ps, con);
  }

  String tituloPagina = "Caracteristicas de la propiedad";
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Caracteristicas</h1>
        <p class="text-muted mb-0"><%=esc(tituloPropiedad)%></p>
    </div>
    <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/agente/propiedades.jsp"><i class="bi bi-arrow-left me-1"></i> Volver</a>
</div>

<% if ("4".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Caracteristicas actualizadas.</div>
<% } %>
<% if (errMsj != null && !errMsj.trim().isEmpty()) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
<% } %>

<div class="card ims-card shadow-lg">
    <div class="card-body">
        <form action="<%=ctx%>/agente/guardar_caracteristicas.jsp" method="post">
            <input type="hidden" name="id" value="<%=idProp%>">
            <div class="row g-3">
        <% for (Object[] c : caracteristicas) {
            int idCar = ((Integer) c[0]).intValue();
            String nombreCar = (String) c[1];
            int cantidad = ((Integer) c[2]).intValue();
            boolean marcada = cantidad > 0;
        %>
                <div class="col-md-4">
                    <div class="form-check form-check-inline align-items-center gap-2 py-2 px-3 rounded-3 border
                        <%= marcada ? "border-primary bg-body-tertiary" : "" %>">
                        <input class="form-check-input" type="checkbox" id="car_<%=idCar%>" name="car_<%=idCar%>"
                               value="1" <%= marcada ? "checked" : "" %>>
                        <label class="form-check-label me-1" for="car_<%=idCar%>"><%=esc(nombreCar)%></label>
                        <input type="number" min="1" class="form-control form-control-sm d-inline-block" style="width:80px"
                               id="cant_<%=idCar%>" name="cant_<%=idCar%>" value="<%=cantidad > 0 ? cantidad : 1%>"
                               title="Cantidad">
                    </div>
                </div>
        <% } %>
            </div>
            <div class="d-flex gap-2 mt-4">
                <button type="submit" class="btn ims-btn rounded-pill px-4"><i class="bi bi-save me-1"></i> Guardar caracteristicas</button>
                <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/agente/propiedades.jsp"><i class="bi bi-x-circle me-1"></i> Cancelar</a>
            </div>
        </form>
    </div>
</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>