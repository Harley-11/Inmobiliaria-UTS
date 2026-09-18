<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLEncoder" %>
<%--
 acceso.jsp - Recibe el POST de login.jsp y valida las credenciales.
 Usa PreparedStatement contra la tabla usuario, compara el hash
 (claveCifrada = SHA-256 "correo:clave"), guarda en sesion
 idUsuario, nombre, correo, rol (principal) y roles (CSV), y
 redirige al panel segun el rol.
 Auditoria (valor agregado): registra LOGIN en acceso exitoso y
 BLOQUEO_LOGIN en intentos fallidos (clave incorrecta o usuario
 inactivo). Para correos inexistentes no se audita porque la FK de
 auditoria.id_usuario exige un usuario real.
 No emite HTML: solo redirige.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
  request.setCharacterEncoding("UTF-8");
  String ctx = request.getContextPath();

  String correo = request.getParameter("correo");
  String clave  = request.getParameter("clave");
  String correoLimpio = (correo == null) ? "" : correo.trim().toLowerCase();

  String volverLogin = ctx + "/login.jsp?error=credenciales&correo="
                     + URLEncoder.encode(correoLimpio, "UTF-8");

  if (correoLimpio.isEmpty() || clave == null || clave.isEmpty()) {
    response.sendRedirect(volverLogin);
    return;
  }

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;

  try {
    con = abrirConexion();
    String sql =
        "SELECT u.id_usuario, u.estado, u.contrasena_hash, "
      + "COALESCE(p.nombres, '') AS nombres, "
      + "COALESCE(p.apellidos, '') AS apellidos, "
      + "(SELECT GROUP_CONCAT(r.nombre_rol ORDER BY r.id_rol SEPARATOR ',') "
      +   "FROM usuario_rol ur JOIN rol r ON r.id_rol = ur.id_rol "
      +   "WHERE ur.id_usuario = u.id_usuario) AS roles_csv "
      + "FROM usuario u "
      + "LEFT JOIN perfil p ON p.id_usuario = u.id_usuario "
      + "WHERE u.correo = ?";

    ps = con.prepareStatement(sql);
    ps.setString(1, correoLimpio);
    rs = ps.executeQuery();

    if (!rs.next()) {
      // Correo inexistente: no se audita (la FK exige un usuario real).
      response.sendRedirect(volverLogin);
      return;
    }

    int idUsuario = rs.getInt("id_usuario");

    String hashAlmacenado = rs.getString("contrasena_hash");
    if (hashAlmacenado == null || !hashAlmacenado.equals(claveCifrada(correoLimpio, clave))) {
      registrarAuditoria(con, idUsuario, "BLOQUEO_LOGIN",
          "Intento de acceso fallido por clave incorrecta: " + correoLimpio);
      response.sendRedirect(volverLogin);
      return;
    }

    if ("inactivo".equalsIgnoreCase(rs.getString("estado"))) {
      registrarAuditoria(con, idUsuario, "BLOQUEO_LOGIN",
          "Se rechazo el acceso de un usuario inactivo: " + correoLimpio);
      response.sendRedirect(ctx + "/login.jsp?error=inactivo&correo="
                            + URLEncoder.encode(correoLimpio, "UTF-8"));
      return;
    }

    String rolesCsv = rs.getString("roles_csv");
    String rolPrincipal = (rolesCsv == null) ? "" : rolesCsv.trim();
    int coma = rolPrincipal.indexOf(',');
    if (coma >= 0) {
      rolPrincipal = rolPrincipal.substring(0, coma).trim();
    }

    String nombre = (nullToVacio(rs.getString("nombres")) + " "
                   + nullToVacio(rs.getString("apellidos"))).trim();
    if (nombre.isEmpty()) {
      nombre = correoLimpio;
    }

    registrarAuditoria(con, idUsuario, "LOGIN",
        "Inicio de sesion exitoso del usuario: " + correoLimpio);

    HttpSession sesion = request.getSession(true);
    sesion.setAttribute("idUsuario", Integer.valueOf(idUsuario));
    sesion.setAttribute("correo", correoLimpio);
    sesion.setAttribute("nombre", nombre);
    sesion.setAttribute("rol", rolPrincipal);
    sesion.setAttribute("roles", rolesCsv == null ? "" : rolesCsv);

    String destino;
    if (tieneAlgunRol(rolesCsv, new String[]{"administrador"})) {
      destino = ctx + "/admin/panel.jsp";
    } else if (tieneAlgunRol(rolesCsv, new String[]{"inmobiliaria"})) {
      destino = ctx + "/agente/panel.jsp";
    } else {
      destino = ctx + "/cliente/panel.jsp";
    }
    response.sendRedirect(destino);
  } catch (Exception ex) {
    ex.printStackTrace();
    response.sendRedirect(ctx + "/login.jsp?error=servidor");
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%!
  public String nullToVacio(String texto) {
    return texto == null ? "" : texto;
  }
%>