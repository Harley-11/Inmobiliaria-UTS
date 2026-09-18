<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 cliente/mis_solicitudes.jsp - Listado (solo lectura) de las solicitudes
 (compra/arriendo) del cliente conectado, con su estado y los documentos
 adjuntos (link descargable). Nuevas solicitudes se radican desde la ficha
 de una propiedad (propiedad.jsp -> solicitar_solicitud.jsp).
--%>
<%
  String[] rolesPermitidos = { "cliente" };
  String tituloPagina = "Mis solicitudes";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  String okMsj = request.getParameter("ok");
  String errMsj = request.getParameter("err");

  List<Object[]> solicitudes = new ArrayList<Object[]>();
  java.util.Map<Integer, java.util.List<Object[]>> docsPorSolicitud =
      new java.util.HashMap<Integer, java.util.List<Object[]>>();

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    ps = con.prepareStatement(
        "SELECT s.id_solicitud, s.tipo, s.estado, s.fecha_solicitud, p.titulo, p.id_propiedad " +
        "FROM solicitud s JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
        "WHERE s.id_cliente = ? ORDER BY s.fecha_solicitud DESC");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    while (rs.next()) {
      int idSol = rs.getInt(1);
      solicitudes.add(new Object[]{
          Integer.valueOf(idSol), rs.getString(2), rs.getString(3),
          rs.getString(4), rs.getString(5), Integer.valueOf(rs.getInt(6))});

      java.util.List<Object[]> docs = new java.util.ArrayList<Object[]>();
      PreparedStatement ps2 = con.prepareStatement(
          "SELECT tipo_documento, url_archivo FROM documento_solicitud WHERE id_solicitud = ? ORDER BY id_documento");
      ps2.setInt(1, idSol);
      ResultSet rs2 = ps2.executeQuery();
      while (rs2.next()) docs.add(new Object[]{rs2.getString(1), rs2.getString(2)});
      cerrar(rs2, ps2);
      docsPorSolicitud.put(Integer.valueOf(idSol), docs);
    }
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudieron cargar sus solicitudes.";
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Mis solicitudes</h1>
        <p class="text-muted mb-0">Solicitudes de compra o arriendo y su estado.</p>
    </div>
    <a class="btn ims-btn rounded-pill px-4" href="<%=ctx%>/propiedades.jsp"><i class="bi bi-search me-1"></i> Buscar propiedad</a>
</div>

<% if ("1".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Solicitud radicada. La inmobiliaria la revisara.</div>
<% } %>
<% if (errMsj != null && !errMsj.trim().isEmpty()) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
<% } %>

<% if (solicitudes.isEmpty()) { %>
    <p class="text-center text-muted py-5"><i class="bi bi-file-earmark-x me-1"></i>No tiene solicitudes registradas. Use el boton "Solicitar compra o arriendo" en la ficha de una propiedad.</p>
<% } else { %>
<div class="table-responsive">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th scope="col">Propiedad</th>
                <th scope="col">Tipo</th>
                <th scope="col">Estado</th>
                <th scope="col">Fecha</th>
                <th scope="col">Documentos</th>
            </tr>
        </thead>
        <tbody>
        <% for (Object[] s : solicitudes) {
            int idSol = ((Integer) s[0]).intValue();
            String tipo = (String) s[1];
            String estadoS = (String) s[2];
            String fecha = (String) s[3];
            String tituloS = (String) s[4];
            int idPro = ((Integer) s[5]).intValue();
            java.util.List<Object[]> docs = docsPorSolicitud.get(Integer.valueOf(idSol));
        %>
            <tr>
                <td><a class="text-decoration-none" href="<%=ctx%>/propiedad.jsp?id=<%=idPro%>"><%=esc(tituloS)%></a></td>
                <td><span class="badge text-bg-<%=colorEstado(tipo)%> fw-semibold"><%=esc(tipo)%></span></td>
                <td><span class="badge text-bg-<%=colorEstado(estadoS)%> fw-semibold"><%=esc(estadoS)%></span></td>
                <td class="text-nowrap text-muted small"><%=esc(fecha)%></td>
                <td>
                <% if (docs == null || docs.isEmpty()) { %>
                    <span class="text-muted small">Sin documentos</span>
                <% } else {
                    for (Object[] d : docs) { %>
                    <a class="small text-decoration-none d-block" href="<%=ctx%>/<%=esc((String) d[1])%>" target="_blank" rel="noopener">
                        <i class="bi bi-file-earmark me-1"></i><%=esc((String) d[0])%>
                    </a>
                <%  } } %>
                </td>
            </tr>
        <% } %>
        </tbody>
    </table>
</div>
<% } %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>