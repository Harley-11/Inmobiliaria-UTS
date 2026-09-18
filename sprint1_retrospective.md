# Sprint 1 — Retrospective

**Sprint:** 1 · Fundaciones

Fecha: cierre de la semana 1

## Qué salió bien

- **Fragmentos reutilizables (`.jspf`) desde el inicio.** Centralizar
  conexión, seguridad, cabecera, utilidades y pie evitó duplicación masiva de
  código en cada página y aceleró los sprints siguientes.
- **El esquema se diseñó antes de escribir negocio.** Políticas CASCADE/RESTRICT
  y las 3 tablas puente (N:M) quedaron resueltas en papel antes de programar.
- **Registro con rol fijo en el servidor.** Evitar leer el rol del formulario
  cerró la brecha de seguridad más obvia desde el día uno.
- **Pruebas manuales sistemáticas** (registro → login → catálogo) cada vez que
  se terminaba una historia.

## Qué se podría mejorar

- **Validación de transacciones:** el bug de commit mostró que "la página
  responde bien" no equivale a "la base quedó bien". Faltaba verificar el
  estado real de la BD después de cada operación de escritura.
- **Convención de mensajes de error:** mezcla inicial de redirecciones con
  parámetros `?err=` y despachos con `request.setAttribute`. Se estandarizó a
  medio sprint, pero quedó registro del cambio.

## Acciones acordadas para el Sprint 2

1. **Regla ágil:** toda operación de escritura debe manejar explícitamente
   `setAutoCommit(false)` + `commit` + `rollback` en catch (norma ya aplicada
   en registro) – aplicar a todo nuevo guardado.
2. **Revisar BD tras cada prueba E2E** de un guardado (verificación con
   consultas directas, no solo con la UI).
3. Mantener un **registro de bugs** (síntoma → causa → fix → verificación)
   para alimentar los reviews siguientes (este sprint ya dejó 2 entradas).