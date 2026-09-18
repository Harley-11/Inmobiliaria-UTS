<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%-- =====================================================================
 admin/reportes.jsp - Modulo de reportes de la sustentacion.
 Consta de 5 consultas documentadas (el SQL de cada una aparece comentado
 aqui mismo y se ejecuta con PreparedStatement):

 1) INNER JOIN (3+ tablas): propiedades con su ciudad, tipo e inmobiliaria.
    SELECT p.titulo, tp.nombre_tipo, c.nombre_ciudad, i.nombre_comercial,
           p.precio, p.estado, p.fecha_publicacion
    FROM propiedad p
    INNER JOIN tipo_propiedad tp ON tp.id_tipo = p.id_tipo
    INNER JOIN ciudad c   ON c.id_ciudad   = p.id_ciudad
    INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria
    WHERE p.estado = 'disponible'
    ORDER BY p.id_propiedad;

 2) INNER JOIN (3+ tablas): citas con la propiedad, el cliente y la inmobiliaria.
    SELECT ct.fecha_hora, ct.estado, p.titulo, i.nombre_comercial,
           u.correo, per.nombres, per.apellidos
    FROM cita ct
    INNER JOIN propiedad p   ON p.id_propiedad = ct.id_propiedad
    INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria
    INNER JOIN usuario u     ON u.id_usuario = ct.id_cliente
    INNER JOIN perfil per    ON per.id_usuario = u.id_usuario
    ORDER BY ct.fecha_hora DESC;

 3) N:M (propiedad_caracteristica): caracteristicas de UNA propiedad dada.
    SELECT c.nombre_caracteristica, pc.cantidad
    FROM propiedad_caracteristica pc
    INNER JOIN caracteristica c ON c.id_caracteristica = pc.id_caracteristica
    WHERE pc.id_propiedad = ?
    ORDER BY c.id_caracteristica;

 4) LEFT JOIN: propiedades que todavia NO tienen ninguna cita agendada.
    SELECT p.titulo, i.nombre_comercial, c.nombre_ciudad, p.estado
    FROM propiedad p
    INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria
    INNER JOIN ciudad c       ON c.id_ciudad = p.id_ciudad
    LEFT JOIN cita ct         ON ct.id_propiedad = p.id_propiedad
    WHERE ct.id_cita IS NULL
    ORDER BY p.id_propiedad;

 5) GROUP BY + HAVING: propiedades disponibles agrupadas por ciudad,
    mostrando solo ciudades con MAS DE UNA propiedad disponible.
    SELECT c.nombre_ciudad, COUNT(p.id_propiedad) AS disponibles
    FROM propiedad p
    INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad
    WHERE p.estado = 'disponible'
    GROUP BY c.id_ciudad, c.nombre_ciudad
    HAVING COUNT(p.id_propiedad) > 1
    ORDER BY disponibles DESC, c.nombre_ciudad;
