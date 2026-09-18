<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 index.jsp - Pagina de entrada de la aplicacion.
  1) Con sesion activa: redirige al panel segun el rol
     (administrador -> /admin/panel.jsp, inmobiliaria -> /agente/panel.jsp,
     cliente -> /cliente/panel.jsp).
  2) Sin sesion: muestra la landing page PUBLICA que pide el enunciado:
     presentacion de la inmobiliaria, buscador rapido hacia propiedades.jsp,
     publicaciones destacadas (disponibles, mas recientes) y accesos
     destacados a login.jsp y registro.jsp.
--%>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
  String ctx = request.getContextPath();
  HttpSession sesion = request.getSession(false);
  boolean sesionActiva = (sesion != null && sesion.getAttribute("idUsuario") != null);

  if (sesionActiva) {
    String rolesCsv = (String) sesion.getAttribute("roles");
    String destino;
    if (tieneAlgunRol(rolesCsv, new String[]{"administrador"})) {
      destino = ctx + "/admin/panel.jsp";
    } else if (tieneAlgunRol(rolesCsv, new String[]{"inmobiliaria"})) {
      destino = ctx + "/agente/panel.jsp";
    } else {
      destino = ctx + "/cliente/panel.jsp";
    }
    response.sendRedirect(destino);
    return;
  }
%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  String tituloPagina = "Inmobiliaria UTS";

  List<Object[]> ciudades = new ArrayList<Object[]>();
  List<Object[]> tipos = new ArrayList<Object[]>();
  List<Object[]> destacadas = new ArrayList<Object[]>();
  String errorLanding = null;

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();

    // Opciones del buscador rapido (mismos filtros que propiedades.jsp).
    ps = con.prepareStatement("SELECT id_ciudad, nombre_ciudad FROM ciudad ORDER BY nombre_ciudad");
    rs = ps.executeQuery();
    while (rs.next()) ciudades.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    cerrar(rs, ps);

    ps = con.prepareStatement("SELECT id_tipo, nombre_tipo FROM tipo_propiedad ORDER BY nombre_tipo");
    rs = ps.executeQuery();
    while (rs.next()) tipos.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    cerrar(rs, ps);

    // Publicaciones destacadas: hasta 6 propiedades disponibles,
    // las mas recientes por fecha de publicacion.
    ps = con.prepareStatement(
        "SELECT p.id_propiedad, p.titulo, p.precio, p.descripcion, " +
        "c.nombre_ciudad, t.nombre_tipo, p.direccion, " +
        "(SELECT ip.url_imagen FROM imagen_propiedad ip " +
        " WHERE ip.id_propiedad = p.id_propiedad ORDER BY ip.orden LIMIT 1) AS imagen_principal " +
        "FROM propiedad p " +
        "JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
        "JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
        "WHERE p.estado = 'disponible' " +
        "ORDER BY p.fecha_publicacion DESC LIMIT 6");
    rs = ps.executeQuery();
    while (rs.next()) destacadas.add(new Object[]{
        Integer.valueOf(rs.getInt("id_propiedad")),
        rs.getString("titulo"),
        Double.valueOf(rs.getDouble("precio")),
        rs.getString("descripcion"),
        rs.getString("nombre_ciudad"),
        rs.getString("nombre_tipo"),
        rs.getString("direccion"),
        rs.getString("imagen_principal")});
  } catch (Exception e) {
    e.printStackTrace();
    errorLanding = "No se pudieron cargar las publicaciones en este momento. Intente mas tarde.";
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<%-- ============ Presentacion de la inmobiliaria ============ --%>
<div class="card ims-card shadow-lg mb-4">
    <div class="card-body p-4 p-md-5 text-center">
        <div class="d-inline-flex align-items-center justify-content-center gap-2 mb-2">
            <span class="ims-brand-badge"><i class="bi bi-house-heart-fill"></i></span>
            <h1 class="h3 fw-bold mb-0">Inmobiliaria UTS</h1>
        </div>
        <p class="lead text-muted mb-2">El hogar que buscas, lo encuentras aca.</p>
        <p class="text-muted mx-auto mb-4" style="max-width:640px">
            Somos una inmobiliaria de las Unidades Tecnologicas de Santander que
            conecta a personas con su proximo hogar: publique su propiedad, agenda
            visitas y gestione las solicitudes de compra o arriendo, todo en un
            mismo lugar.
        </p>
        <div class="d-flex flex-wrap justify-content-center gap-2">
            <a class="btn ims-btn rounded-pill px-5 py-2" href="<%=ctx%>/login.jsp"><i class="bi bi-box-arrow-in-right me-1"></i> Iniciar sesion</a>
            <a class="btn btn-outline-secondary rounded-pill px-5 py-2" href="<%=ctx%>/registro.jsp"><i class="bi bi-person-plus me-1"></i> Registrarse</a>
        </div>
    </div>
</div>

<%-- ============ Buscador rapido ============ --%>
<div class="card ims-card shadow-sm p-3 mb-4">
    <div class="card-body py-2">
        <form action="<%=ctx%>/propiedades.jsp" method="get" class="row g-3 align-items-end">
            <div class="col-md-3">
                <label class="form-label small mb-1" for="ciudad">Ciudad</label>
                <select class="form-select" id="ciudad" name="ciudad">
                    <option value="0">Todas las ciudades</option>
                <% for (Object[] c : ciudades) { %>
                    <option value="<%=((Integer) c[0]).intValue()%>"><%=esc((String) c[1])%></option>
                <% } %>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label small mb-1" for="tipo">Tipo</label>
                <select class="form-select" id="tipo" name="tipo">
                    <option value="0">Todos los tipos</option>
                <% for (Object[] t : tipos) { %>
                    <option value="<%=((Integer) t[0]).intValue()%>"><%=esc((String) t[1])%></option>
                <% } %>
                </select>
            </div>
            <div class="col-md-2">
                <label class="form-label small mb-1" for="precio_min">Precio desde</label>
                <input type="number" min="0" step="100000" class="form-control" id="precio_min" name="precio_min" placeholder="0">
            </div>
            <div class="col-md-2">
                <label class="form-label small mb-1" for="precio_max">Precio hasta</label>
                <input type="number" min="0" step="100000" class="form-control" id="precio_max" name="precio_max" placeholder="Sin limite">
            </div>
            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn ims-btn rounded-pill px-4 flex-fill"><i class="bi bi-funnel me-1"></i> Buscar</button>
            </div>
        </form>
    </div>
</div>

<%-- ============ Publicaciones destacadas ============ --%>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-3">
    <h2 class="h4 fw-bold mb-0">Publicaciones destacadas</h2>
    <a class="text-decoration-none small" href="<%=ctx%>/propiedades.jsp">Ver todas las propiedades <i class="bi bi-arrow-right"></i></a>
</div>

<% if (errorLanding != null) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=errorLanding%></div>
<% } %>

