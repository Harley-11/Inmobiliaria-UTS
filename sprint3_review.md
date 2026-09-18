# Sprint 3 — Review

**Sprint:** 3 · Administración, reportes y documentación

Fecha: cierre de la semana 3 (entrega 18/09)

## Demostración (qué quedó funcionando y probado)

Todas las historias se probaron **de extremo a extremo** contra MySQL + Tomcat
en ejecución con la sesión real de `admin@inmobiliaria.com`.

| ID | Historia | Estado | Qué se demostró |
|---|---|---|---|
| US-15 | Listado de usuarios y roles | ✅ Terminada | Tabla con cuenta, nombre, documento, roles y estado; gestión de roles en línea (collapse por usuario). |
| US-16 | Asignar / revocar roles | ✅ Terminada | Se agregó el rol `inmobiliaria` a un cliente de prueba y se revirtió; la asignación quedó en `usuario_rol` y auditada (`GESTIONAR_ROL`). **Protección anti-lockout probada**: el admin no puede quitarse su propio rol administrador (err=3). |
| US-17 | Activar / inactivar cuentas | ✅ Terminada | Se activó un usuario inactivo y se volvió a inactivar; auditado. **Protección probada**: el admin no puede desactivar su propia cuenta (err=4). |
| US-18 | CRUD de catálogos | ✅ Terminada | Alta, edición y borrado de una ciudad de prueba (se creó, editó y eliminó limpiamente). **FK RESTRICT probada**: un catálogo en uso no se borra ("El registro está en uso"); **duplicado probado**: "Ya existe un registro con ese nombre" y la BD no duplicó la fila. |
| US-19 | Auditoría filtrable | ✅ Terminada | Filtros por usuario (solo muestra filas de ese usuario), por acción (`LOGIN`, `GESTIONAR_ROL`, ...) y por rango de fechas; SQL construido con `PreparedStatement`. |
| US-20 | Reportes | ✅ Terminada | Las 5 consultas generan tablas reales: propiedades ciudad/tipo/inmobiliaria; citas con cliente e inmobiliaria; N:M de características (selector de propiedad); propiedades **sin ninguna cita** (LEFT JOIN); y ciudades con **más de una** propiedad disponible (GROUP BY + HAVING). El SQL de cada una está comentado en `admin/reportes.jsp` y visible en la página. |
| US-21 | Documentación | ✅ Terminada | `docs/` completa (MER, modelo relacional, diccionario, sprints) con imágenes exportadas. |

**Cumplimiento del Sprint Goal:** ✅ completo — el rol administrador opera el
sistema completo, los reportes sustentan las consultas SQL exigidas y la
documentación acompaña el código.

## Bugs encontrados y corregidos durante el sprint (evidencia de iteración)

### Bug 5 — NullPointerException al eliminar un catálogo (`nombre = null`)
**Síntoma:** al pulsar **Eliminar** en `admin/catalogos.jsp` la acción
`catalogo_guardar.jsp` respondía **HTTP 500** (NullPointerException) y el
registro no se borraba.

**Causa:** con `accion = eliminar` el formulario no envía `nombre`; la acción
hacía `nombre.trim()` **antes** de saber si se trataba de un alta/edición
(que sí requieren nombre) o un borrado (que no lo usa).

**Corrección aplicada:** validar los parámetros según la acción (nombre solo
obligatorio en `crear`/`editar`) y normalizar de forma null-safe:
`String nombreLimpio = (nombre == null) ? "" : nombre.trim();`.

**Verificación:** repetición de la prueba → el DELETE de la ciudad de prueba
completa con redirección `ok=3` ("Registro eliminado correctamente") y la fila
desaparece de la BD.

### Bug 6 — Detección pobre de restricciones al borrar catálogos
**Síntoma:** al intentar borrar una ciudad/tipo/característica **en uso**, el
comportamiento era impredecible (excepción pasiva o mensaje genérico).

**Causa:** no se diferenciaba el motivo del rechazo de InnoDB.

**Corrección aplicada:** capturar `SQLIntegrityConstraintViolationException` y
distinguir por código de MySQL: **1062** (duplicado `UNIQUE`) → "Ya existe un
registro con ese nombre"; **1451 y afines** (FK RESTRICT) → "El registro está
en uso...". El `rollback` queda garantizado en ambos casos.

### Bug 7 — Detección de duplicados verificada en pruebas
Durante las pruebas E2E se validó que intentar crear un tipo ya existente
(`Apartamento`) redirige a `err=4` y **no inserta una segunda fila**
(comprobado con consulta `COUNT(*)` a la tabla `tipo_propiedad`).

## Métricas / estado al cierre

- Historias Sprint 3: 7/7 terminadas; bugs corregidos con verificación: 3 nuevos.
- Registro acumulado de bugs reales con su fix: 7 (commit, hash, getParts,
  doble cita, NPE eliminar, FK/duplicado, verificación de duplicado).
- Checklist de regresión del Sprint 2 corrida al cierre: ✅ sin regresiones.