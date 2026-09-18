<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 cliente/solicitar_solicitud.jsp - Formulario para radicar una solicitud de
 compra o arriendo sobre una propiedad disponible. Permite adjuntar hasta 3
 documentos (documento_solicitud: tipo_documento + url_archivo).
 Envia POST multipart a guardar_solicitud.jsp. Params: propiedad=<id>, err=...
--%>
<%
  String[] rolesPermitidos = { "cliente" };
  String tituloPagina = "Solicitar compra o arriendo";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idProp = aEntero(request.getParameter("propiedad"), 0);
  String errMsj = request.getParameter("err");

  String tituloPropiedad = null;
  double precioPropiedad = 0;
  String estadoPropiedad = null;
  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    ps = con.prepareStatement(
        "SELECT titulo, precio, estado FROM propiedad WHERE id_propiedad = ? AND estado = 'disponible'");
    ps.setInt(1, idProp);
    rs = ps.executeQuery();
    if (rs.next()) {
      tituloPropiedad = rs.getString(1);
      precioPropiedad = rs.getDouble(2);
      estadoPropiedad = rs.getString(3);
    }
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
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="row justify-content-center">
    <div class="col-lg-9">
        <div class="card ims-card shadow-lg">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-file-earmark-text me-1"></i> Solicitud de compra o arriendo</div>
            <div class="card-body">
                <div class="alert alert-light border rounded-4">
                    <div class="fw-semibold"><%=esc(tituloPropiedad)%></div>
                    <div class="small text-muted">
                        <%=pesos(precioPropiedad)%> &middot; Estado: <span class="badge text-bg-<%=colorEstado(estadoPropiedad)%> fw-semibold"><%=esc(estadoPropiedad)%></span>
                    </div>
                    <div class="small text-muted mt-1">Adjunte al menos un documento de soporte (certificado de ingresos, extracto, cedula, etc.). La solicitud quedara con estado <strong>pendiente</strong>.</div>
                </div>

                <% if ("tipo".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Seleccione un tipo de solicitud valido (compra o arriendo).</div>
                <% } else if ("archivo".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Adjunte al menos un documento valido (PDF, imagen o documento de Office).</div>
                <% } else if ("servidor".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>No se pudo radicar la solicitud. Intente mas tarde.</div>
                <% } else if ("duplicado".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Ya tienes una solicitud <strong>pendiente</strong> de <%=esc("compra".equals(request.getParameter("tipo")) ? "compra" : "arriendo")%> para esta propiedad. Espera a que sea resuelta antes de radicar otra.</div>
                <% } else if (errMsj != null && !errMsj.trim().isEmpty()) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
                <% } %>

                <form action="<%=ctx%>/cliente/guardar_solicitud.jsp" method="post" enctype="multipart/form-data">
                    <input type="hidden" name="propiedad" value="<%=idProp%>">
                    <div class="mb-3">
                        <label class="form-label" for="tipo">Tipo de solicitud *</label>
                        <select class="form-select" id="tipo" name="tipo" required>
                            <option value="compra">Compra</option>
                            <option value="arriendo">Arriendo</option>
                        </select>
                    </div>

                    <h2 class="h6 fw-bold mt-4 mb-3"><i class="bi bi-paperclip me-1"></i> Documentos de soporte (minimo 1)</h2>
                    <% for (int i = 1; i <= 3; i++) { %>
                    <div class="row g-2 align-items-end mb-3">
                        <div class="col-md-4">
                            <label class="form-label small mb-1" for="tipo_documento<%=i%>">Tipo de documento <%=i%></label>
                            <select class="form-select form-select-sm" id="tipo_documento<%=i%>" name="tipo_documento<%=i%>">
                                <option value="">Seleccione...</option>
                                <option value="Cedula de ciudadania">Cedula de ciudadania</option>
                                <option value="Certificado laboral">Certificado laboral</option>
                                <option value="Extracto bancario">Extracto bancario</option>
                                <option value="Declaracion de renta">Declaracion de renta</option>
                                <option value="Otro documento">Otro documento</option>
                            </select>
                        </div>
                        <div class="col-md-8">
                            <label class="form-label small mb-1" for="archivo<%=i%>">Archivo <%=i%></label>
                            <input type="file" class="form-control form-control-sm" id="archivo<%=i%>" name="archivo<%=i%>"
                                   accept=".pdf,.jpg,.jpeg,.png,.webp,.gif,.doc,.docx,.txt">
                        </div>
                    </div>
                    <% } %>

                    <div class="d-flex gap-2 mt-4">
                        <button type="submit" class="btn ims-btn rounded-pill px-4"><i class="bi bi-send me-1"></i> Radicar solicitud</button>
                        <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/propiedad.jsp?id=<%=idProp%>"><i class="bi bi-x-circle me-1"></i> Cancelar</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>