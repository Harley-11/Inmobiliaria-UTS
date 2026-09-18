<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 admin/usuarios.jsp - Administracion de cuentas: lista todos los usuarios con
 su rol(es), permite activar/inactivar la cuenta y asignar o revocar roles
 (tabla usuario_rol). Es la UNICA via para crear cuentas con rol de
 administrador o inmobiliaria, porque el registro publico siempre crea
 usuarios con rol cliente.
  - Toggle de estado: POST a usuario_estado.jsp
  - Gestion de roles (checkboxes rol_<id_rol>): POST a usuario_rol.jsp
  - Un administrador no puede quitarse su propio rol 'administrador'
    ni desactivar su propia cuenta (protegido tambien en las acciones).
--%>
<%
  String[] rolesPermitidos = { "administrador" };
  String tituloPagina = "Usuarios y roles";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  String okMsj = request.getParameter("ok");
  String errMsj = request.getParameter("err");

  List<Object[]> usuarios = new ArrayList<Object[]>();
  List<Object[]> roles = new ArrayList<Object[]>();

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();

    ps = con.prepareStatement(
        "SELECT u.id_usuario, u.correo, u.estado, u.fecha_registro, " +
        "COALESCE(per.nombres, ''), COALESCE(per.apellidos, ''), " +
        "COALESCE(per.documento, ''), " +
        "(SELECT GROUP_CONCAT(r.nombre_rol ORDER BY r.id_rol SEPARATOR ',') " +
        " FROM usuario_rol ur JOIN rol r ON r.id_rol = ur.id_rol " +
        " WHERE ur.id_usuario = u.id_usuario) AS roles_csv, " +
        "(SELECT i.id_inmobiliaria FROM inmobiliaria i " +
        " WHERE i.id_usuario = u.id_usuario) AS id_inmob " +
        "FROM usuario u " +
        "LEFT JOIN perfil per ON per.id_usuario = u.id_usuario " +
        "ORDER BY u.id_usuario");
    rs = ps.executeQuery();
    while (rs.next()) {
      usuarios.add(new Object[]{
          Integer.valueOf(rs.getInt(1)), rs.getString(2), rs.getString(3),
          rs.getString(4), rs.getString(5), rs.getString(6), rs.getString(7),
          rs.getString(8), rs.getObject(9)});
    }
    cerrar(rs, ps);

    ps = con.prepareStatement("SELECT id_rol, nombre_rol FROM rol ORDER BY id_rol");
    rs = ps.executeQuery();
    while (rs.next()) {
      roles.add(new Object[]{
          Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    }
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudo cargar el listado de usuarios.";
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<%
  int idRolInmobiliaria = -1;
  for (Object[] rol : roles) {
    if ("inmobiliaria".equalsIgnoreCase((String) rol[1])) {
      idRolInmobiliaria = ((Integer) rol[0]).intValue();
      break;
    }
  }
%>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Usuarios y roles</h1>
        <p class="text-muted mb-0">Cuentas del sistema, roles (usuario_rol) y estado.</p>
    </div>
    <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/admin/panel.jsp"><i class="bi bi-arrow-left me-1"></i> Volver</a>
</div>

<div class="alert alert-info rounded-4 small">
    <i class="bi bi-info-circle me-1"></i>
    Los usuarios que se registran desde el sector publico nacen con rol <strong>cliente</strong>.
    Esta es la &uacute;nica v&iacute;a para asignar los roles <strong>administrador</strong> o <strong>inmobiliaria</strong> a una cuenta.
    Al asignar <strong>inmobiliaria</strong> a alguien que aun no tiene registro, se crea la inmobiliaria
    (nombre comercial y NIT) en la misma operacion. Quitar el rol <strong>no</strong> borra la inmobiliaria
    ni sus propiedades: solo se desvincula la cuenta.
</div>

<% if ("1".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Roles del usuario actualizados.</div>
<% } else if ("2".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Estado de la cuenta actualizado.</div>
<% } else if ("3".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Rol de administrador revocado de la cuenta.</div>
<% } else if ("4".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Roles actualizados; la inmobiliaria del usuario se creo automaticamente.</div>
<% } %>

<% if ("1".equals(errMsj)) { %>
    <div class="alert alert-warning rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>El usuario no existe o el dato es invalido.</div>
<% } else if ("2".equals(errMsj)) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>No se pudo guardar el cambio. Intente mas tarde.</div>
<% } else if ("3".equals(errMsj)) { %>
    <div class="alert alert-warning rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>No puede quitarse a si mismo el rol administrador ni desactivar su propia cuenta.</div>
<% } else if ("4".equals(errMsj)) { %>
    <div class="alert alert-warning rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Un administrador no puede desactivar su propia cuenta.</div>
<% } else if ("5".equals(errMsj)) { %>
    <div class="alert alert-warning rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Para asignar el rol inmobiliaria, escriba el nombre comercial (y el NIT) de la inmobiliaria.</div>
<% } else if ("6".equals(errMsj)) { %>
    <div class="alert alert-warning rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Ese NIT ya corresponde a otra inmobiliaria registrada.</div>
<% } else if (errMsj != null && !errMsj.trim().isEmpty()) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
<% } %>

