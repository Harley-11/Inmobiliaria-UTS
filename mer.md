# MER — Modelo Entidad-Relación de INMOBILIARIA UTS

Diagrama en sintaxis Mermaid (puedes abrirlo en GitHub, GitLab o VS Code con
la extensión *Mermaid*, o verlo renderizado en `mer.png`).

## 1. Diagrama (Mermaid)

```mermaid
erDiagram
    ROL ||--o{ USUARIO_ROL : "asigna"
    USUARIO ||--o{ USUARIO_ROL : "tiene"

    USUARIO ||--|| PERFIL : "posee"
    USUARIO ||--o| INMOBILIARIA : "opera"

    INMOBILIARIA ||--o{ PROPIEDAD : "publica"
    CIUDAD ||--o{ PROPIEDAD : "ubica"
    TIPO_PROPIEDAD ||--o{ PROPIEDAD : "clasifica"

    PROPIEDAD ||--o{ IMAGEN_PROPIEDAD : "muestra"
    PROPIEDAD ||--o{ PROPIEDAD_CARACTERISTICA : "tiene"
    CARACTERISTICA ||--o{ PROPIEDAD_CARACTERISTICA : "describe"

    PROPIEDAD ||--o{ CITA : "recibe"
    USUARIO ||--o{ CITA : "cliente agenda"

    PROPIEDAD ||--o{ SOLICITUD : "recibe"
    USUARIO ||--o{ SOLICITUD : "cliente radica"
    SOLICITUD ||--o{ DOCUMENTO_SOLICITUD : "adjunta"

    USUARIO ||--o{ FAVORITO : "marca"
    PROPIEDAD ||--o{ FAVORITO : "es favorita de"

    USUARIO ||--o{ AUDITORIA : "origina"

    ROL {
        int id_rol PK
        varchar(30) nombre_rol UK
    }
    USUARIO {
        int id_usuario PK
        varchar(100) correo UK
        varchar(255) contrasena_hash
        varchar(20) estado
        datetime fecha_registro
    }
    USUARIO_ROL {
        int id_usuario PK,FK
        int id_rol PK,FK
    }
    PERFIL {
        int id_perfil PK
        int id_usuario FK,UK
        varchar(60) nombres
        varchar(60) apellidos
        varchar(20) documento
        varchar(15) telefono
        varchar(150) direccion
        varchar(255) foto
    }
    INMOBILIARIA {
        int id_inmobiliaria PK
        int id_usuario FK,UK
        varchar(100) nombre_comercial
        varchar(20) nit UK
    }
    CIUDAD {
        int id_ciudad PK
        varchar(60) nombre_ciudad
        varchar(60) departamento
    }
    TIPO_PROPIEDAD {
        int id_tipo PK
        varchar(30) nombre_tipo UK
    }
    PROPIEDAD {
        int id_propiedad PK
        int id_inmobiliaria FK
        int id_ciudad FK
        int id_tipo FK
        varchar(30) matricula_inmobiliaria UK
        varchar(120) titulo
        text descripcion
        decimal(12,2) precio
        varchar(150) direccion
        varchar(20) estado
        datetime fecha_publicacion
    }
    IMAGEN_PROPIEDAD {
        int id_imagen PK
        int id_propiedad FK
        varchar(255) url_imagen
        int orden
    }
    CARACTERISTICA {
        int id_caracteristica PK
        varchar(50) nombre_caracteristica UK
    }
    PROPIEDAD_CARACTERISTICA {
        int id_propiedad PK,FK
        int id_caracteristica PK,FK
        int cantidad
    }
    CITA {
        int id_cita PK
        int id_propiedad FK
        int id_cliente FK
        datetime fecha_hora
        varchar(20) estado
    }
    SOLICITUD {
        int id_solicitud PK
        int id_propiedad FK
        int id_cliente FK
        varchar(20) tipo
        varchar(20) estado
        datetime fecha_solicitud
    }
    DOCUMENTO_SOLICITUD {
        int id_documento PK
        int id_solicitud FK
        varchar(50) tipo_documento
        varchar(255) url_archivo
        datetime fecha_carga
    }
    FAVORITO {
        int id_usuario PK,FK
        int id_propiedad PK,FK
        datetime fecha_marcado
    }
    AUDITORIA {
        int id_auditoria PK
        int id_usuario FK
        varchar(100) accion
        datetime fecha_hora
        text detalle
    }
```

