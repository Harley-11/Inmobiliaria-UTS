<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 agente/galeria.jsp - Gestion de la galeria de imagenes de una propiedad
 propia: listar, agregar (url + orden), marcar principal y eliminar.
 Operaciones via POST a agregar_imagen.jsp / img_principal.jsp /
 eliminar_imagen.jsp, todas redirigen de vuelta a esta pagina.
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
  List<Object[]> imagenes = new ArrayList<Object[]>();

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
        "SELECT id_imagen, url_imagen, orden FROM imagen_propiedad WHERE id_propiedad = ? ORDER BY orden, id_imagen");
    ps.setInt(1, idProp);
    rs = ps.executeQuery();
    while (rs.next()) imagenes.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2), Integer.valueOf(rs.getInt(3))});
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudo cargar la galeria.";
  } finally {
    cerrar(rs, ps, con);
  }

  String tituloPagina = "Galeria de imagenes";
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Galeria de imagenes</h1>
        <p class="text-muted mb-0"><%=esc(tituloPropiedad)%></p>
    </div>
    <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/agente/propiedades.jsp"><i class="bi bi-arrow-left me-1"></i> Volver</a>
</div>

<% if ("3".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Galeria actualizada.</div>
<% } %>
<% if (errMsj != null && !errMsj.trim().isEmpty()) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
<% } %>

<div class="card ims-card shadow-sm mb-4">
    <div class="card-header bg-transparent fw-bold"><i class="bi bi-image me-1"></i> Agregar imagen</div>
    <div class="card-body">
        <form action="<%=ctx%>/agente/agregar_imagen.jsp" method="post" class="row g-3 align-items-end">
            <input type="hidden" name="id" value="<%=idProp%>">
            <div class="col-md-8">
                <label class="form-label small mb-1" for="url">URL de la imagen *</label>
                <input type="url" class="form-control" id="url" name="url" required
                       placeholder="https://.../foto.jpg">
            </div>
            <div class="col-md-2">
                <label class="form-label small mb-1" for="orden">Orden</label>
                <input type="number" min="1" class="form-control" id="orden" name="orden" value="1">
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn ims-btn rounded-pill w-100"><i class="bi bi-plus-lg"></i> Agregar</button>
            </div>
        </form>
    </div>
</div>

<% if (imagenes.isEmpty()) { %>
    <p class="text-center text-muted py-4"><i class="bi bi-image me-1"></i>Sin imagenes. Agregue la primera arriba.</p>
<% } else { %>
<div class="row g-3">
<% for (Object[] im : imagenes) {
    int idImagen = ((Integer) im[0]).intValue();
    String url = (String) im[1];
    int orden = ((Integer) im[2]).intValue();
%>
    <div class="col-md-4">
        <div class="card ims-card shadow-sm h-100">
            <img src="<%=esc(url)%>" class="card-img-top" alt="Imagen" style="height:160px;object-fit:cover;">
            <div class="card-body">
                <div class="d-flex align-items-center justify-content-between mb-2">
                    <span class="badge text-bg-<%=orden == 1 ? "warning" : "secondary"%> fw-semibold">
                        <%= orden == 1 ? "<i class='bi bi-star-fill'></i> Portada" : "Orden " + orden %>
                    </span>
                </div>
                <div class="d-flex gap-2">
                    <% if (orden != 1) { %>
                    <form method="post" action="<%=ctx%>/agente/img_principal.jsp" class="d-inline">
                        <input type="hidden" name="id" value="<%=idProp%>">
                        <input type="hidden" name="imagen" value="<%=idImagen%>">
                        <button type="submit" class="btn btn-sm btn-outline-warning rounded-pill"><i class="bi bi-star"></i> Portada</button>
                    </form>
                    <% } %>
                    <form method="post" action="<%=ctx%>/agente/eliminar_imagen.jsp" class="d-inline">
                        <input type="hidden" name="id" value="<%=idProp%>">
                        <input type="hidden" name="imagen" value="<%=idImagen%>">
                        <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill"><i class="bi bi-trash"></i> Eliminar</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
<% } %>
</div>
<% } %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>