# Sprint 2 — Retrospective

**Sprint:** 2 · Módulo inmobiliaria y módulo cliente

Fecha: cierre de la semana 2

## Qué salió bien

- **Separación vista / acción.** Cada formulario tiene su JSP de listado y una
  página POST dedicada que solo redirige. El flujo quedó limpio, testeable y
  sin recargas confusas.
- **Validación de pertenencia en el servidor.** Aunque un botón no se muestre
  en la UI, toda acción revalida que la propiedad/solicitud pertenezca a la
  inmobiliaria de la sesión. Impide editar o aprobar datos ajenos manipulando
  IDs.
- **El patrón transaccional del Sprint 1 se replicó.** Todas las escrituras
  nuevas usan `setAutoCommit(false)` + `commit` + `rollback`, sin repetir el
  bug del commit.
- **Bug de `getParts()` documentado en el código.** Dejar el comentario en la
  línea exacta donde se dispara el parseo multipart evita que alguien lo
  "reordene" y vuelva a romper el flujo.

## Qué se podría mejorar

- **El formulario de solicitudes era el más complejo** (multipart + archivos +
  transacciones). Se hubiera beneficiado de subdividirse (primero datos, luego
  documentos).
- Sin framework de test automatizado, la regresión se controla probando todos
  los flujos a mano antes de cada entrega; conviene definir una **checklist de
  humo** por módulo.
- La carpeta de documentos crece con archivos de prueba; hay que recordar
  limpiarla antes de copiar el proyecto (no se subió nada binario al entregable
  de esta entrega).

## Acciones acordadas para el Sprint 3

1. Crear una **checklist de regresión** corta (login → 1 alta de propiedad →
   1 solicitud → 1 cita) para correr antes de cada cierre.
2. **Evidencia de bugs**: completar el registro de bugs (los 4 ya existentes)
   con severidad y verificación.
3. Preparar la **sustentación de consultas SQL**: listar las consultas con
   INNER JOIN, N:M, LEFT JOIN y GROUP BY/HAVING que el enunciado exige, para el
   módulo de reportes del siguiente sprint.