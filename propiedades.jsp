<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 agente/propiedades.jsp - Listado de las propiedades de la inmobiliaria
 del agente conectado, con acciones: editar, galeria, caracteristicas,
 dar de baja (inactivo) / reactivar, y enlace publico al detalle.
 Protegida por seguridad.jspf y SeguridadFilter.
--%>
<%
  String[] rolesPermitidos = { "inmobiliaria" };
  String tituloPagina = "Mis propiedades";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  String okMsj = request.getParameter("ok");
  String errMsj = request.getParameter("err");

  int idInmobiliaria = 0;
  List<Object[]> filas = new ArrayList<Object[]>();
  boolean sinInmobiliaria = false;

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);
    if (idInmobiliaria <= 0) {
      sinInmobiliaria = true;
    } else {
      ps = con.prepareStatement(
          "SELECT p.id_propiedad, p.titulo, p.precio, p.estado, p.fecha_publicacion, " +
          "c.nombre_ciudad, t.nombre_tipo, " +
          "(SELECT ip.url_imagen FROM imagen_propiedad ip " +
          " WHERE ip.id_propiedad = p.id_propiedad ORDER BY ip.orden LIMIT 1) AS imagen " +
          "FROM propiedad p " +
          "JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
          "JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
          "WHERE p.id_inmobiliaria = ? ORDER BY p.id_propiedad DESC");
      ps.setInt(1, idInmobiliaria);
      rs = ps.executeQuery();
      while (rs.next()) {
        filas.add(new Object[]{
          Integer.valueOf(rs.getInt(1)), rs.getString(2), Double.valueOf(rs.getDouble(3)),
          rs.getString(4), rs.getString(5), rs.getString(6), rs.getString(7), rs.getString(8)
        });
      }
    }
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudo cargar el listado.";
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Mis propiedades</h1>
        <p class="text-muted mb-0">Administre el inventario de su inmobiliaria.</p>
    </div>
    <a class="btn ims-btn rounded-pill px-4" href="<%=ctx%>/agente/propiedad_editar.jsp">
        <i class="bi bi-plus-lg me-1"></i> Publicar propiedad
    </a>
</div>

<% if ("1".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Propiedad guardada correctamente.</div>
<% } %>
<% if ("2".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Estado de la propiedad actualizado.</div>
<% } %>
<% if ("3".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Galeria de imagenes actualizada.</div>
<% } %>
<% if ("4".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Caracteristicas actualizadas.</div>
<% } %>
<% if ("5".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Galería y detalles actualizados.</div>
<% } %>
<% if (errMsj != null && !errMsj.trim().isEmpty()) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
<% } %>

<% if (sinInmobiliaria) { %>
    <div class="alert alert-warning rounded-4">
        <i class="bi bi-exclamation-triangle me-1"></i>
        Su cuenta no tiene una inmobiliaria asociada. Contacte al administrador.
    </div>
<% } else if (filas.isEmpty()) { %>
    <p class="text-center text-muted py-5"><i class="bi bi-inbox me-1"></i>Aun no ha publicado propiedades.</p>
<% } else { %>
<div class="table-responsive">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th scope="col" style="width:70px">Foto</th>
                <th scope="col">Propiedad</th>
                <th scope="col">Precio</th>
                <th scope="col">Estado</th>
                <th scope="col" class="text-end">Acciones</th>
            </tr>
        </thead>
        <tbody>
        <% for (Object[] f : filas) {
            int idProp = ((Integer) f[0]).intValue();
            String tituloP = (String) f[1];
            double precio = ((Double) f[2]).doubleValue();
            String estadoP = (String) f[3];
            String ciudadP = (String) f[5];
            String tipoP = (String) f[6];
            String img = (String) f[7];
            if (img == null || img.trim().isEmpty()) img = "https://picsum.photos/seed/propiedad" + idProp + "/160/120";
        %>
            <tr>
                <td><img src="<%=esc(img)%>" alt="<%=esc(tituloP)%>" class="rounded-3"
                         style="width:70px;height:52px;object-fit:cover;"></td>
                <td>
                    <div class="fw-semibold text-truncate" style="max-width:280px"><%=esc(tituloP)%></div>
                    <div class="small text-muted"><i class="bi bi-geo-alt me-1"></i><%=esc(ciudadP)%> &middot; <%=esc(tipoP)%></div>
                </td>
                <td class="fw-semibold"><%=pesos(precio)%></td>
                <td><span class="badge text-bg-<%=colorEstado(estadoP)%> fw-semibold"><%=esc(estadoP)%></span></td>
                <td class="text-end text-nowrap">
                    <a class="btn btn-sm btn-outline-secondary rounded-pill" title="Ver publico" href="<%=ctx%>/propiedad.jsp?id=<%=idProp%>">
                        <i class="bi bi-eye"></i>
                    </a>
                    <a class="btn btn-sm btn-outline-primary rounded-pill" title="Editar" href="<%=ctx%>/agente/propiedad_editar.jsp?id=<%=idProp%>">
                        <i class="bi bi-pencil"></i>
                    </a>
                    <a class="btn btn-sm btn-outline-info rounded-pill" title="Galería" href="<%=ctx%>/agente/galeria.jsp?id=<%=idProp%>">
                        <i class="bi bi-images"></i>
                    </a>
                    <a class="btn btn-sm btn-outline-success rounded-pill" title="Caracteristicas" href="<%=ctx%>/agente/caracteristicas.jsp?id=<%=idProp%>">
                        <i class="bi bi-sliders"></i>
                    </a>
                    <% if (!"inactivo".equals(estadoP)) { %>
                    <form method="post" action="<%=ctx%>/agente/propiedad_estado.jsp" class="d-inline">
                        <input type="hidden" name="id" value="<%=idProp%>">
                        <input type="hidden" name="accion" value="inactivar">
                        <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill" title="Dar de baja (inactivo)">
                            <i class="bi bi-archive"></i>
                        </button>
                    </form>
                    <% } else { %>
                    <form method="post" action="<%=ctx%>/agente/propiedad_estado.jsp" class="d-inline">
                        <input type="hidden" name="id" value="<%=idProp%>">
                        <input type="hidden" name="accion" value="reactivar">
                        <button type="submit" class="btn btn-sm btn-outline-success rounded-pill" title="Reactivar (disponible)">
                            <i class="bi bi-arrow-up-circle"></i>
                        </button>
                    </form>
                    <% } %>
                </td>
            </tr>
        <% } %>
        </tbody>
    </table>
</div>
<% } %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>