<div class="row g-4">
<% for (Object[] f : destacadas) {
    int idProp = ((Integer) f[0]).intValue();
    String titulo = (String) f[1];
    double precio = ((Double) f[2]).doubleValue();
    String descripcion = (String) f[3];
    String ciudad = (String) f[4];
    String tipo = (String) f[5];
    String direccion = (String) f[6];
    String img = (String) f[7];
    if (img == null || img.trim().isEmpty()) {
      img = "https://picsum.photos/seed/propiedad" + idProp + "/800/600";
    }
    String resumen = (descripcion == null)
        ? "Consulte el detalle para conocer toda la informacion."
        : (descripcion.length() > 90 ? descripcion.substring(0, 90) + "..." : descripcion);
%>
    <div class="col-md-6 col-lg-4">
        <div class="card ims-card h-100 shadow">
            <img src="<%=esc(img)%>" class="ims-thumb" alt="<%=esc(titulo)%>">
            <div class="card-body d-flex flex-column">
                <span class="badge text-bg-primary align-self-start mb-2 fw-semibold"><%=esc(tipo)%></span>
                <h3 class="h6 fw-bold text-truncate mb-1" title="<%=esc(titulo)%>"><%=esc(titulo)%></h3>
                <p class="text-muted small mb-1"><i class="bi bi-geo-alt me-1"></i><%=esc(ciudad)%><% if (direccion != null && !direccion.isEmpty()) { %>, <%=esc(direccion)%><% } %></p>
                <p class="text-muted small flex-grow-1 mb-2"><%=esc(resumen)%></p>
                <div class="d-flex justify-content-between align-items-center mt-auto pt-2 border-top">
                    <span class="ims-precio fs-5 fw-bold"><%=pesos(precio)%></span>
                    <a class="btn ims-btn btn-sm rounded-pill px-3" href="<%=ctx%>/propiedad.jsp?id=<%=idProp%>"><i class="bi bi-eye me-1"></i> Ver detalle</a>
                </div>
            </div>
        </div>
    </div>
<% } %>
</div>

<% if (destacadas.isEmpty()) { %>
    <p class="text-center text-muted py-5"><i class="bi bi-building me-1"></i>No hay publicaciones destacadas por el momento.</p>
<% } %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>