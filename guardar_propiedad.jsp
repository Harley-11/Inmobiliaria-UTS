<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 agente/guardar_propiedad.jsp - Procesa el formulario de creacion/edicion
 de propiedad (POST). Crea una propiedad nueva en estado 'disponible' o
 actualiza una existente, siempre verificando que pertenezca a la
 inmobiliaria del agente conectado.
--%>
<%
  String[] rolesPermitidos = { "inmobiliaria" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  request.setCharacterEncoding("UTF-8");
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();

  int idProp = aEntero(request.getParameter("id"), 0);
  String tituloF = request.getParameter("titulo");
  String descripcionF = request.getParameter("descripcion");
  double precioF = aDoble(request.getParameter("precio"), -1);
  int idCiudadF = aEntero(request.getParameter("id_ciudad"), 0);
  int idTipoF = aEntero(request.getParameter("id_tipo"), 0);
  String matriculaF = request.getParameter("matricula");
  String direccionF = request.getParameter("direccion");

  String enlaceVolver = ctx + "/agente/propiedad_editar.jsp?id=" + idProp;
  String sepErr = (idProp > 0 ? "&" : "?");

  boolean datosInvalidos =
      (tituloF == null || tituloF.trim().isEmpty())
   || (matriculaF == null || matriculaF.trim().isEmpty())
   || precioF < 0 || idCiudadF <= 0 || idTipoF <= 0;

  if (datosInvalidos) {
    response.sendRedirect(enlaceVolver + sepErr + "err=datos");
    return;
  }

  Connection con = null;
  PreparedStatement ps = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);
    int idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);

    if (idProp > 0) {
      if (idInmobiliaria <= 0 || !esPropiedadDeInmobiliaria(con, idProp, idInmobiliaria)) {
        response.sendRedirect(ctx + "/agente/propiedades.jsp?err=1");
        return;
      }
      ps = con.prepareStatement(
          "UPDATE propiedad SET titulo = ?, descripcion = ?, precio = ?, " +
          "id_ciudad = ?, id_tipo = ?, direccion = ?, matricula_inmobiliaria = ? " +
          "WHERE id_propiedad = ?");
      ps.setString(1, tituloF.trim());
      ps.setString(2, (descripcionF == null || descripcionF.trim().isEmpty()) ? null : descripcionF.trim());
      ps.setDouble(3, precioF);
      ps.setInt(4, idCiudadF);
      ps.setInt(5, idTipoF);
      ps.setString(6, (direccionF == null || direccionF.trim().isEmpty()) ? null : direccionF.trim());
      ps.setString(7, matriculaF.trim());
      ps.setInt(8, idProp);
      ps.executeUpdate();
    } else {
      if (idInmobiliaria <= 0) {
        response.sendRedirect(ctx + "/agente/propiedades.jsp?err=1");
        return;
      }
      ps = con.prepareStatement(
          "INSERT INTO propiedad (id_inmobiliaria, id_ciudad, id_tipo, matricula_inmobiliaria, " +
          "titulo, descripcion, precio, direccion, estado) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'disponible')");
      ps.setInt(1, idInmobiliaria);
      ps.setInt(2, idCiudadF);
      ps.setInt(3, idTipoF);
      ps.setString(4, matriculaF.trim());
      ps.setString(5, tituloF.trim());
      ps.setString(6, (descripcionF == null || descripcionF.trim().isEmpty()) ? null : descripcionF.trim());
      ps.setDouble(7, precioF);
      ps.setString(8, (direccionF == null || direccionF.trim().isEmpty()) ? null : direccionF.trim());
      ps.executeUpdate();
    }
    cerrar(ps);
    con.commit();
    registrarAuditoria(con, idUsuario, "PROPIEDAD", "Propiedad guardada id=" + idProp + " matricula=" + matriculaF.trim());
    con.commit();
    response.sendRedirect(ctx + "/agente/propiedades.jsp?ok=1");
  } catch (java.sql.SQLIntegrityConstraintViolationException e) {
    response.sendRedirect(enlaceVolver + sepErr + "err=matricula");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(enlaceVolver + sepErr + "err=servidor");
  } finally {
    cerrar(ps, con);
  }
%>