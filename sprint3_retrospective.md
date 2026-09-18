# Sprint 3 — Retrospective

**Sprint:** 3 · Administración, reportes y documentación

Fecha: cierre de la semana 3 (entrega 18/09)

## Qué salió bien

- **Las protecciones de la gestión de usuarios** (anti-lockout del admin,
  baja lógica, FK RESTRICT) fueron parte del diseño desde el planning y se
  probaron, no se "inventaron" al final. Esto es evidencia fuerte de
  madurez del proyecto.
- **Los reportes quedaron documentados donde se pueden explicar.** El SQL
  comentado en el propio `admin/reportes.jsp` (y visible en un `<details>`
  de la página) convierte la sustentación en una lectura del código, no un
  acto de memoria.
- **La documentación técnica ya no es un apéndice:** el diccionario se
  extrajo del DDL real y las imágenes del MER se generan desde el mismo código
  Mermaid que está en `docs/mer.md`, así que mantienen coherencia.
- **La checklist de regresión** del Sprint 2 se incorporó y atrapó 0
  regresiones en el cierre.

## Qué se podría mejorar

- **Conteo de auditoría y contenido:** registrar acciones del panel admin
  genera muchas filas de prueba; conviene decidir una política de limpieza
  para la entrega (revisar el volumen antes de entregar).
- **Módulo de reportes en el futuro** se beneficiaría de exportación (CSV/PDF)
  y de parámetros en línea; quedó como mejora posible, no bloqueante.
- El **MER en Mermaid** depende de un renderizador (GitHub/VS Code o
  `mermaid-cli`); para la entrega se exportó además `mer.png` y
  `modelo_relacional.png`, así los diagramas se ven sin herramientas.

## Acciones finales antes de la entrega (18/09)

1. Correr la checklist de humo final completa (login de los 3 roles,
   registro, alta de propiedad, solicitud con documento, cita, admin).
2. Verificar que `docs/` contiene los 8 artefactos y que los PNG abren
   correctamente.
3. Confirmar que el SQL comentado de `admin/reportes.jsp` coincide con las
   consultas exigidas por el enunciado.
4. (Pendiente de decisión) limpiar las filas de prueba de `auditoria` o
   conservarlas como evidencia de uso real.