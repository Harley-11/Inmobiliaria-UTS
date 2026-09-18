<%--
 acceso-denegado.jsp - Pagina publica mostrada por SeguridadFilter cuando
 el usuario (o visitante anonimo) no tiene permiso sobre una ruta privada.
 Parametros de la URL:
   ?motivo=sesion  -> no hay sesion activa (no autenticado)
   ?motivo=rol     -> sesion activa pero el rol no corresponde
                      (opcional &rol=... para mostrar cual se exigia)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLDecoder" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
  String ctx = request.getContextPath();
  String motivo = request.getParameter("motivo");
  String rolExigido = request.getParameter("rol");

  String titulo, mensaje, icono, alerta;
  if ("rol".equals(motivo)) {
    titulo  = "Acceso denegado por rol";
    mensaje = "Su sesion esta activa, pero su rol no tiene permiso sobre esta "
            + "secci&oacute;n.";
    icono   = "bi-shield-exclamation";
    alerta  = "warning";
  } else {
    motivo  = "sesion";
    titulo  = "Debe iniciar sesi&oacute;n";
    mensaje = "Para entrar en esta secci&oacute;n necesita autenticarse primero.";
    icono   = "bi-box-arrow-in-right";
    alerta  = "info";
  }
  boolean haySesion = session.getAttribute("idUsuario") != null;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Acceso denegado | Inmobiliaria UTS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="<%=ctx%>/css/estilos.css" rel="stylesheet">
</head>
<body class="ims-body d-flex align-items-center py-5">
<div class="container" style="max-width: 560px;">
    <div class="card ims-card shadow-lg p-4 p-md-5 text-center">
        <span class="display-5 ims-acento"><i class="bi <%=icono%>"></i></span>
        <h1 class="h4 fw-bold mt-3 mb-1"><%=titulo%></h1>
        <p class="text-muted"><%=mensaje%></p>

        <% if ("sesion".equals(motivo) && !haySesion) { %>
            <div class="alert alert-info rounded-4">
                <i class="bi bi-info-circle"></i>
                El filtro de seguridad lo redirigi&oacute; antes de cargar la p&aacute;gina solicitada.
            </div>
        <% } %>

        <% if (rolExigido != null && !rolExigido.isEmpty()) { %>
            <div class="alert alert-warning rounded-4">
                <i class="bi bi-shield-lock"></i>
                Se requiere el rol <strong><%=esc(rolExigido)%></strong>
                <span class="text-muted">(usted tiene: <%=haySesion ? esc((String) session.getAttribute("rol")) : "ninguna sesi&oacute;n"%>)</span>
            </div>
        <% } %>

        <div class="d-grid gap-2 d-sm-flex justify-content-sm-center mt-4">
            <% if ("sesion".equals(motivo) && !haySesion) { %>
                <a class="btn ims-btn rounded-pill px-4" href="<%=ctx%>/login.jsp"><i class="bi bi-box-arrow-in-right"></i> Iniciar sesi&oacute;n</a>
            <% } %>
            <% if (haySesion) { %>
                <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/logout.jsp"><i class="bi bi-arrow-return-left"></i> Volver al inicio</a>
            <% } %>
            <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/index.jsp"><i class="bi bi-house"></i> Ir al inicio</a>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>