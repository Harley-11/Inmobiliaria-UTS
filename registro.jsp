<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 registro.jsp - Pagina publica de autocadastro de cuentas.
 El registro publico SOLO crea cuentas con rol "cliente"; los roles
 "inmobiliaria" y "administrador" los asigna un administrador desde
 su panel. Envia un POST a guardar_registro.jsp. Cuando se reenvia
 (forward) con errores, conserva los valores ya escritos a traves de
 los parametros de la request.
--%>
<%
  String ctx = request.getContextPath();
  String tituloPagina = "Crear cuenta";

  String errorReg = (String) request.getAttribute("error");

  String vNombre     = request.getParameter("nombres");
  String vApellidos  = request.getParameter("apellidos");
  String vDocumento  = request.getParameter("documento");
  String vTelefono   = request.getParameter("telefono");
  String vDireccion  = request.getParameter("direccion");
  String vCorreo     = request.getParameter("correo");
  if (vNombre    == null) vNombre    = "";
  if (vApellidos == null) vApellidos = "";
  if (vDocumento == null) vDocumento = "";
  if (vTelefono  == null) vTelefono  = "";
  if (vDireccion == null) vDireccion = "";
  if (vCorreo    == null) vCorreo    = "";
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="row justify-content-center">
    <div class="col-md-8 col-lg-6">
        <div class="card ims-card shadow-lg p-4 p-md-5">

            <h1 class="h4 fw-bold mb-1">Crear una cuenta</h1>
            <p class="text-muted mb-4">Complete los campos obligatorios para registrarse en la plataforma.</p>

            <% if (errorReg != null) { %>
                <div class="alert alert-danger rounded-4">
                    <i class="bi bi-exclamation-triangle me-1"></i>
                    <%=errorReg%>
                </div>
            <% } %>

            <form action="<%=ctx%>/guardar_registro.jsp" method="post" onsubmit="return validarRegistro();">
                <div class="row g-3 mb-3">
                    <div class="col-md-6">
                        <label class="form-label" for="nombres">Nombres <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="nombres" name="nombres"
                               value="<%=esc(vNombre)%>" required maxlength="60">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="apellidos">Apellidos <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="apellidos" name="apellidos"
                               value="<%=esc(vApellidos)%>" required maxlength="60">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="documento">Numero de documento <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="documento" name="documento"
                               value="<%=esc(vDocumento)%>" required maxlength="20">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="telefono">Telefono <span class="text-muted fw-normal">(opcional)</span></label>
                        <input type="text" class="form-control" id="telefono" name="telefono"
                               value="<%=esc(vTelefono)%>" maxlength="15">
                    </div>
                    <div class="col-12">
                        <label class="form-label" for="direccion">Direccion <span class="text-muted fw-normal">(opcional)</span></label>
                        <input type="text" class="form-control" id="direccion" name="direccion"
                               value="<%=esc(vDireccion)%>" maxlength="150">
                    </div>
                    <div class="col-12">
                        <label class="form-label" for="correo">Correo electronico <span class="text-danger">*</span></label>
                        <input type="email" class="form-control" id="correo" name="correo"
                               value="<%=esc(vCorreo)%>" placeholder="usuario@correo.com"
                               autocomplete="email" required maxlength="100">
                    </div>
                    <div class="col-12">
                        <div class="alert alert-info rounded-4 py-2 mb-0 small">
                            <i class="bi bi-info-circle me-1"></i>
                            El registro publico crea una cuenta de tipo <strong>cliente</strong>.
                            Los roles de inmobiliaria y administrador los asigna un administrador
                            desde su panel.
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="clave">Clave <span class="text-danger">*</span></label>
                        <input type="password" class="form-control" id="clave" name="clave"
                               autocomplete="new-password" required maxlength="100">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="confirmar_clave">Confirmar clave <span class="text-danger">*</span></label>
                        <input type="password" class="form-control" id="confirmar_clave" name="confirmar_clave"
                               autocomplete="new-password" required maxlength="100">
                    </div>
                </div>

                <button type="submit" class="btn ims-btn w-100 rounded-pill py-2">
                    <i class="bi bi-person-plus me-1"></i> Crear cuenta
                </button>
            </form>

            <hr class="my-4">
            <p class="text-center text-muted mb-0">
                Ya tiene cuenta? <a href="<%=ctx%>/login.jsp">Inicie sesion</a>
            </p>
        </div>
    </div>
</div>
<script>
function validarRegistro() {
    var clave = document.getElementById('clave').value;
    var confirmar = document.getElementById('confirmar_clave').value;
    if (clave !== confirmar) {
        alert('Las claves no coinciden.');
        return false;
    }
    return true;
}
</script>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>