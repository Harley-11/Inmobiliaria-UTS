# Sprint 1 — Planning

**Proyecto:** Inmobiliaria UTS
**Objetivo del sprint (Sprint Goal):** sentar las fundaciones del sistema:
base de datos completa, autenticación segura por roles y el catálogo público
de propiedades.

**Duración:** 5 días (semanas 1)

**Equipo:** 1 desarrolladora (autonomía total sobre frontend + backend JSP/MySQL)

**Backlog del Sprint 1** (elementos comprometidos):

| ID | Historia de usuario | Criterios de aceptación (Definition of Done) |
|---|---|---|
| US-01 | **Como administradora del esquema, quiero un script DDL y uno DML** que creen toda la BD con datos de prueba, para tener una base instalable. | El script `01_DDL` crea las **16 tablas** con PK, FK, UK e índices; `02_DML` inserta roles, usuarios, inmobiliarias, propiedades y datos de prueba; ambos se ejecutan sin errores en MySQL (XAMPP); las políticas ON DELETE CASCADE/RESTRICT están documentadas en comentarios. |
| US-02 | **Como visitante, quiero registrarme como cliente** con correo y clave, para poder comprar o arrendar después. | Se crean **usuario + perfil + usuario_rol** (rol fijo `cliente`) en una sola transacción; la clave se guarda como **SHA-256 de `correo:clave`** (nunca texto plano); el correo duplicado muestra "El correo ya se encuentra registrado" (sin excepción cruda); **el rol no se lee del request** (un atacante no puede autoasignarse administrador/inmobiliaria). |
| US-03 | **Como usuario, quiero iniciar y cerrar sesión**, para entrar a mi panel según mi rol. | El login compara el hash, valida el estado de la cuenta (inactivo → rechazado), guarda en sesión `idUsuario`, `nombre`, `correo`, `rol` (principal) y `roles` (CSV); se audita `LOGIN` exitoso y `BLOQUEO_LOGIN` fallido; el logout invalida la sesión. |
| US-04 | **Como administradora del sistema, quiero proteger las secciones por rol**, para que cada perfil solo vea lo suyo. | `SeguridadFilter` protege `/admin/*`, `/agente/*` y `/cliente/*`; sin sesión se redirige a `acceso-denegado.jsp?motivo=sesion`; con rol incorrecto a `acceso-denegado.jsp?motivo=rol`; el menú se adapta al rol activo. |
| US-05 | **Como visitante, quiero ver las propiedades disponibles** y su detalle, para decidir si me interesan. | El listado público solo muestra propiedades con `estado = 'disponible'`; el detalle muestra galería, características y datos; hay layout compartido (cabecera/pie). |

**Definition of Done (transversal para todo el sprint):**

1. Código JSP/servlets funcional probado de extremo a extremo en Tomcat + MySQL.
2. Sin excepciones crudas al usuario (mensajes controlados).
3. Auditoría registrada en acciones relevantes.
4. Comentario de cabecera en cada archivo explicando su responsabilidad.