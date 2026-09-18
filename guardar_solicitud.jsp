<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.io.*" %>
<%--
 cliente/guardar_solicitud.jsp - Procesa el formulario multipart de solicitud
 de compra/arriendo (POST). Crea la solicitud con estado 'pendiente' y guarda
 cada documento adjunto en la carpeta documentos/ del contexto web, insertando
 su registro en documento_solicitud (tipo_documento, url_archivo).
 Requiere el multipart-config del servlet jsp declarado en WEB-INF/web.xml.
--%>
<%
  String[] rolesPermitidos = { "cliente" };
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%!
  private static final String[] EXT_PERMITIDAS =
      { "pdf", "jpg", "jpeg", "png", "webp", "gif", "doc", "docx", "txt" };

  public String extensionArchivo(String nombre) {
    if (nombre == null) return "";
    int punto = nombre.lastIndexOf('.');
    if (punto < 0 || punto == nombre.length() - 1) return "";
    return nombre.substring(punto + 1).toLowerCase();
  }

  public boolean extensionPermitida(String ext) {
    for (String e : EXT_PERMITIDAS) {
      if (e.equals(ext)) return true;
    }
    return false;
  }
%>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();

  int idProp = 0;
  String tipoSolicitud = null;
  try {
    // El acceso a getParts dispara el parseo multipart; solo despues de esa
    // llamada los parametros de texto del formulario quedan disponibles.
    request.getParts();
    idProp = aEntero(request.getParameter("propiedad"), 0);
    tipoSolicitud = request.getParameter("tipo");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(ctx + "/cliente/solicitar_solicitud.jsp?err=servidor");
    return;
  }

  if (idProp <= 0 || !("compra".equals(tipoSolicitud) || "arriendo".equals(tipoSolicitud))) {
    response.sendRedirect(ctx + "/cliente/solicitar_solicitud.jsp?propiedad=" + idProp + "&err=tipo");
    return;
  }

  int[] slots = { 1, 2, 3 };

  try {
    // Validar que haya al menos un archivo valido.
    boolean hayArchivo = false;
    for (int i : slots) {
      Part parte = request.getPart("archivo" + i);
      if (parte != null && parte.getSize() > 0) {
        String nombreOrig = parte.getSubmittedFileName();
        if (nombreOrig != null && !nombreOrig.trim().isEmpty()
            && extensionPermitida(extensionArchivo(nombreOrig))) {
          hayArchivo = true;
        }
      }
    }
    if (!hayArchivo) {
      response.sendRedirect(ctx + "/cliente/solicitar_solicitud.jsp?propiedad=" + idProp + "&err=archivo");
      return;
    }

    String raiz = application.getRealPath("/");
    File carpetaDocs = new File(raiz, "documentos");
    if (!carpetaDocs.exists()) carpetaDocs.mkdirs();

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
      con = abrirConexion();
      con.setAutoCommit(false);

      ps = con.prepareStatement("SELECT 1 FROM propiedad WHERE id_propiedad = ? AND estado = 'disponible'");
      ps.setInt(1, idProp);
      rs = ps.executeQuery();
      boolean propValida = rs.next();
      cerrar(rs, ps);

      if (!propValida) {
        response.sendRedirect(ctx + "/cliente/solicitar_solicitud.jsp?propiedad=" + idProp + "&err=servidor");
        return;
      }

      // Regla de negocio: un mismo cliente no puede tener dos solicitudes
      // pendientes del mismo tipo (compra/arriendo) sobre la misma propiedad.
      // El bloqueo es SOLO contra estado 'pendiente'; una vez la solicitud fue
      // aprobada o rechazada el cliente puede radicar una nueva.
      ps = con.prepareStatement(
          "SELECT 1 FROM solicitud WHERE id_propiedad = ? AND id_cliente = ? AND tipo = ? AND estado = 'pendiente'");
      ps.setInt(1, idProp);
      ps.setInt(2, idUsuario);
      ps.setString(3, tipoSolicitud);
      rs = ps.executeQuery();
      boolean existePendiente = rs.next();
      cerrar(rs, ps);

      if (existePendiente) {
        response.sendRedirect(ctx + "/cliente/solicitar_solicitud.jsp?propiedad=" + idProp
            + "&err=duplicado&tipo=" + tipoSolicitud);
        return;
      }

      long base = new java.util.Date().getTime();
      int contadorArchivos = 0;

      ps = con.prepareStatement(
          "INSERT INTO solicitud (id_propiedad, id_cliente, tipo, estado) VALUES (?, ?, ?, 'pendiente')",
          java.sql.Statement.RETURN_GENERATED_KEYS);
      ps.setInt(1, idProp);
      ps.setInt(2, idUsuario);
      ps.setString(3, tipoSolicitud);
      ps.executeUpdate();
      rs = ps.getGeneratedKeys();
      rs.next();
      int idSolicitud = rs.getInt(1);
      cerrar(rs, ps);

      for (int i : slots) {
        Part parte = request.getPart("archivo" + i);
        if (parte == null || parte.getSize() <= 0) continue;
        String nombreOrig = parte.getSubmittedFileName();
        if (nombreOrig == null || nombreOrig.trim().isEmpty()
            || !extensionPermitida(extensionArchivo(nombreOrig))) continue;

        String tipoDoc = request.getParameter("tipo_documento" + i);
        if (tipoDoc == null || tipoDoc.trim().isEmpty()) tipoDoc = "Documento de soporte";

        contadorArchivos++;
        String nombre = "sol_" + base + "_" + i + "." + extensionArchivo(nombreOrig);
        java.io.File destino = new java.io.File(carpetaDocs, nombre);
        try (java.io.InputStream entrada = parte.getInputStream();
             java.io.FileOutputStream fos = new java.io.FileOutputStream(destino)) {
          byte[] buffer = new byte[8192];
          int leidos;
          while ((leidos = entrada.read(buffer)) != -1) fos.write(buffer, 0, leidos);
        }

        ps = con.prepareStatement(
            "INSERT INTO documento_solicitud (id_solicitud, tipo_documento, url_archivo) VALUES (?, ?, ?)");
        ps.setInt(1, idSolicitud);
        ps.setString(2, tipoDoc.trim());
        ps.setString(3, "documentos/" + nombre);
        ps.executeUpdate();
        cerrar(ps);
      }

      if (contadorArchivos == 0) {
        deshacer(con);
        response.sendRedirect(ctx + "/cliente/solicitar_solicitud.jsp?propiedad=" + idProp + "&err=archivo");
        return;
      }

      con.commit();
      registrarAuditoria(con, idUsuario, "SOLICITUD",
          "Radico solicitud de " + tipoSolicitud + " sobre propiedad id=" + idProp
          + " (" + contadorArchivos + " documento" + (contadorArchivos == 1 ? "" : "s") + ")");
      con.commit();
      response.sendRedirect(ctx + "/cliente/mis_solicitudes.jsp?ok=1");
    } catch (Exception e) {
      if (con != null) { try { con.rollback(); } catch (Exception ignorada) { } }
      e.printStackTrace();
      response.sendRedirect(ctx + "/cliente/solicitar_solicitud.jsp?propiedad=" + idProp + "&err=servidor");
    } finally {
      cerrar(rs, ps, con);
    }
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(ctx + "/cliente/solicitar_solicitud.jsp?propiedad=" + idProp + "&err=servidor");
  }
%>