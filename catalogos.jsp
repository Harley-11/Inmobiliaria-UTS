<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%--
 admin/catalogos.jsp - Parametrizacion de catalogos con CRUD simple:
  ciudad, tipo_propiedad y caracteristica. Cada seccion tiene formulario de
  alta, listado con edicion en linea (parametros ed/eid) y eliminacion.
  Las acciones van a catalogo_guardar.jsp (POST). Protegida por el fragmento
  seguridad.jspf y por SeguridadFilter (ruta /admin/*).
--%>
<%
  String[] rolesPermitidos = { "administrador" };
  String tituloPagina = "Catalogos";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  String okMsj = request.getParameter("ok");
  String errMsj = request.getParameter("err");
  String tab = request.getParameter("tab");
  String ed = request.getParameter("ed");   // ciudad | tipo | caracteristica
  int eid = aEntero(request.getParameter("eid"), 0);

  List<Object[]> ciudades = new ArrayList<Object[]>();
  List<Object[]> tipos = new ArrayList<Object[]>();
  List<Object[]> caracteristicas = new ArrayList<Object[]>();

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();
    ps = con.prepareStatement("SELECT id_ciudad, nombre_ciudad, departamento FROM ciudad ORDER BY id_ciudad");
    rs = ps.executeQuery();
    while (rs.next()) ciudades.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2), rs.getString(3)});
    cerrar(rs, ps);

    ps = con.prepareStatement("SELECT id_tipo, nombre_tipo FROM tipo_propiedad ORDER BY id_tipo");
    rs = ps.executeQuery();
    while (rs.next()) tipos.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    cerrar(rs, ps);

    ps = con.prepareStatement("SELECT id_caracteristica, nombre_caracteristica FROM caracteristica ORDER BY id_caracteristica");
    rs = ps.executeQuery();
    while (rs.next()) caracteristicas.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2)});
  } catch (Exception e) {
    e.printStackTrace();
    errMsj = (errMsj == null ? "" : errMsj + " - ") + "No se pudieron cargar los catalogos.";
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Catalogos</h1>
        <p class="text-muted mb-0">Parametrizacion de ciudades, tipos de propiedad y caracteristicas.</p>
    </div>
    <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/admin/panel.jsp"><i class="bi bi-arrow-left me-1"></i> Volver</a>
</div>

<% if ("1".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Registro creado correctamente.</div>
<% } else if ("2".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Registro actualizado correctamente.</div>
<% } else if ("3".equals(okMsj)) { %>
    <div class="alert alert-success rounded-4"><i class="bi bi-check-circle me-1"></i>Registro eliminado correctamente.</div>
<% } else if ("1".equals(errMsj)) { %>
    <div class="alert alert-warning rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Parametros invalidos para la operacion.</div>
<% } else if ("2".equals(errMsj)) { %>
    <div class="alert alert-warning rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>No se pudo eliminar: el registro esta en uso por propiedades u otros registros.</div>
<% } else if ("3".equals(errMsj)) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Error del servidor al procesar la operacion.</div>
<% } else if ("4".equals(errMsj)) { %>
    <div class="alert alert-warning rounded-4"><i class="bi bi-exclamation-triangle me-1"></i>Ya existe un registro con ese nombre en el catalogo.</div>
<% } else if (errMsj != null && !errMsj.trim().isEmpty()) { %>
    <div class="alert alert-danger rounded-4"><i class="bi bi-exclamation-triangle me-1"></i><%=esc(errMsj)%></div>
<% } %>

<div class="row g-4">
<%-- ================= CIUDAD ================= --%>
    <div class="col-lg-6" id="ciudad">
        <div class="card ims-card shadow-sm h-100">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-geo-alt me-1"></i> Ciudades</div>
            <div class="card-body">
                <form class="d-flex flex-wrap gap-2 mb-3" action="<%=ctx%>/admin/catalogo_guardar.jsp" method="post">
                    <input type="hidden" name="tabla" value="ciudad">
                    <input type="hidden" name="accion" value="crear">
                    <input type="hidden" name="tab" value="ciudad">
                    <input class="form-control flex-fill" type="text" name="nombre" placeholder="Nombre de la ciudad" required>
                    <input class="form-control" style="max-width:160px" type="text" name="departamento" placeholder="Departamento">
                    <button class="btn ims-btn rounded-pill px-3" type="submit"><i class="bi bi-plus-lg me-1"></i>Agregar</button>
                </form>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr><th scope="col">#</th><th scope="col">Nombre</th><th scope="col">Depto.</th><th scope="col" class="text-end">Acciones</th></tr>
                        </thead>
                        <tbody>
                    <% for (Object[] c : ciudades) {
                        int idCiudad = ((Integer) c[0]).intValue();
                        boolean modoEdicionCiudad = ("ciudad".equals(ed) && eid == idCiudad);
                    %>
                        <% if (modoEdicionCiudad) { %>
                            <tr>
                                <td colspan="4" class="bg-body-tertiary">
                                    <form class="d-flex flex-wrap gap-2" action="<%=ctx%>/admin/catalogo_guardar.jsp" method="post">
                                        <input type="hidden" name="tabla" value="ciudad">
                                        <input type="hidden" name="accion" value="editar">
                                        <input type="hidden" name="id" value="<%=idCiudad%>">
                                        <input type="hidden" name="tab" value="ciudad">
                                        <input class="form-control flex-fill" type="text" name="nombre" value="<%=esc((String) c[1])%>" required>
                                        <input class="form-control" style="max-width:160px" type="text" name="departamento"
                                               value="<%=esc((String) (c[2] == null ? "" : c[2]))%>" placeholder="Departamento">
                                        <button class="btn btn-sm ims-btn rounded-pill px-3" type="submit"><i class="bi bi-save me-1"></i>Guardar</button>
                                        <a class="btn btn-sm btn-outline-secondary rounded-pill px-3" href="<%=ctx%>/admin/catalogos.jsp?tab=ciudad"><i class="bi bi-x-circle me-1"></i>Cancelar</a>
                                    </form>
                                </td>
                            </tr>
                        <% } else { %>
                            <tr>
                                <td class="text-muted"><%=idCiudad%></td>
                                <td><%=esc((String) c[1])%></td>
                                <td class="text-muted"><%=esc(c[2] == null ? "-" : (String) c[2])%></td>
                                <td class="text-end text-nowrap">
                                    <a class="btn btn-sm btn-outline-primary rounded-pill px-2" href="<%=ctx%>/admin/catalogos.jsp?ed=ciudad&eid=<%=idCiudad%>#ciudad"><i class="bi bi-pencil"></i></a>
                                    <form class="d-inline" action="<%=ctx%>/admin/catalogo_guardar.jsp" method="post"
                                          onsubmit="return confirm('Desea eliminar esta ciudad?');">
                                        <input type="hidden" name="tabla" value="ciudad">
                                        <input type="hidden" name="accion" value="eliminar">
                                        <input type="hidden" name="id" value="<%=idCiudad%>">
                                        <input type="hidden" name="tab" value="ciudad">
                                        <button class="btn btn-sm btn-outline-danger rounded-pill px-2" type="submit" title="Eliminar"><i class="bi bi-trash"></i></button>
                                    </form>
                                </td>
                            </tr>
                        <% } %>
                    <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

<%-- ================= TIPO PROPIEDAD ================= --%>
    <div class="col-lg-6" id="tipo">
        <div class="card ims-card shadow-sm h-100">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-house-check me-1"></i> Tipos de propiedad</div>
            <div class="card-body">
                <form class="d-flex flex-wrap gap-2 mb-3" action="<%=ctx%>/admin/catalogo_guardar.jsp" method="post">
                    <input type="hidden" name="tabla" value="tipo">
                    <input type="hidden" name="accion" value="crear">
                    <input type="hidden" name="tab" value="tipo">
                    <input class="form-control flex-fill" type="text" name="nombre" placeholder="Nombre del tipo" required>
                    <button class="btn ims-btn rounded-pill px-3" type="submit"><i class="bi bi-plus-lg me-1"></i>Agregar</button>
                </form>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr><th scope="col">#</th><th scope="col">Nombre</th><th scope="col" class="text-end">Acciones</th></tr>
                        </thead>
                        <tbody>
                    <% for (Object[] t : tipos) {
                        int idTipo = ((Integer) t[0]).intValue();
                        boolean modoEdicionTipo = ("tipo".equals(ed) && eid == idTipo);
                    %>
                        <% if (modoEdicionTipo) { %>
                            <tr>
                                <td colspan="3" class="bg-body-tertiary">
                                    <form class="d-flex flex-wrap gap-2" action="<%=ctx%>/admin/catalogo_guardar.jsp" method="post">
                                        <input type="hidden" name="tabla" value="tipo">
                                        <input type="hidden" name="accion" value="editar">
                                        <input type="hidden" name="id" value="<%=idTipo%>">
                                        <input type="hidden" name="tab" value="tipo">
                                        <input class="form-control flex-fill" type="text" name="nombre" value="<%=esc((String) t[1])%>" required>
                                        <button class="btn btn-sm ims-btn rounded-pill px-3" type="submit"><i class="bi bi-save me-1"></i>Guardar</button>
                                        <a class="btn btn-sm btn-outline-secondary rounded-pill px-3" href="<%=ctx%>/admin/catalogos.jsp?tab=tipo"><i class="bi bi-x-circle me-1"></i>Cancelar</a>
                                    </form>
                                </td>
                            </tr>
                        <% } else { %>
                            <tr>
                                <td class="text-muted"><%=idTipo%></td>
                                <td><%=esc((String) t[1])%></td>
                                <td class="text-end text-nowrap">
                                    <a class="btn btn-sm btn-outline-primary rounded-pill px-2" href="<%=ctx%>/admin/catalogos.jsp?ed=tipo&eid=<%=idTipo%>#tipo"><i class="bi bi-pencil"></i></a>
                                    <form class="d-inline" action="<%=ctx%>/admin/catalogo_guardar.jsp" method="post"
                                          onsubmit="return confirm('Desea eliminar?');">
                                        <input type="hidden" name="tabla" value="tipo">
                                        <input type="hidden" name="accion" value="eliminar">
                                        <input type="hidden" name="id" value="<%=idTipo%>">
                                        <input type="hidden" name="tab" value="tipo">
                                        <button class="btn btn-sm btn-outline-danger rounded-pill px-2" type="submit" title="Eliminar"><i class="bi bi-trash"></i></button>
                                    </form>
                                </td>
                            </tr>
                        <% } %>
                    <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

<%-- ================= CARACTERISTICA ================= --%>
    <div class="col-12" id="caracteristica">
        <div class="card ims-card shadow-sm">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-list-check me-1"></i> Caracteristicas</div>
            <div class="card-body">
                <form class="d-flex flex-wrap gap-2 mb-3" action="<%=ctx%>/admin/catalogo_guardar.jsp" method="post">
                    <input type="hidden" name="tabla" value="caracteristica">
                    <input type="hidden" name="accion" value="crear">
                    <input type="hidden" name="tab" value="caracteristica">
                    <input class="form-control flex-fill" type="text" name="nombre" placeholder="Nombre de la caracteristica" required>
                    <button class="btn ims-btn rounded-pill px-3" type="submit"><i class="bi bi-plus-lg me-1"></i>Agregar</button>
                </form>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr><th scope="col">#</th><th scope="col">Nombre</th><th scope="col" class="text-end">Acciones</th></tr>
                        </thead>
                        <tbody>
                    <% for (Object[] car : caracteristicas) {
                        int idCar = ((Integer) car[0]).intValue();
                        boolean modoEdicionCar = ("caracteristica".equals(ed) && eid == idCar);
                    %>
                        <% if (modoEdicionCar) { %>
                            <tr>
                                <td colspan="3" class="bg-body-tertiary">
                                    <form class="d-flex flex-wrap gap-2" action="<%=ctx%>/admin/catalogo_guardar.jsp" method="post">
                                        <input type="hidden" name="tabla" value="caracteristica">
                                        <input type="hidden" name="accion" value="editar">
                                        <input type="hidden" name="id" value="<%=idCar%>">
                                        <input type="hidden" name="tab" value="caracteristica">
                                        <input class="form-control flex-fill" type="text" name="nombre" value="<%=esc((String) car[1])%>" required>
                                        <button class="btn btn-sm ims-btn rounded-pill px-3" type="submit"><i class="bi bi-save me-1"></i>Guardar</button>
                                        <a class="btn btn-sm btn-outline-secondary rounded-pill px-3" href="<%=ctx%>/admin/catalogos.jsp?tab=caracteristica"><i class="bi bi-x-circle me-1"></i>Cancelar</a>
                                    </form>
                                </td>
                            </tr>
                        <% } else { %>
                            <tr>
                                <td class="text-muted"><%=idCar%></td>
                                <td><%=esc((String) car[1])%></td>
                                <td class="text-end text-nowrap">
                                    <a class="btn btn-sm btn-outline-primary rounded-pill px-2" href="<%=ctx%>/admin/catalogos.jsp?ed=caracteristica&eid=<%=idCar%>#caracteristica"><i class="bi bi-pencil"></i></a>
                                    <form class="d-inline" action="<%=ctx%>/admin/catalogo_guardar.jsp" method="post"
                                          onsubmit="return confirm('Desea eliminar?');">
                                        <input type="hidden" name="tabla" value="caracteristica">
                                        <input type="hidden" name="accion" value="eliminar">
                                        <input type="hidden" name="id" value="<%=idCar%>">
                                        <input type="hidden" name="tab" value="caracteristica">
                                        <button class="btn btn-sm btn-outline-danger rounded-pill px-2" type="submit" title="Eliminar"><i class="bi bi-trash"></i></button>
                                    </form>
                                </td>
                            </tr>
                        <% } %>
                    <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>