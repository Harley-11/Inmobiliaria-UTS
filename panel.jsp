<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 cliente/panel.jsp - Panel del rol cliente: resumen y acceso rapido a
 perfil, citas, solicitudes y favoritos. Protegido por seguridad.jspf
 (rolesPermitidos) y por SeguridadFilter (ruta /cliente/*).
--%>
<%
  String[] rolesPermitidos = { "cliente" };
  String tituloPagina = "Panel del cliente";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();

  boolean tienePerfil = false;
  int totalCitas = 0;
  int citasPendientes = 0;
  int totalSolicitudes = 0;
  int totalFavoritos = 0;
  String errorPanel = null;

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();

    ps = con.prepareStatement("SELECT 1 FROM perfil WHERE id_usuario = ?");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    tienePerfil = rs.next();
    cerrar(rs, ps);

    ps = con.prepareStatement(
        "SELECT COUNT(*), SUM(CASE WHEN estado = 'pendiente' THEN 1 ELSE 0 END) " +
        "FROM cita WHERE id_cliente = ?");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    if (rs.next()) { totalCitas = rs.getInt(1); citasPendientes = rs.getInt(2); }
    cerrar(rs, ps);

    ps = con.prepareStatement("SELECT COUNT(*) FROM solicitud WHERE id_cliente = ?");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    if (rs.next()) totalSolicitudes = rs.getInt(1);
    cerrar(rs, ps);

    ps = con.prepareStatement("SELECT COUNT(*) FROM favorito WHERE id_usuario = ?");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    if (rs.next()) totalFavoritos = rs.getInt(1);
  } catch (Exception e) {
    e.printStackTrace();
    errorPanel = "No se pudo cargar el resumen. Intente mas tarde.";
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Panel del cliente</h1>
        <p class="text-muted mb-0">Bienvenido, <%=esc(nombreSesion)%>.</p>
    </div>
    <% if (!tienePerfil) { %>
    <a class="btn ims-btn rounded-pill px-4" href="<%=ctx%>/cliente/perfil.jsp">
        <i class="bi bi-person-plus me-1"></i> Completar mi perfil
    </a>
    <% } %>
</div>

<% if (errorPanel != null) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=errorPanel%></div>
<% } %>

<div class="row g-3">
    <div class="col-sm-6 col-lg-3">
        <a class="card ims-card shadow-sm h-100 text-decoration-none" href="<%=ctx%>/cliente/perfil.jsp">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="ims-stat-icon"><i class="bi bi-person-vcard"></i></span>
                <div>
                    <div class="text-muted small">Perfil</div>
                    <div class="fw-bold fs-6">Completar / editar</div>
                </div>
            </div>
        </a>
    </div>
    <div class="col-sm-6 col-lg-3">
        <a class="card ims-card shadow-sm h-100 text-decoration-none" href="<%=ctx%>/cliente/mis_citas.jsp">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="ims-stat-icon"><i class="bi bi-calendar-check"></i></span>
                <div>
                    <div class="text-muted small">Citas</div>
                    <div class="fw-bold fs-3"><%=totalCitas%> <span class="text-secondary fs-6">(<%=citasPendientes%> pendientes)</span></div>
                </div>
            </div>
        </a>
    </div>
    <div class="col-sm-6 col-lg-3">
        <a class="card ims-card shadow-sm h-100 text-decoration-none" href="<%=ctx%>/cliente/mis_solicitudes.jsp">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="ims-stat-icon"><i class="bi bi-file-earmark-text"></i></span>
                <div>
                    <div class="text-muted small">Solicitudes</div>
                    <div class="fw-bold fs-3"><%=totalSolicitudes%></div>
                </div>
            </div>
        </a>
    </div>
    <div class="col-sm-6 col-lg-3">
        <a class="card ims-card shadow-sm h-100 text-decoration-none" href="<%=ctx%>/cliente/favoritos.jsp">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="ims-stat-icon"><i class="bi bi-heart"></i></span>
                <div>
                    <div class="text-muted small">Favoritos</div>
                    <div class="fw-bold fs-3"><%=totalFavoritos%></div>
                </div>
            </div>
        </a>
    </div>
</div>

<div class="card ims-card shadow-sm mt-4">
    <div class="card-body">
        <h2 class="h6 fw-bold mb-2"><i class="bi bi-lightbulb me-1 ims-acento"></i> Sugerencia</h2>
        <p class="text-muted small mb-0">
            Explore las <a href="<%=ctx%>/propiedades.jsp">propiedades disponibles</a>. Desde la ficha de detalle puede
            agendar una visita o agregar propiedades a sus favoritos.
        </p>
    </div>
</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>