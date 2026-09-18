<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 propiedad.jsp - Ficha publica de detalle de una propiedad. Muestra galeria de
 imagenes (carrusel Bootstrap), datos principales y las caracteristicas
 asociadas (propiedad_caracteristica). Si la propiedad esta en estado
 'disponible' se ofrecen las acciones (visita, favoritos, solicitud); si ya
 fue 'vendida' o 'arrendada' se muestra la ficha con una etiqueta informativa
 y SIN botones de accion. Las propiedades 'inactivo' (baja logica de la
 inmobiliaria) nunca se muestran: redirige a propiedades.jsp.
 El visitante sin sesion NO ve los datos de contacto completos de la
 inmobiliaria (solo el nombre comercial). "Solicitar visita" exige sesion
 de rol cliente y redirige a login.jsp?error=visita si no la hay.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  String ctx = request.getContextPath();
  int idProp = aEntero(request.getParameter("id"), 0);

  String titulo = null;
  String descripcion = null;
  double precio = 0;
  String direccion = null;
  String estado = null;
  String matricula = null;
  String ciudad = null;
  String departamento = null;
  String tipo = null;
  String inmobiliaria = null;
  String inmobiliariaTelefono = null;
  String inmobiliariaCorreo = null;
  boolean esFavorita = false;
  List<String> imagenes = new ArrayList<String>();
  List<Object[]> caracteristicas = new ArrayList<Object[]>();
  boolean encontrada = false;

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();

    ps = con.prepareStatement(
        "SELECT p.titulo, p.descripcion, p.precio, p.direccion, p.estado, "
      + "p.matricula_inmobiliaria, c.nombre_ciudad, c.departamento, t.nombre_tipo, "
      + "im.nombre_comercial, u.correo AS correo_inmobiliaria, pf.telefono AS telefono_inmobiliaria "
      + "FROM propiedad p "
      + "JOIN ciudad c ON c.id_ciudad = p.id_ciudad "
      + "JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo "
      + "LEFT JOIN inmobiliaria im ON im.id_inmobiliaria = p.id_inmobiliaria "
      + "LEFT JOIN usuario u ON u.id_usuario = im.id_usuario "
      + "LEFT JOIN perfil pf ON pf.id_usuario = im.id_usuario "
      + "WHERE p.id_propiedad = ?");
    ps.setInt(1, idProp);
    rs = ps.executeQuery();
    if (rs.next()) {
      encontrada = true;
      titulo = rs.getString("titulo");
      descripcion = rs.getString("descripcion");
      precio = rs.getDouble("precio");
      direccion = rs.getString("direccion");
      estado = rs.getString("estado");
      matricula = rs.getString("matricula_inmobiliaria");
      ciudad = rs.getString("nombre_ciudad");
      departamento = rs.getString("departamento");
      tipo = rs.getString("nombre_tipo");
      inmobiliaria = rs.getString("nombre_comercial");
      inmobiliariaTelefono = rs.getString("telefono_inmobiliaria");
      inmobiliariaCorreo = rs.getString("correo_inmobiliaria");
    }
    cerrar(rs, ps);

    if (encontrada) {
      ps = con.prepareStatement(
          "SELECT url_imagen FROM imagen_propiedad WHERE id_propiedad = ? ORDER BY orden");
      ps.setInt(1, idProp);
      rs = ps.executeQuery();
      while (rs.next()) { imagenes.add(rs.getString(1)); }
      cerrar(rs, ps);
      if (imagenes.isEmpty()) {
        imagenes.add("https://picsum.photos/seed/propiedad" + idProp + "/1000/600");
      }

      Object idSesion = session.getAttribute("idUsuario");
      if (idSesion != null && tieneRol((String) session.getAttribute("roles"), "cliente")) {
        ps = con.prepareStatement(
            "SELECT 1 FROM favorito WHERE id_usuario = ? AND id_propiedad = ?");
        ps.setInt(1, ((Integer) idSesion).intValue());
        ps.setInt(2, idProp);
        rs = ps.executeQuery();
        esFavorita = rs.next();
        cerrar(rs, ps);
      }

      ps = con.prepareStatement(
          "SELECT c.nombre_caracteristica, pc.cantidad "
        + "FROM propiedad_caracteristica pc "
        + "JOIN caracteristica c ON c.id_caracteristica = pc.id_caracteristica "
        + "WHERE pc.id_propiedad = ? AND pc.cantidad > 0 "
        + "ORDER BY c.id_caracteristica");
      ps.setInt(1, idProp);
      rs = ps.executeQuery();
      while (rs.next()) {
        caracteristicas.add(new Object[]{rs.getString(1), Integer.valueOf(rs.getInt(2))});
      }
    }
  } catch (Exception e) {
    e.printStackTrace();
  } finally {
    cerrar(rs, ps, con);
  }