## 2. Tabla de relaciones y cardinalidades

| # | Origen | Destino | Cardinalidad | Tipo | Clave involucrada / comentario |
|---|--------|---------|:---:|:---:|---|
| R1 | `rol` | `usuario_rol` | 1 : N | —— | un rol se asigna a muchos `usuario_rol` |
| R2 | `usuario` | `usuario_rol` | 1 : N | —— | un usuario puede tener varios `usuario_rol` |
| R3 | `usuario` | `rol` | **N : M** | N:M | se resuelve con la tabla intermedia `usuario_rol` (R1 + R2) |
| R4 | `usuario` | `perfil` | **1 : 1** | 1:1 | `perfil.id_usuario` es `UNIQUE` |
| R5 | `usuario` | `inmobiliaria` | **1 : 1** | 1:1 | `inmobiliaria.id_usuario` es `UNIQUE` (0..1 por usuario) |
| R6 | `inmobiliaria` | `propiedad` | 1 : N | 1:N | `propiedad.id_inmobiliaria` |
| R7 | `ciudad` | `propiedad` | 1 : N | 1:N | `propiedad.id_ciudad` |
| R8 | `tipo_propiedad` | `propiedad` | 1 : N | 1:N | `propiedad.id_tipo` |
| R9 | `propiedad` | `imagen_propiedad` | 1 : N | 1:N | `imagen_propiedad.id_propiedad` |
| R10 | `propiedad` | `propiedad_caracteristica` | 1 : N | —— | la N:M se apoya en esta intermedia |
| R11 | `caracteristica` | `propiedad_caracteristica` | 1 : N | —— | ídem |
| R12 | `propiedad` | `caracteristica` | **N : M** | N:M | se resuelve con `propiedad_caracteristica` (R10 + R11), con la columna `cantidad` |
| R13 | `propiedad` | `cita` | 1 : N | 1:N | `cita.id_propiedad` |
| R14 | `usuario` (cliente) | `cita` | 1 : N | 1:N | `cita.id_cliente` |
| R15 | `propiedad` | `solicitud` | 1 : N | 1:N | `solicitud.id_propiedad` |
| R16 | `usuario` (cliente) | `solicitud` | 1 : N | 1:N | `solicitud.id_cliente` |
| R17 | `solicitud` | `documento_solicitud` | 1 : N | 1:N | `documento_solicitud.id_solicitud` |
| R18 | `usuario` | `favorito` | 1 : N | —— | la N:M se apoya en esta intermedia |
| R19 | `propiedad` | `favorito` | 1 : N | —— | ídem |
| R20 | `usuario` | `propiedad` | **N : M** | N:M | se resuelve con `favorito` (R18 + R19) |
| R21 | `usuario` | `auditoria` | 1 : N | 1:N | `auditoria.id_usuario` |

## 3. Resumen de tipos de cardinalidad

- **1:1 (2)**: `usuario–perfil`, `usuario–inmobiliaria`.
- **1:N (12)**: R1, R2, R6–R11, R13–R17, R21 (las cabeceras padre → tabla hija).
- **N:M (3)**: `usuario–rol` (vía `usuario_rol`), `propiedad–caracteristica` (vía `propiedad_caracteristica`), `usuario–propiedad` (vía `favorito`).

Las tres relaciones N:M se materializan con **tablas puente de llave primaria
compuesta**, que es lo que se refleja en el modelo relacional
(`docs/modelo_relacional.md`).