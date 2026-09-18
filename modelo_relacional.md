# Modelo Relacional de INMOBILIARIA UTS

Versión en prosa del esquema de base de datos. El diagrama relación-tabla
exportado está en `modelo_relacional.png` y el código Mermaid fuente en
`mer.md`. La definición física (DDL) vive en `sql/01_DDL_inmobiliaria_uts.sql`.

## 1. Notación

- **PK** — llave primaria. **FK** — llave foránea. **UK** — llave única (candidata).
- `FK → tabla(destino)` indica a qué llave referencia y, entre paréntesis, la
  política `ON DELETE` aplicada.
- Las FKs de tablas puente llevan `PK,FK` (llave primaria compuesta).

## 2. Esquema resumido

```
rol(id_rol PK, nombre_rol UK)
usuario(id_usuario PK, correo UK, contrasena_hash, estado, fecha_registro)
usuario_rol(id_usuario PK,FK→usuario(CASCADE), id_rol PK,FK→rol(CASCADE))
perfil(id_perfil PK, id_usuario FK→usuario(CASCADE) UK, nombres, apellidos,
       documento, telefono, direccion, foto)
inmobiliaria(id_inmobiliaria PK, id_usuario FK→usuario(RESTRICT) UK,
             nombre_comercial, nit UK)
ciudad(id_ciudad PK, nombre_ciudad, departamento)
tipo_propiedad(id_tipo PK, nombre_tipo UK)
propiedad(id_propiedad PK, id_inmobiliaria FK→inmobiliaria(CASCADE),
          id_ciudad FK→ciudad(RESTRICT), id_tipo FK→tipo_propiedad(RESTRICT),
          matricula_inmobiliaria UK, titulo, descripcion, precio, direccion,
          estado, fecha_publicacion)
imagen_propiedad(id_imagen PK, id_propiedad FK→propiedad(CASCADE), url_imagen, orden)
caracteristica(id_caracteristica PK, nombre_caracteristica UK)
propiedad_caracteristica(id_propiedad PK,FK→propiedad(CASCADE),
                         id_caracteristica PK,FK→caracteristica(CASCADE), cantidad)
cita(id_cita PK, id_propiedad FK→propiedad(CASCADE), id_cliente FK→usuario(CASCADE),
     fecha_hora, estado)  [+ UK (id_propiedad, fecha_hora)]
solicitud(id_solicitud PK, id_propiedad FK→propiedad(CASCADE),
          id_cliente FK→usuario(CASCADE), tipo, estado, fecha_solicitud)
       [índices: idx_solicitud_propiedad, idx_solicitud_cliente]
documento_solicitud(id_documento PK, id_solicitud FK→solicitud(CASCADE),
                    tipo_documento, url_archivo, fecha_carga)
favorito(id_usuario PK,FK→usuario(CASCADE), id_propiedad PK,FK→propiedad(CASCADE),
         fecha_marcado)
auditoria(id_auditoria PK, id_usuario FK→usuario(RESTRICT), accion, fecha_hora, detalle)
       [índice: idx_auditoria_usuario]
```

## 3. Cardinalidades que materializa el modelo

| Relación | Cardinalidad | Cómo se modela |
|---|---|---|
| `usuario`–`rol` | N:M | tabla puente `usuario_rol` (PK compuesta). Un usuario puede tener varios roles y un rol puede estar en varios usuarios |
| `usuario`–`perfil` | 1:1 | `perfil.id_usuario` es **UNIQUE**: un usuario tiene a lo sumo un perfil |
| `usuario`–`inmobiliaria` | 1:1 | `inmobiliaria.id_usuario` es **UNIQUE**: un usuario opera a lo sumo una inmobiliaria |
| `inmobiliaria`–`propiedad` | 1:N | `propiedad.id_inmobiliaria` |
| `ciudad`–`propiedad` | 1:N | `propiedad.id_ciudad` |
| `tipo_propiedad`–`propiedad` | 1:N | `propiedad.id_tipo` |
| `propiedad`–`imagen_propiedad` | 1:N | `imagen_propiedad.id_propiedad` |
| `propiedad`–`caracteristica` | N:M | tabla puente `propiedad_caracteristica` (PK compuesta) con columna extra `cantidad` |
| `propiedad`–`cita` | 1:N | `cita.id_propiedad` |
| `usuario`(cliente)–`cita` | 1:N | `cita.id_cliente` |
| `propiedad`–`solicitud` | 1:N | `solicitud.id_propiedad` |
| `usuario`(cliente)–`solicitud` | 1:N | `solicitud.id_cliente` |
| `solicitud`–`documento_solicitud` | 1:N | `documento_solicitud.id_solicitud` |
| `usuario`–`propiedad` (favoritos) | N:M | tabla puente `favorito` (PK compuesta) |
| `usuario`–`auditoria` | 1:N | `auditoria.id_usuario` |