===================================================================== --%>
<%
  String[] rolesPermitidos = { "administrador" };
  String tituloPagina = "Reportes";
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%
  List<Object[]> rPropCiudad = new ArrayList<Object[]>();
  List<Object[]> rCitas = new ArrayList<Object[]>();
  List<Object[]> rSinCita = new ArrayList<Object[]>();
  List<Object[]> rPorCiudad = new ArrayList<Object[]>();
  List<Object[]> rCaractProp = new ArrayList<Object[]>();
  List<Object[]> propiedades = new ArrayList<Object[]>();

  int idPropSel = aEntero(request.getParameter("prop"), 0);

  Connection con = null;
  PreparedStatement ps = null;
  ResultSet rs = null;
  try {
    con = abrirConexion();

    // Lista de propiedades para el selector de la consulta N:M.
    ps = con.prepareStatement("SELECT id_propiedad, titulo FROM propiedad ORDER BY id_propiedad");
    rs = ps.executeQuery();
    while (rs.next()) propiedades.add(new Object[]{
        Integer.valueOf(rs.getInt(1)), rs.getString(2)});
    cerrar(rs, ps);
    if (idPropSel <= 0 && !propiedades.isEmpty()) {
      idPropSel = ((Integer) propiedades.get(0)[0]).intValue();
    }

    // Consulta 1
    ps = con.prepareStatement(
        "SELECT p.titulo, tp.nombre_tipo, c.nombre_ciudad, i.nombre_comercial, " +
        "p.precio, p.estado, p.fecha_publicacion " +
        "FROM propiedad p " +
        "INNER JOIN tipo_propiedad tp ON tp.id_tipo = p.id_tipo " +
        "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
        "INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria " +
        "WHERE p.estado = 'disponible' ORDER BY p.id_propiedad");
    rs = ps.executeQuery();
    while (rs.next()) rPropCiudad.add(new Object[]{
        rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4),
        Double.valueOf(rs.getDouble(5)), rs.getString(6), rs.getString(7)});
    cerrar(rs, ps);

    // Consulta 2
    ps = con.prepareStatement(
        "SELECT ct.fecha_hora, ct.estado, p.titulo, i.nombre_comercial, " +
        "u.correo, per.nombres, per.apellidos " +
        "FROM cita ct " +
        "INNER JOIN propiedad p ON p.id_propiedad = ct.id_propiedad " +
        "INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria " +
        "INNER JOIN usuario u ON u.id_usuario = ct.id_cliente " +
        "INNER JOIN perfil per ON per.id_usuario = u.id_usuario " +
        "ORDER BY ct.fecha_hora DESC");
    rs = ps.executeQuery();
    while (rs.next()) rCitas.add(new Object[]{
        rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4),
        rs.getString(5), rs.getString(6), rs.getString(7)});
    cerrar(rs, ps);

    // Consulta 3 (parametrizada por propiedad)
    if (idPropSel > 0) {
      ps = con.prepareStatement(
          "SELECT c.nombre_caracteristica, pc.cantidad " +
          "FROM propiedad_caracteristica pc " +
          "INNER JOIN caracteristica c ON c.id_caracteristica = pc.id_caracteristica " +
          "WHERE pc.id_propiedad = ? " +
          "ORDER BY c.id_caracteristica");
      ps.setInt(1, idPropSel);
      rs = ps.executeQuery();
      while (rs.next()) rCaractProp.add(new Object[]{
          rs.getString(1), Integer.valueOf(rs.getInt(2))});
      cerrar(rs, ps);
    }

    // Consulta 4
    ps = con.prepareStatement(
        "SELECT p.titulo, i.nombre_comercial, c.nombre_ciudad, p.estado " +
        "FROM propiedad p " +
        "INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria " +
        "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
        "LEFT JOIN cita ct ON ct.id_propiedad = p.id_propiedad " +
        "WHERE ct.id_cita IS NULL " +
        "ORDER BY p.id_propiedad");
    rs = ps.executeQuery();
    while (rs.next()) rSinCita.add(new Object[]{
        rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4)});
    cerrar(rs, ps);

    // Consulta 5
    ps = con.prepareStatement(
        "SELECT c.nombre_ciudad, COUNT(p.id_propiedad) AS disponibles " +
        "FROM propiedad p " +
        "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
        "WHERE p.estado = 'disponible' " +
        "GROUP BY c.id_ciudad, c.nombre_ciudad " +
        "HAVING COUNT(p.id_propiedad) > 1 " +
        "ORDER BY disponibles DESC, c.nombre_ciudad");
    rs = ps.executeQuery();
    while (rs.next()) rPorCiudad.add(new Object[]{
        rs.getString(1), Integer.valueOf(rs.getInt(2))});
  } catch (Exception e) {
    e.printStackTrace();
  } finally {
    cerrar(rs, ps, con);
  }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-2">
    <div>
        <h1 class="h4 fw-bold mb-1">Reportes</h1>
        <p class="text-muted mb-0">Consultas de la sustentacion. El SQL de cada reporte esta comentado en admin/reportes.jsp.</p>
    </div>
    <a class="btn btn-outline-secondary rounded-pill px-4" href="<%=ctx%>/admin/panel.jsp"><i class="bi bi-arrow-left me-1"></i> Volver</a>
</div>

<div class="row g-4">

<%-- ============ Reporte 1 ============ --%>
    <div class="col-12">
        <div class="card ims-card shadow-sm">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-1-circle me-1"></i> Propiedades disponibles: ciudad, tipo e inmobiliaria <span class="badge text-bg-primary align-middle">INNER JOIN &mdash; 4 tablas</span></div>
            <div class="card-body">
                <details class="small text-muted mb-3">
                    <summary class="fw-semibold">Ver SQL de este reporte</summary>
                    <pre class="bg-body-tertiary p-3 rounded-3 mt-2 mb-0"><code>SELECT p.titulo, tp.nombre_tipo, c.nombre_ciudad, i.nombre_comercial,
       p.precio, p.estado, p.fecha_publicacion
