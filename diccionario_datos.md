# Diccionario de Datos de INMOBILIARIA UTS

Diccionario extraído del DDL (`sql/01_DDL_inmobiliaria_uts.sql`) y de la lógica
de negocio del proyecto. Motor: **MySQL / MariaDB (XAMPP)**, charset
`utf8mb4` / `utf8mb4_unicode_ci`.

Convenciones: **PK** = llave primaria, **FK** = foránea, **UK** = única,
**NN** = NOT NULL, **AI** = AUTO_INCREMENT. Las FKs indican tabla referenciada
y política `ON DELETE`.

---

## 1. `rol`

Catálogo de roles del sistema. El registro público siempre crea usuarios con
rol `cliente`; los roles `administrador` e `inmobiliaria` solo pueden
asignarse desde el panel de administración.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_rol` | INT | PK, NN, AI | Identificador único del rol. |
| `nombre_rol` | VARCHAR(30) | NN, UK | Nombre del rol: `administrador`, `inmobiliaria`, `cliente`. |

---

## 2. `usuario`

Cuentas del sistema (autenticación). Guarda credenciales con hash y estado de
la cuenta; los datos personales viven en `perfil`.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_usuario` | INT | PK, NN, AI | Identificador único de la cuenta. |
| `correo` | VARCHAR(100) | NN, UK | Correo electrónico único, usado para iniciar sesión. |
| `contrasena_hash` | VARCHAR(255) | NN | Hash SHA-256 del patrón `correo:clave` en minúsculas (nunca clave en texto plano). |
| `estado` | VARCHAR(20) | NN, DEFAULT `'activo'` | Estado de la cuenta: `activo` / `inactivo`. `inactivo` bloquea el login (baja lógica). |
| `fecha_registro` | DATETIME | NN, DEFAULT `CURRENT_TIMESTAMP` | Fecha y hora en que se creó la cuenta. |

---

## 3. `usuario_rol`

Tabla puente que resuelve la relación **N:M** entre `usuario` y `rol`.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_usuario` | INT | PK (compuesta), FK → `usuario(id_usuario)` CASCADE | Usuario al que se asigna el rol. |
| `id_rol` | INT | PK (compuesta), FK → `rol(id_rol)` CASCADE | Rol asignado. |

---

## 4. `perfil`

Datos personales del usuario. Relación **1:1** con `usuario`.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_perfil` | INT | PK, NN, AI | Identificador único del perfil. |
| `id_usuario` | INT | NN, FK → `usuario(id_usuario)` CASCADE, UK | Cuenta dueña del perfil (única por usuario). |
| `nombres` | VARCHAR(60) | NN | Nombres de la persona. |
| `apellidos` | VARCHAR(60) | NN | Apellidos de la persona. |
| `documento` | VARCHAR(20) | NN | Documento de identidad. |
| `telefono` | VARCHAR(15) | NULL | Teléfono de contacto. |
| `direccion` | VARCHAR(150) | NULL | Dirección de residencia. |
| `foto` | VARCHAR(255) | NULL | URL de la foto de perfil. |

---

## 5. `inmobiliaria`

Inmobiliaria operada por un usuario (relación **1:1** con `usuario`). Dueña de
las propiedades publicadas.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_inmobiliaria` | INT | PK, NN, AI | Identificador único de la inmobiliaria. |
| `id_usuario` | INT | NN, FK → `usuario(id_usuario)` RESTRICT, UK | Cuenta raíz de la inmobiliaria (única). No se puede borrar la cuenta si posee inmobiliaria. |
| `nombre_comercial` | VARCHAR(100) | NN | Razón o nombre comercial. |
| `nit` | VARCHAR(20) | UK, NULL | NIT de la inmobiliaria. |

---

## 6. `ciudad`

Catálogo de ciudades (parametrizable desde el panel de administración).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_ciudad` | INT | PK, NN, AI | Identificador único de la ciudad. |
| `nombre_ciudad` | VARCHAR(60) | NN | Nombre de la ciudad. |
| `departamento` | VARCHAR(60) | NULL | Departamento al que pertenece. |

---

## 7. `tipo_propiedad`

Catálogo de tipos de propiedad (apartamento, casa, local, etc.).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_tipo` | INT | PK, NN, AI | Identificador único del tipo. |
| `nombre_tipo` | VARCHAR(30) | NN, UK | Nombre del tipo de propiedad. |

---

## 8. `propiedad`

Bien inmueble publicado por una inmobiliaria. Su estado controla la
visibilidad pública.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_propiedad` | INT | PK, NN, AI | Identificador único de la propiedad. |
| `id_inmobiliaria` | INT | NN, FK → `inmobiliaria(id_inmobiliaria)` CASCADE | Inmobiliaria propietaria del aviso. |
| `id_ciudad` | INT | NN, FK → `ciudad(id_ciudad)` RESTRICT | Ciudad donde se ubica. No se puede borrar una ciudad en uso. |
| `id_tipo` | INT | NN, FK → `tipo_propiedad(id_tipo)` RESTRICT | Tipo de propiedad. |
| `matricula_inmobiliaria` | VARCHAR(30) | NN, UK | Matrícula inmobiliaria, identificador oficial único. |
| `titulo` | VARCHAR(120) | NN | Título corto del aviso. |
| `descripcion` | TEXT | NULL | Descripción ampliada del inmueble. |
| `precio` | DECIMAL(12,2) | NN | Precio de venta o arriendo en pesos. |
| `direccion` | VARCHAR(150) | NULL | Dirección del inmueble. |
| `estado` | VARCHAR(20) | NN, DEFAULT `'disponible'` | `disponible` / `arrendado` / `vendido` / `inactivo`. Solo `disponible` se muestra en el listado público. |
| `fecha_publicacion` | DATETIME | NN, DEFAULT `CURRENT_TIMESTAMP` | Fecha de publicación del aviso. |