## 4. Justificación de las políticas ON DELETE

El DDL aplica dos políticas, pensadas para cada tipo de dato:

### 4.1 `ON DELETE CASCADE` en hijos "parte-de" (agregados)

Cuando la tabla hija **no tiene sentido sin su padre** (es parte estructural de
él), borrar el padre debe arrastrar a sus hijos:

- `perfil`: la información personal no existe sin la cuenta `usuario`.
- `usuario_rol`: la asignación de roles muere con la cuenta.
- `imagen_propiedad`, `propiedad_caracteristica`: galería y atributos que solo
  existen dentro de una `propiedad`.
- `documento_solicitud`: los adjuntos cuelgan de su `solicitud`.
- `cita`, `solicitud`, `favorito`: registros de negocio del cliente; si se
  elimina la cuenta o la propiedad, desaparecen sus dependencias.

**Regla práctica aplicada:** en estos casos el sistema **no borra físicamente**
— la baja de una propiedad o de una cuenta es **lógica** (`estado = 'inactivo'`).
El CASCADE existe como garantía de integridad del esquema y de facilidad de
re-provisionamiento (los tests y el DML se pueden recargar limpiamente), no
como vía habitual de eliminación de datos de negocio.

### 4.2 `ON DELETE RESTRICT` en datos maestros / referencia

Cuando el padre es un **catálogo o una entidad que debe quedar protegida**
aunque no se use, se restringe el borrado:

- `ciudad`, `tipo_propiedad`, `caracteristica`: no se pueden eliminar mientras
  una `propiedad` las referencie. Para "desactivarlas" se usa baja lógica o se
  deja de usarlas en nuevas inserciones. El panel de administración captura el
  error de restricción y lo muestra al usuario ("El registro está en uso").
- `inmobiliaria` (desde usuario) y `auditoria.id_usuario`: la FK **RESTRICT**
  impide borrar un `usuario` que sea dueño de una inmobiliaria o que tenga
  trazas de auditoría; son evidencias que no deben perderse.

### 4.3 Baja lógica como norma de negocio

En un sistema inmobiliario los borrados reales destruyen historial importante
(qué propiedad vendió, qué solicitud se aprobó, quién marcó favorito). Por
eso:

- `usuario.estado` = `activo | inactivo` (bloquea el login, conserva el registro).
- `propiedad.estado` = `disponible | arrendado | vendido | inactivo` (la baja
  oculta la propiedad del listado público sin perder su historia).
- `cita.estado` / `solicitud.estado` reflejan el ciclo de vida del trámite.

Esta política convive con el CASCADE del esquema: el CASCADE protege la
integridad si algún día se depura la BD en desarrollo, mientras la lógica de
negocio evita los borrados destructivos en producción.

## 5. Índices y restricciones adicionales (seguridad de datos)

- Todos los correos y nombres de catálogo/roles/características tienen `UNIQUE`
  para evitar duplicados (`uq_*`).
- `cita` tiene `UNIQUE (id_propiedad, fecha_hora)`: evita doble cita sobre la
  misma propiedad a la misma hora.
- `solicitud` y `auditoria` tienen índices auxiliares (`idx_*`) para acelerar
  las consultas por propiedad, cliente y usuario.
- `ON UPDATE CASCADE` se aplica a todas las FK por uniformidad: si alguna vez
  cambia una PK, las referencias quedan sincronizadas.