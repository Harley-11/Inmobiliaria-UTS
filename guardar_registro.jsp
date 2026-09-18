<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLIntegrityConstraintViolationException" %>
<%@ page import="java.sql.Statement" %>
<%--
 guardar_registro.jsp - Recibe el POST de registro.jsp, valida los campos
 obligatorios e inserta el nuevo usuario (usuario + perfil + usuario_rol)
 en una sola transaccion (autocommit = false).
 La clave se guarda como claveCifrada(correo, clave) = SHA-256 "correo:clave".
 Requisito del enunciado: capturar SQLIntegrityConstraintViolationException y
 mostrar "El correo ya se encuentra registrado" en vez de una excepcion cruda.
 Exito: redirige a login.jsp?exito=1. Error: reenvia a registro.jsp con el
 mensaje y conserva los datos escritos.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
  request.setCharacterEncoding("UTF-8");
  String ctx = request.getContextPath();

  String nombres   = request.getParameter("nombres");
  String apellidos = request.getParameter("apellidos");
  String documento = request.getParameter("documento");
  String telefono  = request.getParameter("telefono");
  String direccion = request.getParameter("direccion");
  String correo    = request.getParameter("correo");
  String clave     = request.getParameter("clave");
  String clave2    = request.getParameter("confirmar_clave");

  String nombresL   = (nombres   == null) ? "" : nombres.trim();
  String apellidosL = (apellidos == null) ? "" : apellidos.trim();
  String documentoL = (documento == null) ? "" : documento.trim();
  String telefonoL  = (telefono  == null) ? "" : telefono.trim();
  String direccionL = (direccion == null) ? "" : direccion.trim();
  String correoLimpio = (correo   == null) ? "" : correo.trim().toLowerCase();

  String error = null;

  if (nombresL.isEmpty() || apellidosL.isEmpty() || documentoL.isEmpty()
      || correoLimpio.isEmpty() || clave == null || clave.isEmpty()
      || clave2 == null || clave2.isEmpty()) {
    error = "Complete todos los campos obligatorios.";
  } else if (!clave.equals(clave2)) {
    error = "Las claves no coinciden.";
  }

  if (error != null) {
    request.setAttribute("error", error);
    request.getRequestDispatcher("/registro.jsp").forward(request, response);
    return;
  }

  // El registro publico SOLO crea cuentas de rol "cliente" (id_rol = 3).
  // No se lee el parametro "rol": un atacante no puede autoasignarse
  // "administrador" ni "inmobiliaria". Esos roles solo los asigna un
  // administrador desde su panel (historia: asignar y revocar roles).
  int idRol = 3;

  Connection con = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);

    PreparedStatement ps = null;
    try {
      ps = con.prepareStatement(
          "INSERT INTO usuario (correo, contrasena_hash, estado) VALUES (?, ?, 'activo')",
          Statement.RETURN_GENERATED_KEYS);
      ps.setString(1, correoLimpio);
      ps.setString(2, claveCifrada(correoLimpio, clave));
      ps.executeUpdate();

      ResultSet gen = ps.getGeneratedKeys();
      gen.next();
      int idUsuario = gen.getInt(1);
      cerrar(gen, ps);

      ps = con.prepareStatement(
          "INSERT INTO perfil (id_usuario, nombres, apellidos, documento, telefono, direccion) "
        + "VALUES (?, ?, ?, ?, ?, ?)");
      ps.setInt(1, idUsuario);
      ps.setString(2, nombresL);
      ps.setString(3, apellidosL);
      ps.setString(4, documentoL);
      ps.setString(5, telefonoL.isEmpty()  ? null : telefonoL);
      ps.setString(6, direccionL.isEmpty() ? null : direccionL);
      ps.executeUpdate();
      cerrar(ps);

      ps = con.prepareStatement(
          "INSERT INTO usuario_rol (id_usuario, id_rol) VALUES (?, ?)");
      ps.setInt(1, idUsuario);
      ps.setInt(2, idRol);
      ps.executeUpdate();
      cerrar(ps);

      registrarAuditoria(con, idUsuario, "REGISTRO",
          "Nuevo registro de cuenta (rol cliente): " + correoLimpio);

      con.commit();
      response.sendRedirect(ctx + "/login.jsp?exito=1");
    } catch (SQLIntegrityConstraintViolationException ex) {
      deshacer(con);
      request.setAttribute("error", "El correo ya se encuentra registrado.");
      request.getRequestDispatcher("/registro.jsp").forward(request, response);
    } catch (SQLException ex) {
      deshacer(con);
      ex.printStackTrace();
      request.setAttribute("error", "No se pudo completar el registro. Intente de nuevo.");
      request.getRequestDispatcher("/registro.jsp").forward(request, response);
    } finally {
      cerrar(con);
    }
  } catch (SQLException ex) {
    ex.printStackTrace();
    request.setAttribute("error", "No se pudo conectar con la base de datos.");
    request.getRequestDispatcher("/registro.jsp").forward(request, response);
  }
%>