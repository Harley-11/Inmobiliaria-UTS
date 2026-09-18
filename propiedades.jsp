<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 propiedades.jsp - Listado publico de propiedades en estado "disponible",
 con filtros por ciudad, tipo y rango de precio. Cada tarjeta enlaza a
 la ficha de detalle propiedad.jsp?id=...
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  String ctx = request.getContextPath();
  String tituloPagina = "Propiedades";

  int idCiudad = aEntero(request.getParameter("ciudad"), 0);
  int idTipo   = aEntero(request.getParameter("tipo"), 0);
  double precioMin = aDoble(request.getParameter("precio_min"), 0);
  double precioMax = aDoble(request.getParameter("precio_max"), 0);
  boolean verTodas = "todas".equals(request.getParameter("estado"));

  List<Object[]> ciudades = new ArrayList<Object[]>();
  List<Object[]> tipos = new ArrayList<Object[]>();
  List<Object[]> filas = new ArrayList<Object[]>();
  String errorListado = null;

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();

    ps = con.prepareStatement("SELECT id_ciudad, nombre_ciudad FROM ciudad ORDER BY nombre_ciudad");
    rs = ps.executeQuery();
    while (rs.next()) {
      ciudades.add(new Object[]{Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    }
    cerrar(rs, ps);

    ps = con.prepareStatement("SELECT id_tipo, nombre_tipo FROM tipo_propiedad ORDER BY nombre_tipo");
    rs = ps.executeQuery();
    while (rs.next()) {
      tipos.add(new Object[]{Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    }
    cerrar(rs, ps);

    StringBuilder sql = new StringBuilder();
    sql.append("SELECT p.id_propiedad, p.titulo, p.descripcion, p.precio, p.direccion, p.estado, ")
       .append("c.nombre_ciudad, t.nombre_tipo, ")
       .append("(SELECT ip.url_imagen FROM imagen_propiedad ip ")
       .append(" WHERE ip.id_propiedad = p.id_propiedad ORDER BY ip.orden LIMIT 1) AS imagen_principal ")
       .append("FROM propiedad p ")
       .append("JOIN ciudad c ON c.id_ciudad = p.id_ciudad ")
       .append("JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo ")
       .append("WHERE ");
    if (!verTodas) {
      sql.append("p.estado = 'disponible' ");
    } else {
      sql.append("p.estado <> 'inactivo' ");
    }

    List<Object> params = new ArrayList<Object>();
    if (idCiudad > 0)     { sql.append("AND p.id_ciudad = ? "); params.add(Integer.valueOf(idCiudad)); }
    if (idTipo > 0)       { sql.append("AND p.id_tipo = ? ");   params.add(Integer.valueOf(idTipo)); }
    if (precioMin > 0)    { sql.append("AND p.precio >= ? ");   params.add(Double.valueOf(precioMin)); }
    if (precioMax > 0)    { sql.append("AND p.precio <= ? ");   params.add(Double.valueOf(precioMax)); }
    sql.append("ORDER BY p.fecha_publicacion DESC");

    ps = con.prepareStatement(sql.toString());
    int idx = 1;
    for (Object o : params) { ps.setObject(idx++, o); }
    rs = ps.executeQuery();
    while (rs.next()) {
      filas.add(new Object[]{
        Integer.valueOf(rs.getInt("id_propiedad")),
        rs.getString("titulo"),
        rs.getString("descripcion"),
        Double.valueOf(rs.getDouble("precio")),
        rs.getString("nombre_ciudad"),
        rs.getString("nombre_tipo"),
        rs.getString("direccion"),
        rs.getString("estado"),
        rs.getString("imagen_principal")
      });
    }
  } catch (Exception e) {
    e.printStackTrace();
    errorListado = "No se pudieron cargar las propiedades. Intente mas tarde.";
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<h1 class="h3 fw-bold mb-1">Explora las propiedades disponibles</h1>
<p class="text-muted mb-4">Use los filtros para encontrar el hogar que busca.</p>

<% if (errorListado != null) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=errorListado%></div>
<% } %>

<form action="<%=ctx%>/propiedades.jsp" method="get" class="card ims-card shadow-sm p-3 mb-4">
    <div class="row g-3 align-items-end">
        <div class="col-md-3">
            <label class="form-label small mb-1" for="ciudad">Ciudad</label>
            <select class="form-select" id="ciudad" name="ciudad">
                <option value="0">Todas las ciudades</option>
<% for (Object[] c : ciudades) {
    int idCiud = ((Integer) c[0]).intValue();
    String sel = (idCiudad == idCiud) ? " selected" : ""; %>
                <option value="<%=idCiud%>"<%=sel%>><%=esc((String) c[1])%></option>
<% } %>
            </select>
        </div>
        <div class="col-md-3">
            <label class="form-label small mb-1" for="tipo">Tipo</label>
            <select class="form-select" id="tipo" name="tipo">
                <option value="0">Todos los tipos</option>
<% for (Object[] t : tipos) {
    int idTip = ((Integer) t[0]).intValue();
    String selT = (idTipo == idTip) ? " selected" : ""; %>
                <option value="<%=idTip%>"<%=selT%>><%=esc((String) t[1])%></option>
<% } %>
            </select>
        </div>
        <div class="col-md-3">
            <label class="form-label small mb-1" for="precio_min">Precio desde</label>
            <input type="number" min="0" step="100000" class="form-control" id="precio_min" name="precio_min"
                   value="<%= precioMin > 0 ? String.valueOf((long) precioMin) : "" %>" placeholder="0">
        </div>
        <div class="col-md-3">
            <label class="form-label small mb-1" for="precio_max">Precio hasta</label>
            <input type="number" min="0" step="100000" class="form-control" id="precio_max" name="precio_max"
                   value="<%= precioMax > 0 ? String.valueOf((long) precioMax) : "" %>" placeholder="Sin limite">
        </div>
        <div class="col-md-4">
            <label class="form-label small mb-1" for="estado">Estado</label>
            <select class="form-select" id="estado" name="estado">
                <option value="disponible"<%= verTodas ? "" : " selected" %>>Solo disponibles</option>
                <option value="todas"<%= verTodas ? " selected" : "" %>>Todas (incluye vendida/arrendada)</option>
            </select>
        </div>
        <div class="col-md-4 d-flex gap-2">
            <button type="submit" class="btn ims-btn rounded-pill px-4 flex-fill"><i class="bi bi-funnel me-1"></i> Filtrar</button>
        </div>
        <div class="col-md-4 d-flex gap-2">
            <a class="btn btn-outline-secondary rounded-pill px-4 w-100" href="<%=ctx%>/propiedades.jsp"><i class="bi bi-x-circle me-1"></i> Limpiar</a>
        </div>
    </div>
</form>

<div class="row g-4">
<% for (Object[] f : filas) {
    int idProp = ((Integer) f[0]).intValue();
    String titulo = (String) f[1];
    String descripcion = (String) f[2];
    double precio = ((Double) f[3]).doubleValue();
    String ciudad = (String) f[4];
    String tipo = (String) f[5];
    String direccion = (String) f[6];
    String estado = (String) f[7];
    String img = (String) f[8];
    if (img == null || img.trim().isEmpty()) {
      img = "https://picsum.photos/seed/propiedad" + idProp + "/800/600";
    }
    String resumen = (descripcion == null)
        ? "Consulte el detalle para conocer toda la informacion."
        : (descripcion.length() > 110 ? descripcion.substring(0, 110) + "..." : descripcion);
%>
    <div class="col-md-6 col-lg-4">
        <div class="card ims-card h-100 shadow">
            <img src="<%=esc(img)%>" class="ims-thumb" alt="<%=esc(titulo)%>">
            <div class="card-body d-flex flex-column">
                <div class="d-flex flex-wrap gap-1 align-self-start mb-2">
                    <span class="badge text-bg-primary fw-semibold"><%=esc(tipo)%></span>
                    <% if (!"disponible".equals(estado)) { %>
                    <span class="badge text-bg-<%=colorEstado(estado)%> fw-semibold"><i class="bi bi-check2-circle me-1"></i><%=esc(capitalizar(estado))%></span>
                    <% } %>
                </div>
                <h2 class="h6 fw-bold text-truncate mb-1" title="<%=esc(titulo)%>"><%=esc(titulo)%></h2>
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

<% if (filas.isEmpty()) { %>
    <p class="text-center text-muted py-5"><i class="bi bi-search me-1"></i>No se encontraron propiedades con esos criterios.</p>
<% } %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>