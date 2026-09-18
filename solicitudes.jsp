<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 agente/solicitudes.jsp - Bandeja de solicitudes (compra/arriendo) recibidas
 sobre las propiedades de la inmobiliaria del agente conectado. Permite
 aprobar o rechazar cada solicitud pendiente (POST a solicitud_estado.jsp).
--%>
<%
  String[] rolesPermitidos = { "inmobiliaria" };
  String tituloPagina = "Bandeja de solicitudes";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  String okMsj = request.getParameter("ok");
  String errMsj = request.getParameter("err");

  int idInmobiliaria = 0;
  List<Object[]> solicitudes = new ArrayList<Object[]>();
  List<Object[]> documentos = new ArrayList<Object[]>();

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);

    if (idInmobiliaria > 0) {
      ps = con.prepareStatement(
          "SELECT s.id_solicitud, s.tipo, s.estado, s.fecha_solicitud, " +
          "p.titulo, p.id_propiedad, u.correo, per.nombres, per.apellidos, per.telefono " +
          "FROM solicitud s " +
          "JOIN propiedad p ON p.id_propiedad = s.id_propiedad AND p.id_inmobiliaria = ? " +
          "LEFT JOIN usuario u ON u.id_usuario = s.id_cliente " +
          "LEFT JOIN perfil per ON per.id_usuario = s.id_cliente " +
          "ORDER BY s.fecha_solicitud DESC");
      ps.setInt(1, idInmobiliaria);
      rs = ps.executeQuery();
      while (rs.next()) solicitudes.add(new Object[]{
          Integer.valueOf(rs.getInt(1)), rs.getString(2), rs.getString(3),
          rs.getString(4), rs.getString(5), Integer.valueOf(rs.getInt(6)),
          rs.getString(7), rs.getString(8), rs.getString(9), rs.getString(10)});

      if (!solicitudes.isEmpty()) {
        ps = con.prepareStatement(
            "SELECT id_solicitud, tipo_documento, url_archivo FROM documento_solicitud " +
            "WHERE id_solicitud IN (SELECT s.id_solicitud FROM solicitud s " +
            "JOIN propiedad p ON p.id_propiedad = s.id_propiedad AND p.id_inmobiliaria = ?) " +
            "ORDER BY id_solicitud, id_documento");
        ps.setInt(1, idInmobiliaria);
        rs = ps.executeQuery();
        while (rs.next()) documentos.add(new Object[]{
            Integer.valueOf(rs.getInt(1)), rs.getString(2), rs.getString(3)});
      }
    }
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudo cargar la bandeja.";
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Bandeja de solicitudes</h1>
        <p class="text-muted mb-0">Solicitudes de compra o arriendo sobre sus propiedades.</p>
    </div>
    <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/agente/panel.jsp"><i class="bi bi-arrow-left me-1"></i> Volver al panel</a>
</div>

<% if ("1".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Solicitud aprobada.</div>
<% } else if ("2".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Solicitud rechazada.</div>
<% } else if ("1".equals(errMsj)) { %>
    <div class="alert alert-warning rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Esa solicitud ya fue resuelta o no pertenece a su inmobiliaria.</div>
<% } else if ("2".equals(errMsj)) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>No se pudo actualizar la solicitud. Intente mas tarde.</div>
<% } else if (errMsj != null && !errMsj.trim().isEmpty()) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
<% } %>

<% if (idInmobiliaria <= 0) { %>
    <div class="alert alert-warning rounded-4">
        <i class="bi bi-exclamation-triangle me-1"></i>
        Su cuenta no tiene una inmobiliaria asociada en el sistema.
    </div>
<% } else if (solicitudes.isEmpty()) { %>
    <p class="text-center text-muted py-5"><i class="bi bi-inbox me-1"></i>No tiene solicitudes recibidas.</p>
<% } else { %>
<div class="table-responsive">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th scope="col">Fecha</th>
                <th scope="col">Propiedad</th>
                <th scope="col">Cliente</th>
                <th scope="col">Tipo</th>
                <th scope="col">Estado</th>
                <th scope="col">Documentos</th>
                <th scope="col" class="text-end">Acciones</th>
            </tr>
        </thead>
        <tbody>
        <% for (Object[] s : solicitudes) {
            int idSol = ((Integer) s[0]).intValue();
            String tipoS = (String) s[1];
            String estadoS = (String) s[2];
            String fechaS = (String) s[3];
            String tituloS = (String) s[4];
            int idPro = ((Integer) s[5]).intValue();
            String correoC = (String) s[6];
            String nombresC = (String) s[7];
            String apellidosC = (String) s[8];
            String telefonoC = (String) s[9];
            String nombreCliente = (nombresC != null ? nombresC + (apellidosC != null ? " " + apellidosC : "") : (correoC != null ? correoC : "Cliente"));
        %>
            <tr>
                <td class="text-nowrap text-muted small"><%=esc(fechaS)%></td>
                <td><a class="text-decoration-none" href="<%=ctx%>/propiedad.jsp?id=<%=idPro%>"><%=esc(tituloS)%></a></td>
                <td>
                    <div class="fw-semibold"><%=esc(nombreCliente)%></div>
                    <div class="small text-muted"><%=esc(correoC)%><% if (telefonoC != null && !telefonoC.isEmpty()) { %> &middot; <%=esc(telefonoC)%><% } %></div>
                </td>
                <td><span class="badge text-bg-<%=colorEstado(tipoS)%> fw-semibold"><%=esc(tipoS)%></span></td>
                <td><span class="badge text-bg-<%=colorEstado(estadoS)%> fw-semibold"><%=esc(estadoS)%></span></td>
                <td>
                <% boolean hayDocs = false;
                    for (Object[] d : documentos) {
                        if (((Integer) d[0]).intValue() == idSol) {
                            hayDocs = true; %>
                    <a class="small text-decoration-none d-block" href="<%=ctx%>/<%=esc((String) d[2])%>" target="_blank" rel="noopener">
                        <i class="bi bi-file-earmark me-1"></i><%=esc((String) d[1])%>
                    </a>
                <%    }
                    }
                    if (!hayDocs) { %><span class="text-muted small">Sin documentos</span><% } %>
                </td>
                <td class="text-end text-nowrap">
                <% if ("pendiente".equals(estadoS)) { %>
                    <form class="d-inline" action="<%=ctx%>/agente/solicitud_estado.jsp" method="post">
                        <input type="hidden" name="id_solicitud" value="<%=idSol%>">
                        <input type="hidden" name="accion" value="aprobar">
                        <button class="btn btn-sm btn-success rounded-pill px-3" type="submit"><i class="bi bi-check-lg me-1"></i>Aprobar</button>
                    </form>
                    <form class="d-inline" action="<%=ctx%>/agente/solicitud_estado.jsp" method="post">
                        <input type="hidden" name="id_solicitud" value="<%=idSol%>">
                        <input type="hidden" name="accion" value="rechazar">
                        <button class="btn btn-sm btn-outline-danger rounded-pill px-3" type="submit"><i class="bi bi-x-lg me-1"></i>Rechazar</button>
                    </form>
                <% } else { %>
                    <span class="text-muted small">Resuelta</span>
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