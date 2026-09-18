<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 admin/usuario_estado.jsp - Activa o inactiva la cuenta de un usuario
 (campo estado en la tabla usuario). Proceso POST desde admin/usuarios.jsp.
  - Valida el nuevo estado (activo / inactivo) y que el usuario exista.
  - Un administrador NO puede desactivar su propia cuenta.
  - Baja logica: el registro nunca se borra (la FK de auditoria es RESTRICT
    y hay trazas vinculadas); inactivar solo bloquea el acceso.
  - Queda registrado en auditoria. No emite HTML: solo redirige.
--%>
<%
  String[] rolesPermitidos = { "administrador" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuarioSesion = ((Integer) session.getAttribute("idUsuario")).intValue();
  int idUsuario = aEntero(request.getParameter("id_usuario"), 0);
  String nuevoEstado = request.getParameter("estado");

  boolean esActivo = "activo".equals(nuevoEstado);
  boolean esInactivo = "inactivo".equals(nuevoEstado);

  if (idUsuario <= 0 || (!esActivo && !esInactivo)) {
    response.sendRedirect(ctx + "/admin/usuarios.jsp?err=1");
    return;
  }

  // Proteccion: no desactivar la propia cuenta del administrador en sesion.
  if (idUsuario == idUsuarioSesion && esInactivo) {
    response.sendRedirect(ctx + "/admin/usuarios.jsp?err=4");
    return;
  }

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);

    ps = con.prepareStatement("SELECT correo, estado FROM usuario WHERE id_usuario = ?");
    ps.setInt(1, idUsuario);
    rs = ps.executeQuery();
    if (!rs.next()) {
      response.sendRedirect(ctx + "/admin/usuarios.jsp?err=1");
      return;
    }
    String correoObjetivo = rs.getString(1);
    String estadoActual = rs.getString(2);
    cerrar(rs, ps);

    if (estadoActual != null && estadoActual.equals(nuevoEstado)) {
      // No hay cambio real: se informa igual que un exito para no bloquear.
      response.sendRedirect(ctx + "/admin/usuarios.jsp?ok=2");
      return;
    }

    ps = con.prepareStatement("UPDATE usuario SET estado = ? WHERE id_usuario = ?");
    ps.setString(1, nuevoEstado);
    ps.setInt(2, idUsuario);
    ps.executeUpdate();
    cerrar(ps);

    con.commit();
    registrarAuditoria(con, idUsuarioSesion, esActivo ? "ACTIVAR_USUARIO" : "INACTIVAR_USUARIO",
        "Cuenta " + idUsuario + " (" + correoObjetivo + ") paso a estado '" + nuevoEstado + "'");
    con.commit();
    response.sendRedirect(ctx + "/admin/usuarios.jsp?ok=2");
  } catch (Exception e) {
    if (con != null) { try { con.rollback(); } catch (Exception ignorada) { } }
    e.printStackTrace();
    response.sendRedirect(ctx + "/admin/usuarios.jsp?err=2");
  } finally {
    cerrar(rs, ps, con);
  }
%>