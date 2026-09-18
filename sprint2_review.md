# Sprint 2 — Review

**Sprint:** 2 · Módulo inmobiliaria y módulo cliente

## Demostración (qué quedó funcionando y probado)

| ID | Historia | Estado | Qué se demostró |
|---|---|---|---|
| US-06 | Publicar / editar propiedad | ✅ Terminada | Alta y edición con catálogo de ciudades y tipos; solo propiedades de **mi** inmobiliaria son editables (validación por `id_inmobiliaria` del usuario). |
| US-07 | Estado de la propiedad | ✅ Terminada | Activar/desactivar (baja lógica); la propiedad `inactivo` deja de verse en el listado público pero permanece en la BD. |
| US-08 | Galería de imágenes | ✅ Terminada | Subir varias imágenes (multipart), elegir principal, eliminar; cada imagen con `orden`. |
| US-09 | Características N:M | ✅ Terminada | Checkboxes con cantidad; la relación se sincroniza (borrar + reinsertar) sobre la propiedad correcta. |
| US-10 | Bandeja de solicitudes | ✅ Terminada | La inmobiliaria ve solicitudes de **sus** propiedades con documentos adjuntos y las aprueba/rechaza solo si siguen `pendiente`. |
| US-11 | Citas del cliente | ✅ Terminada | Agendar, ver y cancelar citas; la unicidad por propiedad/fecha evita doble reserva. |
| US-12 | Solicitud con documentos | ✅ Terminada | Upload multipart a `documentos/`, registro en `documento_solicitud`, solicitud `pendiente`, con validación de extensión y tamaño. |
| US-13 | Favoritos | ✅ Terminada | Marcar/desmarcar y listado de mis favoritos. |
| US-14 | Perfil editable | ✅ Terminada | Actualización transaccional de nombres/contacto/foto. |

**Cumplimiento del Sprint Goal:** ✅ completo — ambos módulos operativos
funcionan contra la BD con sus usuarios de prueba.

## Bugs encontrados y corregidos durante el sprint

### Bug 3 — `request.getParts()` en el formulario multipart de solicitudes
**Síntoma:** al radicar una solicitud de compra/arriendo con documentos, los
parámetros de texto (`propiedad`, `tipo`) llegaban **nulos** al servlet/JSP y
el flujo se cortaba o creaba solicitudes sin datos.

**Causa:** en un `POST multipart/form-data` los campos no viajan como
parámetros normales; pedir `request.getParameter()` **antes** de disparar el
parseo del `multipart` devolvía `null`.

**Corrección aplicada:** invocar `request.getParts()` primero (que fuerza el
parseo multipart) y **después** leer los parámetros de texto, tal como quedó
documentado en `cliente/guardar_solicitud.jsp` (comentario en la línea 40).
Además se configuró el `multipart-config` del servlet JSP en `WEB-INF/web.xml`
(tamaños máximos de 8 MB por archivo).

**Verificación:** envío real de una solicitud con 2 documentos adjuntos →
`solicitud` `pendiente` + 2 filas en `documento_solicitud`; los archivos
existen bajo `documentos/solicitud_XX/`.

### Bug 4 — Doble cita sobre la misma propiedad a la misma hora
**Síntoma:** se podía agendar una cita que chocaba de fecha y hora con otra
existente, rompiendo la agenda.

**Causa:** el alta no validaba el conflicto antes del INSERT (confiando solo en
la UK, que en su versión inicial no existía).

**Corrección:** se definió la restricción `UNIQUE (id_propiedad, fecha_hora)`
en `cita` y se captura la violación en la acción, mostrando un mensaje claro al
cliente ("Ya existe una cita para esa propiedad en esa fecha y hora").

## Métricas / estado al cierre

- Funcionalidad cubierta: 9/9 historias del sprint.
- Archivos nuevos en `agente/` y `cliente/`: ~20 JSP (listados, formularios,
  acciones POST dedicadas).
- Reutilización: todas las acciones usan el patrón transaccional estándar.
- La galería y los documentos se almacenan en el propio contexto web de Tomcat
  (`img/` y `documentos/`).