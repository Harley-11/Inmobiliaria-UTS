<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 agente/propiedad_editar.jsp - Formulario de creacion (sin id) y edicion
 (con id) de una propiedad de la inmobiliaria del agente.
 Envia POST a guardar_propiedad.jsp. Params de error: err=matricula|datos|servidor
--%>
<%
  String[] rolesPermitidos = { "inmobiliaria" };
  String tituloPagina = "Publicar propiedad";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  int idUsuario = ((Integer) session.getAttribute("idUsuario")).intValue();
  int idEditar = aEntero(request.getParameter("id"), 0);
  String errMsj = request.getParameter("err");

  int idInmobiliaria = 0;
  boolean cargarOK = true;
  String vTitulo = "";
  String vDescripcion = "";
  double vPrecio = 0;
  int vCiudad = 0;
  int vTipo = 0;
  String vDireccion = "";
  String vMatricula = "";

  List<Object[]> ciudades = new ArrayList<Object[]>();
  List<Object[]> tipos = new ArrayList<Object[]>();

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    idInmobiliaria = idInmobiliariaDeUsuario(con, idUsuario);

    ps = con.prepareStatement("SELECT id_ciudad, nombre_ciudad FROM ciudad ORDER BY nombre_ciudad");
    rs = ps.executeQuery();
    while (rs.next()) ciudades.add(new Object[]{Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    cerrar(rs, ps);

    ps = con.prepareStatement("SELECT id_tipo, nombre_tipo FROM tipo_propiedad ORDER BY nombre_tipo");
    rs = ps.executeQuery();
    while (rs.next()) tipos.add(new Object[]{Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    cerrar(rs, ps);

    if (idEditar > 0) {
      if (idInmobiliaria <= 0 || !esPropiedadDeInmobiliaria(con, idEditar, idInmobiliaria)) {
        response.sendRedirect(ctx + "/agente/propiedades.jsp?err=1");
        return;
      }
      ps = con.prepareStatement(
          "SELECT titulo, descripcion, precio, id_ciudad, id_tipo, direccion, matricula_inmobiliaria " +
          "FROM propiedad WHERE id_propiedad = ?");
      ps.setInt(1, idEditar);
      rs = ps.executeQuery();
      if (rs.next()) {
        vTitulo = rs.getString(1);
        vDescripcion = rs.getString(2);
        vPrecio = rs.getDouble(3);
        vCiudad = rs.getInt(4);
        vTipo = rs.getInt(5);
        vDireccion = rs.getString(6);
        vMatricula = rs.getString(7);
      } else {
        response.sendRedirect(ctx + "/agente/propiedades.jsp?err=1");
        return;
      }
    } else if (idInmobiliaria <= 0) {
      response.sendRedirect(ctx + "/agente/propiedades.jsp?err=1");
      return;
    }
  } catch (Exception e) {
    e.printStackTrace();
    cargarOK = false;
  } finally {
    cerrar(rs, ps, con);
  }

  if (!cargarOK) {
    response.sendRedirect(ctx + "/agente/propiedades.jsp?err=2");
    return;
  }

  tituloPagina = (idEditar > 0) ? "Editar propiedad" : "Publicar propiedad";
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="row justify-content-center">
    <div class="col-lg-9">
        <div class="card ims-card shadow-lg">
            <div class="card-header bg-transparent fw-bold">
                <i class="bi bi-<%= idEditar > 0 ? "pencil-square" : "plus-square" %> me-1"></i>
                <%= idEditar > 0 ? "Editar propiedad" : "Publicar nueva propiedad" %>
            </div>
            <div class="card-body">
                <% if ("matricula".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Ya existe una propiedad con esa matricula inmobiliaria.</div>
                <% } else if ("datos".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Complete todos los campos obligatorios.</div>
                <% } else if ("servidor".equals(errMsj)) { %>
                    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>No se pudo guardar la propiedad. Intente mas tarde.</div>
                <% } %>

                <form action="<%=ctx%>/agente/guardar_propiedad.jsp" method="post">
                    <input type="hidden" name="id" value="<%=idEditar%>">
                    <div class="mb-3">
                        <label class="form-label" for="titulo">Titulo *</label>
                        <input type="text" class="form-control" id="titulo" name="titulo" maxlength="120"
                               value="<%=esc(vTitulo)%>" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label" for="descripcion">Descripcion</label>
                        <textarea class="form-control" id="descripcion" name="descripcion" rows="4"><%=esc(vDescripcion)%></textarea>
                    </div>
                    <div class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label" for="precio">Precio (COP) *</label>
                            <input type="number" min="0" step="100000" class="form-control" id="precio" name="precio"
                                   value="<%=vPrecio > 0 ? String.valueOf((long) vPrecio) : ""%>" placeholder="250000000" required>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label" for="matricula">Matricula inmobiliaria *</label>
                            <input type="text" class="form-control" id="matricula" name="matricula" maxlength="30"
                                   value="<%=esc(vMatricula)%>" placeholder="300-12345" required>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label" for="direccion">Direccion</label>
                            <input type="text" class="form-control" id="direccion" name="direccion" maxlength="150"
                                   value="<%=esc(vDireccion)%>" placeholder="Cra 30 # 45-10">
                        </div>
                    </div>
                    <div class="row g-3 mt-0">
                        <div class="col-md-6">
                            <label class="form-label" for="id_ciudad">Ciudad *</label>
                            <select class="form-select" id="id_ciudad" name="id_ciudad" required>
                                <option value="0">Seleccione...</option>
                        <% for (Object[] c : ciudades) {
                            int idCiud = ((Integer) c[0]).intValue();
                            String sel = (idCiud == vCiudad) ? " selected" : ""; %>
                                <option value="<%=idCiud%>"<%=sel%>><%=esc((String) c[1])%></option>
                        <% } %>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label" for="id_tipo">Tipo *</label>
                            <select class="form-select" id="id_tipo" name="id_tipo" required>
                                <option value="0">Seleccione...</option>
                        <% for (Object[] t : tipos) {
                            int idTip = ((Integer) t[0]).intValue();
                            String selT = (idTip == vTipo) ? " selected" : ""; %>
                                <option value="<%=idTip%>"<%=selT%>><%=esc((String) t[1])%></option>
                        <% } %>
                            </select>
                        </div>
                    </div>
                    <div class="d-flex gap-2 mt-4">
                        <button type="submit" class="btn ims-btn rounded-pill px-4"><i class="bi bi-save me-1"></i> Guardar</button>
                        <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/agente/propiedades.jsp"><i class="bi bi-x-circle me-1"></i> Cancelar</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>