%>

  <%
  if (!encontrada || "inactivo".equals(estado)) {
    // No existe, o la inmobiliaria la retiro del mercado (baja logica):
    // nunca se muestra publicamente.
    response.sendRedirect(ctx + "/propiedades.jsp");
    return;
  }

  boolean disponible = "disponible".equals(estado);
  String tituloPagina = titulo;
  boolean haySesion = session.getAttribute("idUsuario") != null;
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<nav class="mb-3" aria-label="breadcrumb">
    <ol class="breadcrumb mb-2">
        <li class="breadcrumb-item"><a href="<%=ctx%>/index.jsp">Inicio</a></li>
        <li class="breadcrumb-item"><a href="<%=ctx%>/propiedades.jsp">Propiedades</a></li>
        <li class="breadcrumb-item active" aria-current="page"><%=esc(titulo)%></li>
    </ol>
</nav>

<div class="row g-4">
    <div class="col-lg-7">
        <div id="galeriaPropiedad" class="carousel slide rounded-4 overflow-hidden shadow" data-bs-ride="carousel">
            <div class="carousel-inner">
                <% for (int i = 0; i < imagenes.size(); i++) { %>
                <div class="carousel-item <%= i == 0 ? "active" : "" %>">
                    <img src="<%=esc(imagenes.get(i))%>" class="d-block w-100" alt="<%=esc(titulo)%>"
                         style="height: 400px; object-fit: cover;">
                </div>
                <% } %>
            </div>
            <% if (imagenes.size() > 1) { %>
            <button class="carousel-control-prev" type="button" data-bs-target="#galeriaPropiedad" data-bs-slide="prev">
                <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                <span class="visually-hidden">Anterior</span>
            </button>
            <button class="carousel-control-next" type="button" data-bs-target="#galeriaPropiedad" data-bs-slide="next">
                <span class="carousel-control-next-icon" aria-hidden="true"></span>
                <span class="visually-hidden">Siguiente</span>
            </button>
            <% } %>
        </div>

        <div class="card ims-card shadow-sm mt-4">
            <div class="card-body">
                <h2 class="h5 fw-bold mb-3"><i class="bi bi-justify me-1 ims-acento"></i> Descripcion</h2>
                <p class="text-muted mb-0"><%=esc(descripcion == null ? "Sin descripcion." : descripcion)%></p>
            </div>
        </div>

        <% if (!caracteristicas.isEmpty()) { %>
        <div class="card ims-card shadow-sm mt-4">
            <div class="card-body">
                <h2 class="h5 fw-bold mb-3"><i class="bi bi-sliders me-1 ims-acento"></i> Caracteristicas</h2>
                <div class="d-flex flex-wrap gap-2">
                <% for (Object[] c : caracteristicas) {
                    String nombre = (String) c[0];
                    int cantidad = ((Integer) c[1]).intValue();
                    String texto = (cantidad == 1) ? nombre : nombre + ": " + cantidad; %>
                    <span class="badge rounded-pill text-bg-light border fw-semibold px-3 py-2">
                        <i class="bi bi-check2-circle ims-acento me-1"></i><%=esc(texto)%>
                    </span>
                <% } %>
                </div>
            </div>
        </div>
        <% } %>
    </div>

    <div class="col-lg-5">
        <div class="card ims-card shadow-lg">
            <div class="card-body">
                <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
                    <span class="badge text-bg-primary fw-semibold"><%=esc(tipo)%></span>
                    <span class="badge text-bg-<%=colorEstado(estado)%> fw-semibold"><%=esc(estado)%></span>
                </div>
                <h1 class="h4 fw-bold mb-1"><%=esc(titulo)%></h1>
                <p class="text-muted mb-3">
                    <i class="bi bi-geo-alt me-1"></i><%=esc(ciudad)%><% if (departamento != null && !departamento.isEmpty()) { %> &middot; <%=esc(departamento)%><% } %>
                    <% if (direccion != null && !direccion.isEmpty()) { %><br><span class="small"><i class="bi bi-signpost me-1"></i><%=esc(direccion)%></span><% } %>
                </p>

                <div class="ims-precio fs-2 fw-bold rounded-4 bg-body-tertiary text-center py-3 mb-3">
                    <%=pesos(precio)%>
                </div>

                <ul class="list-unstyled small text-muted mb-3">
                    <li class="mb-1"><i class="bi bi-hash me-1"></i>Matricula inmobiliaria: <strong><%=esc(matricula)%></strong></li>
                    <% if (inmobiliaria != null && !inmobiliaria.isEmpty()) { %>
                    <li class="mb-1"><i class="bi bi-building me-1"></i>Publicada por: <strong><%=esc(inmobiliaria)%></strong></li>
                    <% } %>
                </ul>

                <div class="card border-0 bg-body-tertiary rounded-4 mb-3">
                    <div class="card-body py-3">
                        <h2 class="h6 fw-bold mb-2"><i class="bi bi-building me-1 ims-acento"></i> Datos de contacto</h2>
                        <% if (haySesion) { %>
                            <p class="fw-semibold mb-1"><%=esc(inmobiliaria)%></p>
                            <% if (inmobiliariaTelefono != null && !inmobiliariaTelefono.isEmpty()) { %>
                            <p class="mb-1"><i class="bi bi-telephone me-1"></i><%=esc(inmobiliariaTelefono)%></p>
                            <% } %>
                            <% if (inmobiliariaCorreo != null && !inmobiliariaCorreo.isEmpty()) { %>
                            <p class="mb-0"><i class="bi bi-envelope me-1"></i><%=esc(inmobiliariaCorreo)%></p>
                            <% } %>
                        <% } else { %>
                            <p class="text-muted small mb-0"><i class="bi bi-info-circle me-1"></i>Inicie sesion para ver los datos de contacto completos de la inmobiliaria.</p>
                        <% } %>
                    </div>
                </div>

                <div class="d-grid gap-2">
                    <% if (!disponible) { %>
                        <div class="alert alert-warning rounded-4 mb-2 small">
                            <i class="bi bi-info-circle me-1"></i>
                            Esta propiedad fue <%= "vendida".equals(estado) ? "vendida" : "arrendada" %>
                            y ya no esta disponible para agendar visitas ni radicar solicitudes.
                        </div>
                    <% } else if (haySesion && tieneRol((String) session.getAttribute("roles"), "cliente")) { %>
                        <a class="btn ims-btn rounded-pill py-2" href="<%=ctx%>/cliente/solicitar_visita.jsp?propiedad=<%=idProp%>">
                            <i class="bi bi-calendar-check me-1"></i> Solicitar visita
                        </a>
                        <a class="btn btn-outline-<%=esFavorita ? "danger" : "secondary"%> rounded-pill py-2" href="<%=ctx%>/cliente/favorito_toggle.jsp?propiedad=<%=idProp%>&origen=ficha">
                            <i class="bi bi-heart<%=esFavorita ? "-fill" : ""%> me-1"></i> <%=esFavorita ? "Quitar de favoritos" : "Agregar a favoritos"%>
                        </a>
                        <a class="btn btn-outline-primary rounded-pill py-2" href="<%=ctx%>/cliente/solicitar_solicitud.jsp?propiedad=<%=idProp%>">
                            <i class="bi bi-file-earmark-text me-1"></i> Solicitar compra o arriendo
                        </a>
                    <% } else if (!haySesion) { %>
                        <a class="btn ims-btn rounded-pill py-2" href="<%=ctx%>/login.jsp?error=visita">
                            <i class="bi bi-calendar-check me-1"></i> Solicitar visita
                        </a>
                    <% } %>
                    <a class="btn btn-outline-secondary rounded-pill py-2" href="<%=ctx%>/propiedades.jsp">
                        <i class="bi bi-arrow-left me-1"></i> Volver al listado
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>