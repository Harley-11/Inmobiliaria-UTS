<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 cliente/favoritos.jsp - Listado de propiedades favoritas del cliente
 conectado, con boton para quitarlas de favoritos.
--%>
<%
  String[] rolesPermitidos = { "cliente" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  String okMsj = request.getParameter("ok");
  String errMsj = request.getParameter("err");

  List<Object[]> favoritos = new ArrayList<Object[]>();
  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    ps = con.prepareStatement(
        "SELECT p.id_propiedad, p.titulo, p.precio, c.nombre_ciudad, p.estado, " +
        "(SELECT ip.url_imagen FROM imagen_propiedad ip " +
        " WHERE ip.id_propiedad = p.id_propiedad ORDER BY ip.orden LIMIT 1) AS imagen " +
        "FROM favorito f " +
        "JOIN propiedad p ON p.id_propiedad = f.id_propiedad " +
        "JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
        "WHERE f.id_usuario = ? ORDER BY f.fecha_marcado DESC");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    while (rs.next()) favoritos.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2), Double.valueOf(rs.getDouble(3)),
        rs.getString(4), rs.getString(5), rs.getString(6)});
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudieron cargar sus favoritos.";
  } finally {
    cerrar(rs, ps, con);
  }

  String tituloPagina = "Mis favoritos";
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Mis favoritos</h1>
        <p class="text-muted mb-0">Propiedades marcadas para consulta rapida.</p>
    </div>
    <a class="btn ims-btn rounded-pill px-4" href="<%=ctx%>/propiedades.jsp"><i class="bi bi-search me-1"></i> Buscar propiedades</a>
</div>

<% if ("1".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Favorito agregado.</div>
<% } else if ("2".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Quitado de sus favoritos.</div>
<% } %>
<% if (errMsj != null && !errMsj.trim().isEmpty()) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
<% } %>

<% if (favoritos.isEmpty()) { %>
    <p class="text-center text-muted py-5"><i class="bi bi-heart me-1"></i>No tiene propiedades favoritas. Use el corazon en la ficha de una propiedad.</p>
<% } else { %>
<div class="row g-4">
<% for (Object[] f : favoritos) {
    int idPro = ((Integer) f[0]).intValue();
    String tituloF = (String) f[1];
    double precioF = ((Double) f[2]).doubleValue();
    String ciudadF = (String) f[3];
    String estadoF = (String) f[4];
    String img = (String) f[5];
    if (img == null || img.trim().isEmpty()) img = "https://picsum.photos/seed/propiedad" + idPro + "/800/600";
%>
    <div class="col-md-6 col-lg-4">
        <div class="card ims-card h-100 shadow">
            <img src="<%=esc(img)%>" class="ims-thumb" alt="<%=esc(tituloF)%>">
            <div class="card-body d-flex flex-column">
                <span class="badge text-bg-<%=colorEstado(estadoF)%> align-self-start mb-2 fw-semibold"><%=esc(estadoF)%></span>
                <h2 class="h6 fw-bold text-truncate mb-1" title="<%=esc(tituloF)%>"><%=esc(tituloF)%></h2>
                <p class="text-muted small mb-2"><i class="bi bi-geo-alt me-1"></i><%=esc(ciudadF)%></p>
                <div class="d-flex justify-content-between align-items-center mt-auto pt-2 border-top">
                    <span class="ims-precio fw-bold"><%=pesos(precioF)%></span>
                    <div class="d-flex gap-2">
                        <a class="btn btn-outline-primary btn-sm rounded-pill" href="<%=ctx%>/propiedad.jsp?id=<%=idPro%>"><i class="bi bi-eye"></i></a>
                        <form method="post" action="<%=ctx%>/cliente/favorito_toggle.jsp" class="d-inline">
                            <input type="hidden" name="propiedad" value="<%=idPro%>">
                            <input type="hidden" name="origen" value="favoritos">
                            <button type="submit" class="btn btn-outline-danger btn-sm rounded-pill" title="Quitar de favoritos"><i class="bi bi-heart-fill"></i></button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
<% } %>
</div>
<% } %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>