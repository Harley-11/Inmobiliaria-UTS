<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 login.jsp - Pagina publica de inicio de sesion.
 Parametros opcionales de la URL:
   ?error=sesion       -> se intento entrar a una seccion privada sin sesion
   ?error=permiso      -> el rol no tiene permiso sobre esa seccion
   ?error=credenciales -> correo o clave incorrectos
   ?error=inactivo     -> el usuario esta inactivo
   ?error=servidor     -> error interno al validar
   ?exito=1            -> registro recien completado
   &correo=...         -> prellenar el campo correo
 Envia un POST a acceso.jsp con los campos correo y clave.
--%>
<%
  String ctx = request.getContextPath();
  String tituloPagina = "Iniciar sesion";

  String error = request.getParameter("error");
  String exito = request.getParameter("exito");
  String correoPrefill = request.getParameter("correo");

  String msjAlerta = null;
  String tipoAlerta = "danger";
  if ("sesion".equals(error)) {
    msjAlerta = "Debe iniciar sesion para acceder a esa seccion.";
    tipoAlerta = "warning";
  } else if ("permiso".equals(error)) {
    msjAlerta = "Su sesion esta activa, pero su rol no tiene permiso sobre esa seccion.";
    tipoAlerta = "warning";
  } else if ("credenciales".equals(error)) {
    msjAlerta = "Correo o clave incorrectos.";
  } else if ("inactivo".equals(error)) {
    msjAlerta = "El usuario esta inactivo. Contacte al administrador.";
  } else if ("servidor".equals(error)) {
    msjAlerta = "No se pudo validar el acceso en este momento. Intente mas tarde.";
  } else if ("visita".equals(error)) {
    msjAlerta = "Inicie sesion como cliente para poder agendar una visita.";
    tipoAlerta = "warning";
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="row justify-content-center">
    <div class="col-md-6 col-lg-5">
        <div class="card ims-card shadow-lg p-4 p-md-5">

            <h1 class="h4 fw-bold mb-1">Bienvenido de nuevo</h1>
            <p class="text-muted mb-4">Ingrese sus credenciales para entrar a su panel.</p>

            <% if ("1".equals(exito)) { %>
                <div class="alert alert-success rounded-4">
                    <i class="bi bi-check-circle me-1"></i>
                    Registro exitoso. Ya puede iniciar sesion.
                </div>
            <% } %>

            <% if (msjAlerta != null) { %>
                <div class="alert alert-<%=tipoAlerta%> rounded-4">
                    <i class="bi bi-shield-exclamation me-1"></i>
                    <%=msjAlerta%>
                </div>
            <% } %>

            <form action="<%=ctx%>/acceso.jsp" method="post" autocomplete="on">
                <div class="mb-3">
                    <label class="form-label" for="correo">Correo electronico</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                        <input type="email" class="form-control" id="correo" name="correo"
                               value="<%=esc(correoPrefill)%>" placeholder="usuario@correo.com"
                               autocomplete="username" required autofocus>
                    </div>
                </div>
                <div class="mb-4">
                    <label class="form-label" for="clave">Clave</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-key"></i></span>
                        <input type="password" class="form-control" id="clave" name="clave"
                               placeholder="Su clave" autocomplete="current-password" required>
                    </div>
                </div>
                <button type="submit" class="btn ims-btn w-100 rounded-pill py-2">
                    <i class="bi bi-box-arrow-in-right me-1"></i> Iniciar sesion
                </button>
            </form>

            <hr class="my-4">
            <p class="text-center text-muted mb-0">
                No tiene cuenta? <a href="<%=ctx%>/registro.jsp">Registrese aqui</a>
            </p>
        </div>
    </div>
</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>