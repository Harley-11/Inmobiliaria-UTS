<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 cliente/solicitar_visita.jsp - Formulario para agendar una visita (cita)
 a una propiedad disponible. Accion exclusiva del rol cliente (protegida).
 Envia POST a guardar_cita.jsp. Params: propiedad=<id>, err=...
--%>
<%
  String[] rolesPermitidos = { "cliente" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idProp = aEntero(request.getParameter("propiedad"), 0);
  String errMsj = request.getParameter("err");

  String tituloPropiedad = null;
  String estadoPropiedad = null;
  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    ps = con.prepareStatement("SELECT titulo FROM propiedad WHERE id_propiedad = ? AND estado = 'disponible'");
    ps.setInt(1, idProp);
    rs = ps.executeQuery();
    if (rs.next()) tituloPropiedad = rs.getString(1);
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudo cargar la propiedad.";
  } finally {
    cerrar(rs, ps, con);
  }

  if (tituloPropiedad == null) {
    response.sendRedirect(ctx + "/propiedades.jsp");
    return;
  }

  String tituloPagina = "Agendar una visita";
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="row justify-content-center">
    <div class="col-lg-7">
        <div class="card ims-card shadow-lg">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-calendar-check me-1"></i> Agendar visita</div>
            <div class="card-body">
                <div class="alert alert-light border rounded-4">
                    <div class="fw-semibold"><%=esc(tituloPropiedad)%></div>
                    <div class="small text-muted">La cita quedara registrada con estado <strong>pendiente</strong> para que la inmobiliaria la confirme.</div>
                </div>

                <% if ("fecha".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Seleccione una fecha y hora valida.</div>
                <% } else if ("duplicada".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Esa propiedad ya tiene una visita agendada en ese horario. Elija otra fecha.</div>
                <% } else if (errMsj != null && !errMsj.trim().isEmpty()) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
                <% } %>

                <form action="<%=ctx%>/cliente/guardar_cita.jsp" method="post">
                    <input type="hidden" name="propiedad" value="<%=idProp%>">
                    <div class="mb-3">
                        <label class="form-label" for="fecha_hora">Fecha y hora de la visita *</label>
                        <input type="datetime-local" class="form-control" id="fecha_hora" name="fecha_hora" required>
                        <div class="form-text">Elija un momento futuro para la visita a la propiedad.</div>
                    </div>
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn ims-btn rounded-pill px-4"><i class="bi bi-calendar-plus me-1"></i> Agendar</button>
                        <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/propiedad.jsp?id=<%=idProp%>"><i class="bi bi-x-circle me-1"></i> Cancelar</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>