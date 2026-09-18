<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 cliente/perfil.jsp - Completa o edita el perfil 1:1 del cliente conectado
 (tabla perfil con UNIQUE id_usuario). Envia POST a perfil_guardar.jsp.
 Params: ok=1 (guardado), err=datos (faltan datos obligatorios).
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

  String correoSesion = (String) session.getAttribute("correo");
  String vNombres = "";
  String vApellidos = "";
  String vDocumento = "";
  String vTelefono = "";
  String vDireccion = "";
  String vFoto = "";

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    ps = con.prepareStatement(
        "SELECT nombres, apellidos, documento, telefono, direccion, foto FROM perfil WHERE id_usuario = ?");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    if (rs.next()) {
      vNombres = rs.getString(1);
      vApellidos = rs.getString(2);
      vDocumento = rs.getString(3);
      vTelefono = rs.getString(4);
      vDireccion = rs.getString(5);
      vFoto = rs.getString(6);
    }
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudo cargar su perfil.";
  } finally {
    cerrar(rs, ps, con);
  }

  String tituloPagina = "Mi perfil";
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="row justify-content-center">
    <div class="col-lg-8">
        <div class="card ims-card shadow-lg">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-person-vcard me-1"></i> Mi perfil</div>
            <div class="card-body">
                <% if ("1".equals(okMsj)) { %>
                    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Perfil guardado correctamente.</div>
                <% } %>
                <% if ("datos".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Complete los campos obligatorios.</div>
                <% } else if ("servidor".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>No se pudo guardar el perfil. Intente mas tarde.</div>
                <% } %>

                <form action="<%=ctx%>/cliente/perfil_guardar.jsp" method="post">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label" for="nombres">Nombres *</label>
                            <input type="text" class="form-control" id="nombres" name="nombres" maxlength="60"
                                   value="<%=esc(vNombres)%>" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label" for="apellidos">Apellidos *</label>
                            <input type="text" class="form-control" id="apellidos" name="apellidos" maxlength="60"
                                   value="<%=esc(vApellidos)%>" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label" for="documento">Documento *</label>
                            <input type="text" class="form-control" id="documento" name="documento" maxlength="20"
                                   value="<%=esc(vDocumento)%>" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label" for="telefono">Telefono</label>
                            <input type="text" class="form-control" id="telefono" name="telefono" maxlength="15"
                                   value="<%=esc(vTelefono)%>" placeholder="3001234567">
                        </div>
                        <div class="col-12">
                            <label class="form-label" for="direccion">Direccion de contacto</label>
                            <input type="text" class="form-control" id="direccion" name="direccion" maxlength="150"
                                   value="<%=esc(vDireccion)%>" placeholder="Calle 48 # 29-14, Cabecera">
                        </div>
                        <div class="col-12">
                            <label class="form-label" for="foto">URL de la foto de perfil</label>
                            <input type="url" class="form-control" id="foto" name="foto" maxlength="255"
                                   value="<%=esc(vFoto)%>" placeholder="https://.../foto.jpg">
                        </div>
                    </div>
                    <div class="alert alert-light border rounded-4 small text-muted mt-3 mb-0">
                        <i class="bi bi-envelope me-1"></i>Correo de la cuenta (no editable): <strong><%=esc(correoSesion)%></strong>
                    </div>
                    <div class="d-flex gap-2 mt-3">
                        <button type="submit" class="btn ims-btn rounded-pill px-4"><i class="bi bi-save me-1"></i> Guardar perfil</button>
                        <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/cliente/panel.jsp"><i class="bi bi-x-circle me-1"></i> Cancelar</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>