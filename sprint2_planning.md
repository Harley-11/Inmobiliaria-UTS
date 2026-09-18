# Sprint 2 — Planning

**Proyecto:** Inmobiliaria UTS
**Objetivo del sprint (Sprint Goal):** construir los dos módulos productivos
restantes: el panel de la **inmobiliaria** (gestión de propiedades, galería,
características, bandeja de solicitudes) y el panel del **cliente** (citas,
solicitudes con documentos, favoritos, perfil).

**Duración:** 7 días (semanas 2)

**Backlog del Sprint 2:**

| ID | Historia de usuario | Criterios de aceptación (Definition of Done) |
|---|---|---|
| US-06 | **Como inmobiliaria, quiero publicar y editar mis propiedades** (título, descripción, precio, ciudad, tipo, dirección, matrícula). | El CRUD valida que las propiedades solo pertenezcan a la inmobiliaria de la sesión (`esPropiedadDeInmobiliaria`); la matrícula es única; los datos maestros (ciudad/tipo) vienen de catálogo; las operaciones son transaccionales. |
| US-07 | **Como inmobiliaria, quiero cambiar el estado de una propiedad** (disponible / inactivo) sin borrarla. | Baja lógica mediante `estado`; una propiedad `inactivo` desaparece del listado público; se usa un botón de activar/desactivar protegido por pertenencia. |
| US-08 | **Como inmobiliaria, quiero subir la galería de imágenes** y elegir la principal. | Upload multipart a la carpeta del contexto; cada imagen es un registro en `imagen_propiedad` con `orden`; imagen principal seleccionable; eliminar imagen; todo validado por pertenencia. |
| US-09 | **Como inmobiliaria, quiero asignar características con cantidad** a cada propiedad. | La N:M `propiedad_caracteristica` se actualiza por "sincronización" (borrar + insertar lo marcado con cantidad); solo sobre propiedades propias. |
| US-10 | **Como inmobiliaria, quiero aprobar o rechazar las solicitudes** recibidas sobre mis propiedades. | La bandeja muestra solicitudes de propiedades de mi inmobiliaria con sus documentos; se cambia `estado` a `aprobada`/`rechazada` solo si sigue `pendiente`; todo queda auditado. |
| US-11 | **Como cliente, quiero agendar una cita de visita** a una propiedad. | Se valida que la propiedad exista y esté disponible; **no se permiten dos citas sobre la misma propiedad a la misma hora** (UK `(id_propiedad, fecha_hora)`); el cliente puede ver y **cancelar** sus citas. |
| US-12 | **Como cliente, quiero radicar una solicitud de compra o arriendo** adjuntando documentos. | Formulario multipart; se leen los parámetros de texto **después** de disparar el parseo (`getParts()`); los archivos se guardan en `documentos/` con extensión permitida y su registro en `documento_solicitud`; solicitud nace `pendiente`. |
| US-13 | **Como cliente, quiero marcar propiedades como favoritas** y ver mi lista. | Toggle inserta/elimina en `favorito` (PK compuesta); “Mis favoritos” lista las propiedades marcadas con enlace al detalle. |
| US-14 | **Como cliente, quiero editar mi perfil** (teléfono, dirección, foto). | Actualización transaccional de `perfil`; los datos se reflejan en el encabezado y paneles tras recargar. |

**Definition of Done (transversal):**

1. Cada historia probada E2E con usuario real (rol `inmobiliaria` y `cliente`
   de los datos de prueba, clave `1234`).
2. Cada operación de escritura transaccional con rollback en error (norma del
   Sprint 1).
3. Pertenencias validadas en el servidor (no solo ocultar botones en la UI).
4. Auditoría registrada (CREAR_PROP, CARACTERISTICA, APROBAR/CREAR_SOLIC,
   CREAR_CITA, etc.).