# Sprint 1 — Review

**Sprint:** 1 · Fundaciones (base de datos, autenticación, catálogo público)

## Demostración (qué quedó funcionando y probado)

| ID | Historia | Estado | Qué se demostró |
|---|---|---|---|
| US-01 | Esquema DDL + DML | ✅ Terminada | Las 16 tablas creadas con PK/FK/UK e índices; `02_DML` carga roles, usuarios (clave `1234` para los de prueba), inmobiliarias, propiedades, características, citas, solicitudes, favoritos y auditoría. |
| US-02 | Registro de cliente | ✅ Terminada | Un visitante se registra y la cuenta nace con rol `cliente` (fijo en el servidor, no en el form). El registro es transaccional: usuario → perfil → usuario_rol. Correo duplicado muestra mensaje controlado. |
| US-03 | Login / logout | ✅ Terminada | Sesión con roles CSV; inicio correcto redirige al panel según rol; **usuario inactivo bloqueado**; se auditan `LOGIN` y `BLOQUEO_LOGIN`. |
| US-04 | Seguridad por rol | ✅ Terminada | Acceso a `/admin/*`, `/agente/*`, `/cliente/*` validado por `SeguridadFilter`; usuario sin permiso es desviado a `acceso-denegado.jsp`. |
| US-05 | Catálogo público | ✅ Terminada | Solo propiedades `disponible` en listado y detalle con galería y características. |

**Cumplimiento del Sprint Goal:** ✅ completo — la base con autenticación
segura y vitrina pública funciona de punta a punta.

## Bugs encontrados y corregidos durante el sprint

### Bug 1 — El "bug del commit" (transacciones que no aseguraban la escritura)
**Síntoma:** en el registro, al revisar la BD la cuenta aparecía sin perfil o,
en el peor caso, la operación completa se perdía pese a mostrar "registro
exitoso".

**Causa:** se desactivaba el autocommit del `Connection` pero la confirmación
(`commit()`) no quedaba garantizada antes de redirigir; al cerrarse la
conexión sin `commit` efectivo, MySQL descartaba los cambios de la transacción
o los dejaba a medias.

**Corrección aplicada:**
- `setAutoCommit(false)` + `commit()` explícito **antes** del `sendRedirect` de
  éxito en `guardar_registro.jsp`.
- `rollback()` (helper `deshacer()`) en cada bloque `catch`.
- Captura de `SQLIntegrityConstraintViolationException` para el correo
  duplicado (enunciado del proyecto) en lugar de dejarla estallar al usuario.

**Verificación:** registro real con cuenta nueva → los tres INSERTs persisten
(`usuario`, `perfil`, `usuario_rol`); intento con correo repetido → mensaje
"El correo ya se encuentra registrado" y nada queda a medias.

### Bug 2 — Hash de clave comparado de forma incompleta
**Síntoma:** las claves guardadas no coincidían al autenticar según el patrón
documentado.

**Causa:** el cálculo del hash no incluía el correo (patrón `correo:clave`).

**Corrección:** centralizar la lógica en `claveCifrada(correo, clave)` dentro
del fragmento compartido `utilidades.jspf` y usarlo tanto en el alta como en
la validación del login, garantizando que ambos lados usen el mismo algoritmo.

## Métricas / estado al cierre

- Tablas creadas: 16/16.
- Scripts SQL: 2 ejecutados limpios (DDL + DML).
- Páginas funcionales: registro, login, logout, catálogo público, detalle.
- Fragmentos reutilizables creados: `seguridad`, `conexion`, `cabecera`,
  `utilidades`, `pie` (`.jspf`).
- Registros de auditoría generados con datos de prueba y con uso real.