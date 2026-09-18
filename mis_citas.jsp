<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 cliente/mis_citas.jsp - Listado de citas (visitas) del cliente conectado,
 con opcion de cancelar las pendientes. Queries solo sobre id_cliente = sesion.
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

  List<Object[]> citas = new ArrayList<Object[]>();
  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    ps = con.prepareStatement(
        "SELECT c.id_cita, c.fecha_hora, c.estado, p.titulo, p.id_propiedad " +
        "FROM cita c JOIN propiedad p ON p.id_propiedad = c.id_propiedad " +
        "WHERE c.id_cliente = ? ORDER BY c.fecha_hora DESC");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    while (rs.next()) citas.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2), rs.getString(3),
        rs.getString(4), Integer.valueOf(rs.getInt(5))});
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudo cargar sus citas.";
  } finally {
    cerrar(rs, ps, con);
  }

  String tituloPagina = "Mis citas";
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Mis citas</h1>
        <p class="text-muted mb-0">Visitas agendadas a propiedades.</p>
    </div>
    <a class="btn ims-btn rounded-pill px-4" href="<%=ctx%>/propiedades.jsp"><i class="bi bi-search me-1"></i> Buscar propiedades</a>
</div>

<% if ("1".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Cita agendada correctamente.</div>
<% } %>
<% if ("1".equals(errMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Cita cancelada.</div>
<% } else if (errMsj != null && !errMsj.trim().isEmpty()) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
<% } %>

<% if (citas.isEmpty()) { %>
    <p class="text-center text-muted py-5"><i class="bi bi-calendar-x me-1"></i>No tiene citas agendadas.</p>
<% } else { %>
<div class="table-responsive">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th scope="col">Propiedad</th>
                <th scope="col">Fecha y hora</th>
                <th scope="col">Estado</th>
                <th scope="col" class="text-end">Acciones</th>
            </tr>
        </thead>
        <tbody>
        <% for (Object[] c : citas) {
            int idCita = ((Integer) c[0]).intValue();
            String fechaHora = (String) c[1];
            String estadoC = (String) c[2];
            String tituloC = (String) c[3];
            int idPro = ((Integer) c[4]).intValue();
        %>
            <tr>
                <td><a class="text-decoration-none" href="<%=ctx%>/propiedad.jsp?id=<%=idPro%>"><%=esc(tituloC)%></a></td>
                <td><%=esc(fechaHora)%></td>
                <td><span class="badge text-bg-<%=colorEstado(estadoC)%> fw-semibold"><%=esc(estadoC)%></span></td>
                <td class="text-end text-nowrap">
                    <% if ("pendiente".equals(estadoC)) { %>
                    <form method="post" action="<%=ctx%>/cliente/cita_cancelar.jsp" class="d-inline">
                        <input type="hidden" name="id" value="<%=idCita%>">
                        <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill"><i class="bi bi-x-circle me-1"></i> Cancelar</button>
                    </form>
                    <% } else { %>
                    <span class="text-muted small">-</span>
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