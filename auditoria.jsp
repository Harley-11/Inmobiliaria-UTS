<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 admin/auditoria.jsp - Consulta de auditoria: listado filtrable de la tabla
 auditoria por usuario, tipo de accion y rango de fechas. Construye el WHERE
 dinamicamente con PreparedStatement (sin concatenar valores en el SQL).
 Muestra las ultimas coincidencias (descendente por fecha, limite 500).
--%>
<%
  String[] rolesPermitidos = { "administrador" };
  String tituloPagina = "Auditoria";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  String fUsuario = request.getParameter("f_usuario"); // "" = todos
  String fAccion  = request.getParameter("f_accion");  // "" = todas
  String fDesde   = request.getParameter("f_desde");   // yyyy-MM-dd
  String fHasta   = request.getParameter("f_hasta");   // yyyy-MM-dd

  List<Object[]> filas = new ArrayList<Object[]>();
  List<Object[]> usuariosFiltro = new ArrayList<Object[]>();
  List<String> accionesFiltro = new ArrayList<String>();
  String errorAuditoria = null;

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();

    // Opciones del filtro de usuario (solo quienes tienen registros).
    ps = con.prepareStatement(
        "SELECT DISTINCT a.id_usuario, u.correo, COALESCE(per.nombres,''), COALESCE(per.apellidos,'') " +
        "FROM auditoria a JOIN usuario u ON u.id_usuario = a.id_usuario " +
        "LEFT JOIN perfil per ON per.id_usuario = u.id_usuario " +
        "ORDER BY u.correo");
    rs = ps.executeQuery();
    while (rs.next()) usuariosFiltro.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2), rs.getString(3), rs.getString(4)});
    cerrar(rs, ps);

    // Opciones del filtro de accion.
    ps = con.prepareStatement("SELECT DISTINCT accion FROM auditoria ORDER BY accion");
    rs = ps.executeQuery();
    while (rs.next()) accionesFiltro.add(rs.getString(1));
    cerrar(rs, ps);

    // Consulta con filtros opcionales.
    StringBuilder sql = new StringBuilder(
        "SELECT a.id_auditoria, a.id_usuario, u.correo, " +
        "COALESCE(per.nombres,''), COALESCE(per.apellidos,''), " +
        "a.accion, a.fecha_hora, COALESCE(a.detalle, '') " +
        "FROM auditoria a " +
        "JOIN usuario u ON u.id_usuario = a.id_usuario " +
        "LEFT JOIN perfil per ON per.id_usuario = u.id_usuario " +
        "WHERE 1 = 1");
    List<Object> valores = new ArrayList<Object>();

    if (fUsuario != null && !fUsuario.trim().isEmpty()) {
      sql.append(" AND a.id_usuario = ?");
      valores.add(Integer.valueOf(aEntero(fUsuario, 0)));
    }
    if (fAccion != null && !fAccion.trim().isEmpty()) {
      sql.append(" AND a.accion = ?");
      valores.add(fAccion.trim());
    }
    if (fDesde != null && !fDesde.trim().isEmpty()) {
      sql.append(" AND DATE(a.fecha_hora) >= ?");
      valores.add(fDesde.trim());
    }
    if (fHasta != null && !fHasta.trim().isEmpty()) {
      sql.append(" AND DATE(a.fecha_hora) <= ?");
      valores.add(fHasta.trim());
    }
    sql.append(" ORDER BY a.fecha_hora DESC, a.id_auditoria DESC LIMIT 500");

    ps = con.prepareStatement(sql.toString());
    for (int i = 0; i < valores.size(); i++) {
      ps.setObject(i + 1, valores.get(i));
    }
    rs = ps.executeQuery();
    while (rs.next()) filas.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), Integer.valueOf(rs.getInt(2)), rs.getString(3),
        rs.getString(4), rs.getString(5), rs.getString(6), rs.getString(7), rs.getString(8)});
  } catch (Exception e) {
    e.printStackTrace();
    errorAuditoria = "No se pudo cargar la auditoria.";
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Consulta de auditoria</h1>
        <p class="text-muted mb-0">Trazabilidad de acciones en el sistema (tabla auditoria).</p>
    </div>
    <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/admin/panel.jsp"><i class="bi bi-arrow-left me-1"></i> Volver</a>
</div>

<% if (errorAuditoria != null) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=errorAuditoria%></div>
<% } %>

