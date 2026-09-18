<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLIntegrityConstraintViolationException" %>
<%--
 admin/catalogo_guardar.jsp - CRUD simple de tres catalogos maestros:
  - ciudad            (tabla ciudad: nombre_ciudad, departamento)
  - tipo              (tabla tipo_propiedad: nombre_tipo)
  - caracteristica    (tabla caracteristica: nombre_caracteristica)
 Procesa POST desde admin/catalogos.jsp con los parametros:
  tabla  = ciudad | tipo | caracteristica
  accion = crear | editar | eliminar
  id; nombre; [departamento]
  - Mientras el registro este referenciado por FK (propiedad, etc.) la
    eliminacion la bloquea el RESTRICT de InnoDB; se captura el error y se
    informa al usuario. Los nombres duplicados (UNIQUE) se detectan igual.
  - Queda en auditoria. No emite HTML: solo redirige.
--%>
<%
  String[] rolesPermitidos = { "administrador" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  request.setCharacterEncoding("UTF-8");
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();

  String tabla = request.getParameter("tabla");
  String accion = request.getParameter("accion");
  int id = aEntero(request.getParameter("id"), 0);
  String nombre = request.getParameter("nombre");
  String departamento = request.getParameter("departamento");
  String tab = request.getParameter("tab");

  boolean tablaOK = "ciudad".equals(tabla) || "tipo".equals(tabla) || "caracteristica".equals(tabla);
  boolean accionOK = "crear".equals(accion) || "editar".equals(accion) || "eliminar".equals(accion);
  String base = ctx + "/admin/catalogos.jsp?";

  if (!tablaOK || !accionOK || (("crear".equals(accion) || "editar".equals(accion)) && (nombre == null || nombre.trim().isEmpty()))
      || ("eliminar".equals(accion) && id <= 0) || ("editar".equals(accion) && id <= 0)) {
    response.sendRedirect(base + "tab=" + tab + "&err=1");
    return;
  }

  String nombreLimpio = (nombre == null) ? "" : nombre.trim();

  Connection con = null;
  PreparedStatement ps = null;
  try {
    con = abrirConexion();
    con.setAutoCommit(false);

    if ("crear".equals(accion)) {
      if ("ciudad".equals(tabla)) {
        ps = con.prepareStatement(
            "INSERT INTO ciudad (nombre_ciudad, departamento) VALUES (?, ?)");
        ps.setString(1, nombreLimpio);
        ps.setString(2, (departamento == null ? "" : departamento.trim()).isEmpty() ? null : departamento.trim());
      } else if ("tipo".equals(tabla)) {
        ps = con.prepareStatement("INSERT INTO tipo_propiedad (nombre_tipo) VALUES (?)");
        ps.setString(1, nombreLimpio);
      } else {
        ps = con.prepareStatement("INSERT INTO caracteristica (nombre_caracteristica) VALUES (?)");
        ps.setString(1, nombreLimpio);
      }
      ps.executeUpdate();
      cerrar(ps);
      con.commit();
      registrarAuditoria(con, idUsuario, "CREAR_CATALOGO",
          "Catalogo '" + tabla + "': se creo '" + nombreLimpio + "'");
      con.commit();
      response.sendRedirect(base + "tab=" + tab + "&ok=1");
      return;
    }

    if ("editar".equals(accion)) {
      if ("ciudad".equals(tabla)) {
        ps = con.prepareStatement(
            "UPDATE ciudad SET nombre_ciudad = ?, departamento = ? WHERE id_ciudad = ?");
        ps.setString(1, nombreLimpio);
        ps.setString(2, (departamento == null ? "" : departamento.trim()).isEmpty() ? null : departamento.trim());
        ps.setInt(3, id);
      } else if ("tipo".equals(tabla)) {
        ps = con.prepareStatement("UPDATE tipo_propiedad SET nombre_tipo = ? WHERE id_tipo = ?");
        ps.setString(1, nombreLimpio);
        ps.setInt(2, id);
      } else {
        ps = con.prepareStatement("UPDATE caracteristica SET nombre_caracteristica = ? WHERE id_caracteristica = ?");
        ps.setString(1, nombreLimpio);
        ps.setInt(2, id);
      }
      ps.executeUpdate();
      cerrar(ps);
      con.commit();
      registrarAuditoria(con, idUsuario, "EDITAR_CATALOGO",
          "Catalogo '" + tabla + "': se edito el registro " + id + " a '" + nombreLimpio + "'");
      con.commit();
      response.sendRedirect(base + "tab=" + tab + "&ok=2");
      return;
    }

    // eliminar
    if ("ciudad".equals(tabla)) {
      ps = con.prepareStatement("DELETE FROM ciudad WHERE id_ciudad = ?");
      ps.setInt(1, id);
    } else if ("tipo".equals(tabla)) {
      ps = con.prepareStatement("DELETE FROM tipo_propiedad WHERE id_tipo = ?");
      ps.setInt(1, id);
    } else {
      ps = con.prepareStatement("DELETE FROM caracteristica WHERE id_caracteristica = ?");
      ps.setInt(1, id);
    }
    ps.executeUpdate();
    cerrar(ps);
    con.commit();
    registrarAuditoria(con, idUsuario, "ELIMINAR_CATALOGO",
        "Catalogo '" + tabla + "': se elimino el registro " + id);
    con.commit();
    response.sendRedirect(base + "tab=" + tab + "&ok=3");
  } catch (SQLIntegrityConstraintViolationException e) {
    if (con != null) { try { con.rollback(); } catch (Exception ignorada) { } }
    int errCode = e.getErrorCode();
    // 1062 = duplicado (UNIQUE) / 1451 de mas = FK RESTRICT.
    if (errCode == 1062) {
      response.sendRedirect(base + "tab=" + tab + "&err=4");
    } else {
      response.sendRedirect(base + "tab=" + tab + "&err=2");
    }
  } catch (Exception e) {
    if (con != null) { try { con.rollback(); } catch (Exception ignorada) { } }
    e.printStackTrace();
    response.sendRedirect(base + "tab=" + tab + "&err=3");
  } finally {
    cerrar(ps, con);
  }
%>