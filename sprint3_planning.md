# Sprint 3 — Planning

**Proyecto:** Inmobiliaria UTS
**Objetivo del sprint (Sprint Goal):** completar el rol **administrador**,
el módulo de **reportes** para la sustentación y el cierre de la **documentación**
(MER, modelo relacional, diccionario y retrospectivas), dejando el entregable
listo antes del 18 de septiembre.

**Duración:** 6 días (semanas 3)

**Backlog del Sprint 3:**

| ID | Historia de usuario | Criterios de aceptación (Definition of Done) |
|---|---|---|
| US-15 | **Como administrador, quiero ver todos los usuarios con sus roles**, para gestionar el sistema. | Listado con correo, nombre, documento, roles (badges) y estado; protegido bajo `/admin/*`. |
| US-16 | **Como administrador, quiero asignar y revocar roles** (tabla `usuario_rol`). | Es la **única vía** para crear cuentas `administrador` o `inmobiliaria` (el registro público es fijo a `cliente`); la operación sincroniza los roles marcados por checkbox; transaccional y auditada; **un administrador no puede quitarse su propio rol administrador** (protección anti-lockout). |
| US-17 | **Como administrador, quiero activar o inactivar cuentas** (campo `estado`). | Cambio transaccional y auditado (`ACTIVAR_USUARIO` / `INACTIVAR_USUARIO`); la cuenta desactivada no puede iniciar sesión; **no se permite desactivar la propia cuenta**. |
| US-18 | **Como administrador, quiero parametrizar catálogos** (ciudad, tipo_propiedad, característica). | CRUD simple (crear/editar/eliminar + listado) para las 3 tablas; los registros en uso por FK **no se pueden eliminar** (mensaje controlado, no excepción); los nombres duplicados (UNIQUE) se detectan y avisan. |
| US-19 | **Como administrador, quiero consultar la auditoría** de forma filtrable. | Listado de `auditoria` con filtros por **usuario, tipo de acción y rango de fechas**; construido con `PreparedStatement` (sin concatenar valores). |
| US-20 | **Como sustentante, quiero un módulo de reportes** con las consultas exigidas. | Cinco consultas documentadas: (1) INNER JOIN 3+ tablas: propiedades con ciudad/tipo/inmobiliaria; (2) INNER JOIN: citas con propiedad/cliente/inmobiliaria; (3) N:M: características de una propiedad; (4) LEFT JOIN: propiedades sin cita; (5) GROUP BY + HAVING: disponibles por ciudad con >1 propiedad. **El SQL de cada una está comentado en el código** para poder explicarlo en la sustentación. |
| US-21 | **Como estudiante, quiero la documentación técnica** del proyecto. | `mer.md` + `mer.png` (diagrama Mermaid exportado), `modelo_relacional.md` + `.png`, `diccionario_datos.md`, y planning/review/retrospective por sprint en `docs/`. |

**Definition of Done (transversal):**

1. Todo el panel admin probado E2E con el usuario `admin@inmobiliaria.com`
   (clave `1234`), incluidas las protecciones (self-admin, FK en uso,
   duplicados).
2. Reportes con su SQL comentado y visible en la página.
3. Documentos dentro de `docs/`, sin mezclar con `documentos/` (que es para
   los PDFs de las solicitudes de los clientes).
4. Checklist de regresión del Sprint 2 corrida al cierre.