<div class="card ims-card shadow-sm mb-4">
    <div class="card-body">
        <form class="row g-2 align-items-end" method="get" action="<%=ctx%>/admin/auditoria.jsp">
            <div class="col-md-3">
                <label class="form-label small text-muted" for="f_usuario">Usuario</label>
                <select class="form-select" id="f_usuario" name="f_usuario">
                    <option value="">Todos</option>
                <% for (Object[] uf : usuariosFiltro) {
                    String nombreF = (((String) uf[2]).trim() + " " + ((String) uf[3]).trim()).trim();
                    String etiqueta = nombreF.isEmpty() ? (String) uf[1] : nombreF + " (" + (String) uf[1] + ")"; %>
                    <option value="<%=((Integer) uf[0]).intValue()%>" <%= String.valueOf(((Integer) uf[0]).intValue()).equals(fUsuario) ? "selected" : "" %>><%=esc(etiqueta)%></option>
                <% } %>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label small text-muted" for="f_accion">Tipo de accion</label>
                <select class="form-select" id="f_accion" name="f_accion">
                    <option value="">Todas</option>
                <% for (String acc : accionesFiltro) { %>
                    <option value="<%=esc(acc)%>" <%= acc.equals(fAccion) ? "selected" : "" %>><%=esc(acc)%></option>
                <% } %>
                </select>
            </div>
            <div class="col-md-2">
                <label class="form-label small text-muted" for="f_desde">Desde</label>
                <input class="form-control" type="date" id="f_desde" name="f_desde" value="<%=esc(fDesde)%>">
            </div>
            <div class="col-md-2">
                <label class="form-label small text-muted" for="f_hasta">Hasta</label>
                <input class="form-control" type="date" id="f_hasta" name="f_hasta" value="<%=esc(fHasta)%>">
            </div>
            <div class="col-md-2 d-flex gap-2">
                <button class="btn ims-btn rounded-pill px-4 flex-fill" type="submit"><i class="bi bi-funnel me-1"></i>Filtrar</button>
                <a class="btn btn-outline-secondary rounded-pill px-3" href="<%=ctx%>/admin/auditoria.jsp" title="Limpiar filtros"><i class="bi bi-x-lg"></i></a>
            </div>
        </form>
    </div>
</div>

<% if (filas.isEmpty()) { %>
    <p class="text-center text-muted py-5"><i class="bi bi-journal-x me-1"></i>No hay registros de auditoria con esos filtros.</p>
<% } else { %>
<div class="table-responsive">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th scope="col">Hora</th>
                <th scope="col">Usuario</th>
                <th scope="col">Accion</th>
                <th scope="col">Detalle</th>
            </tr>
        </thead>
        <tbody>
        <% for (Object[] a : filas) {
            String nombreU = (((String) a[3]).trim() + " " + ((String) a[4]).trim()).trim();
            if (nombreU.isEmpty()) nombreU = (String) a[2];
        %>
            <tr>
                <td class="text-nowrap text-muted small"><%=esc((String) a[6])%></td>
                <td>
                    <div class="fw-semibold"><%=esc(nombreU)%></div>
                    <div class="small text-muted">#<%=((Integer) a[1]).intValue()%> &middot; <%=esc((String) a[2])%></div>
                </td>
                <td><span class="badge text-bg-secondary fw-semibold"><%=esc((String) a[5])%></span></td>
                <td class="small"><%=esc((String) a[7])%></td>
            </tr>
        <% } %>
        </tbody>
    </table>
</div>
<p class="text-muted small mb-0">Se muestran hasta 500 registros, del mas reciente al mas antiguo.</p>
<% } %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>