---

## 9. `imagen_propiedad`

Galería de imágenes de una propiedad (1:N).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_imagen` | INT | PK, NN, AI | Identificador único de la imagen. |
| `id_propiedad` | INT | NN, FK → `propiedad(id_propiedad)` CASCADE | Propiedad a la que pertenece la imagen. |
| `url_imagen` | VARCHAR(255) | NN | URL del archivo de imagen. |
| `orden` | INT | NN, DEFAULT `1` | Orden de visualización en la galería. |

---

## 10. `caracteristica`

Catálogo de características medibles (habitaciones, baños, estrato, etc.).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_caracteristica` | INT | PK, NN, AI | Identificador único de la característica. |
| `nombre_caracteristica` | VARCHAR(50) | NN, UK | Nombre de la característica. |

---

## 11. `propiedad_caracteristica`

Tabla puente de la relación **N:M** entre `propiedad` y `caracteristica`, con
valor numérico (`cantidad`).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_propiedad` | INT | PK (compuesta), FK → `propiedad(id_propiedad)` CASCADE | Propiedad asociada. |
| `id_caracteristica` | INT | PK (compuesta), FK → `caracteristica(id_caracteristica)` CASCADE | Característica asociada. |
| `cantidad` | INT | NN, DEFAULT `1` | Valor de la característica para esa propiedad (p. ej. 3 habitaciones). |

---

## 12. `cita`

Visita agendada por un cliente sobre una propiedad.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_cita` | INT | PK, NN, AI | Identificador único de la cita. |
| `id_propiedad` | INT | NN, FK → `propiedad(id_propiedad)` CASCADE | Propiedad que se visita. |
| `id_cliente` | INT | NN, FK → `usuario(id_usuario)` CASCADE | Cliente que agenda la visita. |
| `fecha_hora` | DATETIME | NN | Fecha y hora de la visita. |
| `estado` | VARCHAR(20) | NN, DEFAULT `'pendiente'` | `pendiente` / `confirmada` / `cancelada`. |

Restricción adicional: `UNIQUE (id_propiedad, fecha_hora)` evita dos citas
sobre la misma propiedad a la misma hora.

---

## 13. `solicitud`

Solicitud de compra o arriendo de un cliente sobre una propiedad.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_solicitud` | INT | PK, NN, AI | Identificador único de la solicitud. |
| `id_propiedad` | INT | NN, FK → `propiedad(id_propiedad)` CASCADE, índice | Propiedad solicitada. |
| `id_cliente` | INT | NN, FK → `usuario(id_usuario)` CASCADE, índice | Cliente que radica la solicitud. |
| `tipo` | VARCHAR(20) | NN | `compra` o `arriendo`. |
| `estado` | VARCHAR(20) | NN, DEFAULT `'pendiente'` | `pendiente` / `aprobada` / `rechazada`. |
| `fecha_solicitud` | DATETIME | NN, DEFAULT `CURRENT_TIMESTAMP` | Fecha de radicación. |

---

## 14. `documento_solicitud`

Documentos adjuntos a una solicitud (1:N). Los archivos se guardan en la
carpeta física `documentos/` del contexto web.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_documento` | INT | PK, NN, AI | Identificador único del documento. |
| `id_solicitud` | INT | NN, FK → `solicitud(id_solicitud)` CASCADE | Solicitud a la que pertenece el adjunto. |
| `tipo_documento` | VARCHAR(50) | NN | Tipo: cédula, certificado laboral, extracto, etc. |
| `url_archivo` | VARCHAR(255) | NN | Ruta del archivo almacenado. |
| `fecha_carga` | DATETIME | NN, DEFAULT `CURRENT_TIMESTAMP` | Fecha de carga del documento. |

---

## 15. `favorito`

Tabla puente de la relación **N:M** entre `usuario` (cliente) y `propiedad`.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_usuario` | INT | PK (compuesta), FK → `usuario(id_usuario)` CASCADE | Cliente que marca el favorito. |
| `id_propiedad` | INT | PK (compuesta), FK → `propiedad(id_propiedad)` CASCADE | Propiedad marcada. |
| `fecha_marcado` | DATETIME | NN, DEFAULT `CURRENT_TIMESTAMP` | Fecha en que se marcó como favorita. |

---

## 16. `auditoria`

Trazabilidad de acciones relevantes del sistema (login, crear/editar/eliminar,
cambios de estado, gestión de roles).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id_auditoria` | INT | PK, NN, AI | Identificador único del registro. |
| `id_usuario` | INT | NN, FK → `usuario(id_usuario)` RESTRICT, índice | Usuario que ejecutó la acción. No se puede borrar un usuario con trazas. |
| `accion` | VARCHAR(100) | NN | Tipo de acción: `LOGIN`, `BLOQUEO_LOGIN`, `CREAR_PROP`, `CREAR_SOLIC`, `APROBAR_CITA`, `GESTIONAR_ROL`, `ACTIVAR_USUARIO`, `CREAR_CATALOGO`, etc. |
| `fecha_hora` | DATETIME | NN, DEFAULT `CURRENT_TIMESTAMP` | Fecha y hora del evento. |
| `detalle` | TEXT | NULL | Descripción libre del evento (qué recurso y qué se hizo). |