FROM propiedad p
INNER JOIN tipo_propiedad tp ON tp.id_tipo = p.id_tipo
INNER JOIN ciudad c       ON c.id_ciudad   = p.id_ciudad
INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria
WHERE p.estado = 'disponible'
ORDER BY p.id_propiedad;</code></pre>
                </details>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr><th scope="col">Propiedad</th><th scope="col">Tipo</th><th scope="col">Ciudad</th><th scope="col">Inmobiliaria</th><th scope="col">Precio</th><th scope="col">Estado</th><th scope="col">Publicada</th></tr>
                        </thead>
                        <tbody>
                        <% if (rPropCiudad.isEmpty()) { %>
                            <tr><td colspan="7" class="text-center text-muted py-4">Sin resultados.</td></tr>
                        <% } else { for (Object[] f : rPropCiudad) { %>
                            <tr>
                                <td class="fw-semibold"><%=esc((String) f[0])%></td>
                                <td><%=esc((String) f[1])%></td>
                                <td><%=esc((String) f[2])%></td>
                                <td><%=esc((String) f[3])%></td>
                                <td class="text-nowrap"><%=pesos(((Double) f[4]).doubleValue())%></td>
                                <td><span class="badge text-bg-<%=colorEstado((String) f[5])%>"><%=esc((String) f[5])%></span></td>
                                <td class="text-muted small"><%=esc((String) f[6])%></td>
                            </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

<%-- ============ Reporte 2 ============ --%>
    <div class="col-12">
        <div class="card ims-card shadow-sm">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-2-circle me-1"></i> Citas con su propiedad, cliente e inmobiliaria <span class="badge text-bg-primary align-middle">INNER JOIN &mdash; 5 tablas</span></div>
            <div class="card-body">
                <details class="small text-muted mb-3">
                    <summary class="fw-semibold">Ver SQL de este reporte</summary>
                    <pre class="bg-body-tertiary p-3 rounded-3 mt-2 mb-0"><code>SELECT ct.fecha_hora, ct.estado, p.titulo, i.nombre_comercial,
       u.correo, per.nombres, per.apellidos
FROM cita ct
INNER JOIN propiedad p    ON p.id_propiedad = ct.id_propiedad
INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria
INNER JOIN usuario u      ON u.id_usuario = ct.id_cliente
INNER JOIN perfil per     ON per.id_usuario = u.id_usuario
ORDER BY ct.fecha_hora DESC;</code></pre>
                </details>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr><th scope="col">Fecha</th><th scope="col">Estado</th><th scope="col">Propiedad</th><th scope="col">Inmobiliaria</th><th scope="col">Cliente</th></tr>
                        </thead>
                        <tbody>
                        <% if (rCitas.isEmpty()) { %>
                            <tr><td colspan="5" class="text-center text-muted py-4">Sin resultados.</td></tr>
                        <% } else { for (Object[] f : rCitas) {
                            String nombreCliente = (((String) f[5]).trim() + " " + ((String) f[6]).trim()).trim();
                            if (nombreCliente.isEmpty()) nombreCliente = (String) f[4];
                        %>
                            <tr>
                                <td class="text-nowrap"><%=esc((String) f[0])%></td>
                                <td><span class="badge text-bg-<%=colorEstado((String) f[1])%>"><%=esc((String) f[1])%></span></td>
                                <td class="fw-semibold"><%=esc((String) f[2])%></td>
                                <td><%=esc((String) f[3])%></td>
                                <td>
                                    <div class="fw-semibold"><%=esc(nombreCliente)%></div>
                                    <div class="small text-muted"><%=esc((String) f[4])%></div>
                                </td>
                            </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

<%-- ============ Reporte 3 ============ --%>
    <div class="col-12">
        <div class="card ims-card shadow-sm">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-3-circle me-1"></i> Caracteristicas de una propiedad (relacion N:M) <span class="badge text-bg-warning align-middle">propiedad_caracteristica</span></div>
            <div class="card-body">
                <form class="row g-2 align-items-center mb-3" method="get" action="<%=ctx%>/admin/reportes.jsp">
                    <div class="col-md-5">
                        <select class="form-select" name="prop" onchange="this.form.submit()">
                        <% for (Object[] p : propiedades) { %>
                            <option value="<%=((Integer) p[0]).intValue()%>" <%= ((Integer) p[0]).intValue() == idPropSel ? "selected" : "" %>><%=esc((String) p[1])%></option>
                        <% } %>
                        </select>
                    </div>
                    <div class="col-auto d-none d-md-block"><span class="text-muted small">Cambiar la propiedad y la tabla se refresca sola.</span></div>
                </form>
                <details class="small text-muted mb-3">
                    <summary class="fw-semibold">Ver SQL de este reporte</summary>
                    <pre class="bg-body-tertiary p-3 rounded-3 mt-2 mb-0"><code>SELECT c.nombre_caracteristica, pc.cantidad
FROM propiedad_caracteristica pc
INNER JOIN caracteristica c ON c.id_caracteristica = pc.id_caracteristica
WHERE pc.id_propiedad = ?
ORDER BY c.id_caracteristica;</code></pre>
                </details>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr><th scope="col">Caracteristica</th><th scope="col">Cantidad</th></tr>
                        </thead>
                        <tbody>
                        <% if (rCaractProp.isEmpty()) { %>
                            <tr><td colspan="2" class="text-center text-muted py-4">La propiedad seleccionada no tiene caracteristicas registradas.</td></tr>
                        <% } else { for (Object[] f : rCaractProp) { %>
                            <tr>
                                <td><%=esc((String) f[0])%></td>
                                <td><%=((Integer) f[1]).intValue()%></td>
                            </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

<%-- ============ Reporte 4 ============ --%>
    <div class="col-12">
        <div class="card ims-card shadow-sm">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-4-circle me-1"></i> Propiedades sin ninguna cita agendada <span class="badge text-bg-primary align-middle">LEFT JOIN</span></div>
            <div class="card-body">
                <details class="small text-muted mb-3">
                    <summary class="fw-semibold">Ver SQL de este reporte</summary>
                    <pre class="bg-body-tertiary p-3 rounded-3 mt-2 mb-0"><code>SELECT p.titulo, i.nombre_comercial, c.nombre_ciudad, p.estado
FROM propiedad p
INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria
INNER JOIN ciudad c       ON c.id_ciudad = p.id_ciudad
LEFT JOIN cita ct         ON ct.id_propiedad = p.id_propiedad
WHERE ct.id_cita IS NULL
ORDER BY p.id_propiedad;</code></pre>
                </details>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr><th scope="col">Propiedad</th><th scope="col">Inmobiliaria</th><th scope="col">Ciudad</th><th scope="col">Estado</th></tr>
                        </thead>
                        <tbody>
                        <% if (rSinCita.isEmpty()) { %>
                            <tr><td colspan="4" class="text-center text-muted py-4">Todas las propiedades tienen al menos una cita.</td></tr>
                        <% } else { for (Object[] f : rSinCita) { %>
                            <tr>
                                <td class="fw-semibold"><%=esc((String) f[0])%></td>
                                <td><%=esc((String) f[1])%></td>
                                <td><%=esc((String) f[2])%></td>
                                <td><span class="badge text-bg-<%=colorEstado((String) f[3])%>"><%=esc((String) f[3])%></span></td>
                            </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

<%-- ============ Reporte 5 ============ --%>
    <div class="col-12">
        <div class="card ims-card shadow-sm">
            <div class="card-header bg-transparent fw-bold"><i class="bi bi-5-circle me-1"></i> Propiedades disponibles por ciudad (solo ciudades con mas de una) <span class="badge text-bg-primary align-middle">GROUP BY + HAVING</span></div>
            <div class="card-body">
                <details class="small text-muted mb-3">
                    <summary class="fw-semibold">Ver SQL de este reporte</summary>
                    <pre class="bg-body-tertiary p-3 rounded-3 mt-2 mb-0"><code>SELECT c.nombre_ciudad, COUNT(p.id_propiedad) AS disponibles
FROM propiedad p
INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad
WHERE p.estado = 'disponible'
GROUP BY c.id_ciudad, c.nombre_ciudad
HAVING COUNT(p.id_propiedad) > 1
ORDER BY disponibles DESC, c.nombre_ciudad;</code></pre>
                </details>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr><th scope="col">Ciudad</th><th scope="col">Propiedades disponibles</th></tr>
                        </thead>
                        <tbody>
                        <% if (rPorCiudad.isEmpty()) { %>
                            <tr><td colspan="2" class="text-center text-muted py-4">Ninguna ciudad supera una propiedad disponible.</td></tr>
                        <% } else { for (Object[] f : rPorCiudad) { %>
                            <tr>
                                <td class="fw-semibold"><%=esc((String) f[0])%></td>
                                <td><span class="badge rounded-pill text-bg-success"><%=((Integer) f[1]).intValue()%></span></td>
                            </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

</div>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>