<% if (usuarios.isEmpty()) { %>
    <p class="text-center text-muted py-5"><i class="bi bi-people me-1"></i>No hay usuarios registrados.</p>
<% } else { %>
<div class="table-responsive">
    <table class="table table-hover align-middle">
        <thead class="table-light">
            <tr>
                <th scope="col">#</th>
                <th scope="col">Usuario</th>
                <th scope="col">Roles</th>
                <th scope="col">Estado</th>
                <th scope="col" class="text-end">Acciones</th>
            </tr>
        </thead>
        <tbody>
        <% for (Object[] u : usuarios) {
            int idU = ((Integer) u[0]).intValue();
            String correoU = (String) u[1];
            String estadoU = (String) u[2];
            String nombreU = ((String) u[4] + " " + (String) u[5]).trim();
            String docU = (String) u[6];
            String rolesCsvU = (String) u[7];
            Integer idInmobU = (Integer) u[8];
            boolean tieneInmobiliaria = (idInmobU != null);
            boolean esMiCuenta = (idU == idUsuario);
            boolean yaAdmin = tieneRol(rolesCsvU, "administrador");
        %>
            <tr>
                <td class="text-muted"><%=idU%></td>
                <td>
                    <div class="fw-semibold"><%=esc(nombreU.isEmpty() ? correoU : nombreU)%></div>
                    <div class="small text-muted"><%=esc(correoU)%><% if (!docU.isEmpty()) { %> &middot; <%=esc(docU)%><% } %></div>
                </td>
                <td>
                <% if (rolesCsvU == null || rolesCsvU.trim().isEmpty()) { %>
                    <span class="text-muted small">Sin roles</span>
                <% } else { %>
                    <% for (String r : rolesCsvU.split(",")) {
                        String rl = r.trim();
                        String cls = "administrador".equals(rl) ? "danger"
                                   : "inmobiliaria".equals(rl) ? "primary" : "info"; %>
                        <span class="badge text-bg-<%=cls%> fw-semibold me-1"><%=esc(rl)%></span>
                    <% } %>
                <% } %>
                </td>
                <td>
                    <span class="badge <%= "activo".equals(estadoU) ? "text-bg-success" : "text-bg-secondary" %> fw-semibold">
                        <%=esc(estadoU)%>
                    </span>
                </td>
                <td class="text-end text-nowrap">
                    <button class="btn btn-sm btn-outline-primary rounded-pill px-3" type="button"
                            data-bs-toggle="collapse" data-bs-target="#rolesUser<%=idU%>" aria-expanded="false"
                            aria-controls="rolesUser<%=idU%>"><i class="bi bi-person-gear me-1"></i>Roles</button>
                <% if (esMiCuenta) { %>
                    <span class="text-muted small ms-1" title="No puede desactivar su propia cuenta"><i class="bi bi-lock"></i></span>
                <% } else { %>
                    <form class="d-inline" action="<%=ctx%>/admin/usuario_estado.jsp" method="post">
                        <input type="hidden" name="id_usuario" value="<%=idU%>">
                        <input type="hidden" name="estado" value="<%= "activo".equals(estadoU) ? "inactivo" : "activo" %>">
                        <button class="btn btn-sm <%= "activo".equals(estadoU) ? "btn-outline-danger" : "btn-outline-success" %> rounded-pill px-3" type="submit">
                            <i class="bi <%= "activo".equals(estadoU) ? "bi-x-circle" : "bi-check-circle" %> me-1"></i>
                            <%= "activo".equals(estadoU) ? "Desactivar" : "Activar" %>
                        </button>
                    </form>
                <% } %>
                </td>
            </tr>
            <tr class="collapse" id="rolesUser<%=idU%>">
                <td colspan="5" class="bg-body-tertiary">
                    <form action="<%=ctx%>/admin/usuario_rol.jsp" method="post" class="d-flex flex-wrap align-items-center gap-2">
                        <input type="hidden" name="id_usuario" value="<%=idU%>">
                        <span class="fw-semibold small me-2">Roles para <%=esc(correoU)%>:</span>
                    <% for (Object[] r : roles) {
                        int idRol = ((Integer) r[0]).intValue();
                        String nomRol = (String) r[1];
                        boolean marcado = tieneRol(rolesCsvU, nomRol);
                        // Bloquear que el admin de la sesion se quite su propio rol administrador.
                        boolean bloqueado = esMiCuenta && "administrador".equals(nomRol);
                        boolean esInmob = "inmobiliaria".equals(nomRol);
                    %>
                        <div class="form-check form-switch form-check-inline ms-1">
                            <input class="form-check-input" type="checkbox" id="rol<%=idU%>_<%=idRol%>"
                                   name="rol_<%=idRol%>" value="1" <%= marcado ? "checked" : "" %> <%= bloqueado ? "disabled" : "" %>
                                   <%= esInmob && !tieneInmobiliaria ? "data-inmo=\"" + idU + "\"" : "" %>>
                            <label class="form-check-label small <%= bloqueado ? "text-secondary" : "" %>" for="rol<%=idU%>_<%=idRol%>">
                                <%=esc(nomRol)%><% if (bloqueado) { %> <i class="bi bi-lock small" title="Rol protegido de su propia cuenta"></i><% } %>
                            </label>
                        </div>
                    <% } %>
                    <% if (!tieneInmobiliaria && idRolInmobiliaria > 0) {
                           boolean marcadoInmo = tieneRol(rolesCsvU, "inmobiliaria"); %>
                        <div class="w-100"></div>
                        <div id="datosInmo<%=idU%>" class="row g-2 w-100 <%= marcadoInmo ? "" : "d-none" %>">
                            <div class="col-md-5">
                                <label class="form-label small mb-1" for="nc<%=idU%>">Nombre comercial (inmobiliaria)</label>
                                <input type="text" class="form-control form-control-sm" id="nc<%=idU%>" name="nombre_comercial" maxlength="100" placeholder="Ej. Inmobiliaria El Hogar">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label small mb-1" for="nit<%=idU%>">NIT</label>
                                <input type="text" class="form-control form-control-sm" id="nit<%=idU%>" name="nit" maxlength="20" placeholder="Ej. 901234567-1">
                            </div>
                            <div class="col-md-3 align-self-end">
                                <span class="small text-muted"><i class="bi bi-info-circle me-1"></i>Obligatorios si se asigna el rol.</span>
                            </div>
                        </div>
                    <% } %>
                        <button class="btn btn-sm ims-btn rounded-pill px-3 ms-auto" type="submit"><i class="bi bi-save me-1"></i>Guardar roles</button>
                    </form>
                </td>
            </tr>
        <% } %>
        </tbody>
    </table>
</div>
<% } %>
<script>
  // Muestra/oculta los datos de la inmobiliaria cuando se marca o desmarca
  // el rol "inmobiliaria" para un usuario que aun no tiene registro.
  function imsToggleInmobiliaria(idUsuario) {
    var cb = document.getElementById('rol' + idUsuario + '_<%=idRolInmobiliaria%>');
    var box = document.getElementById('datosInmo' + idUsuario);
    if (!cb || !box) return;
    box.classList.toggle('d-none', !cb.checked);
    var req = box.querySelector('input[name="nombre_comercial"]');
    if (req) {
      if (cb.checked) { req.setAttribute('required', 'required'); }
      else { req.removeAttribute('required'); }
    }
  }
  document.addEventListener('DOMContentLoaded', function () {
    var marcas = document.querySelectorAll('[data-inmo]');
    for (var i = 0; i < marcas.length; i++) {
      (function (uid) {
        marcas[i].addEventListener('change', function () { imsToggleInmobiliaria(uid); });
        imsToggleInmobiliaria(uid);
      })(marcas[i].getAttribute('data-inmo'));
    }
  });
</script>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>