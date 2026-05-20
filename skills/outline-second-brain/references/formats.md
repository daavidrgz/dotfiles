# Document Formats Reference

Templates for each document type in the brain. Use these when creating new documents.

---

## Entity (Person / Company / Tool)

```markdown
**Tipo:** persona | empresa | herramienta
**Rol:** [current role]
**Empresa:** [current company]
**Última interacción:** YYYY-MM-DD
**Tags:** #entity #person

## Contexto
[Who they are, relationship with David]

## Historial
- YYYY-MM → presente: [current fact]
- YYYY-MM → YYYY-MM: [previous fact] (aprendido: YYYY-MM-DD)

## Interacciones
- YYYY-MM-DD: [what happened]
```

### Bi-temporal facts rule
When a fact changes (role, company, status, location), NEVER delete the old value. Add a new entry:

```
## Historial
- 2024-01 → 2026-03: CTO en Acme Corp
- 2026-04 → presente: Architect en Acme Corp (aprendido: 2026-04-07, fuente: Daily 2026-04-07)
```

Top-level fields (**Rol:**, **Empresa:**) always reflect the CURRENT state. The Historial preserves the full timeline.

---

## Concept / Idea

```markdown
**Estado:** active | graduated | archived
**Tags:** #concept

## Descripción
[The idea in detail]

## Evidencia
[Supporting facts, sources, examples]

## Conexiones
[Related docs in the brain — projects, entities, other concepts]
```

- `active` = being explored
- `graduated` = promoted to a Project (link to it)
- `archived` = no longer relevant

---

## Project

```markdown
**Estado:** active | planning | completed | archived | on-hold
**Tags:** #project

## Descripción
[What the project is]

## Objetivos
[What success looks like]

## Decisiones clave
- YYYY-MM-DD: [decision made]

## Actividad reciente
- YYYY-MM-DD: [what happened]

## Personas
[People involved — link to their Entity docs]
```

---

## Daily Note

```markdown
**Fecha:** YYYY-MM-DD
**Tags:** #daily

## Actividad
[What was done today]

## Personas
[Who was interacted with — link to Entity docs]

## Decisiones
[What was decided — link to Decisions/Projects]

## Ideas
[What came up — link to Concepts]
```

---

## Source (Immutable)

```markdown
**Tipo:** article | transcript | video | pdf | text
**URL:** [original URL]
**Fecha ingestión:** YYYY-MM-DD
**Tags:** #source #[type]

## Resumen
[Summary of the content]

## Extractos clave
[Key claims, data points, notable insights]

## Entidades mencionadas
[People, companies, tools found in the source]

## Conceptos
[Ideas, frameworks extracted]
```

**IMPORTANT:** Sources are immutable. Once created, never modify them. They are the raw truth. If a wiki page gets corrupted, re-derive from the source.

---

## Decision Record (ADR)

```markdown
**Estado:** accepted | superseded | deprecated
**Proyecto:** [link to related project]
**Fecha:** YYYY-MM-DD
**Tags:** #decision

## Decisión
[One-line summary]

## Contexto
[What prompted this decision]

## Opciones consideradas
1. [Option A] — [pros/cons]
2. [Option B] — [pros/cons]

## Justificación
[Why this option was chosen]

## Consecuencias
[What changed as a result]
```

---

## Naming Conventions

| Type | Pattern | Example |
|---|---|---|
| Daily note | `YYYY-MM-DD` | `2026-04-11` |
| Entity | Full name | `Jane Smith`, `Acme Corp` |
| Concept | Descriptive title | `LLM-Wiki Pattern` |
| Project | Proper name | `Second Brain Outline` |
| Source | `YYYY-MM-DD — Source Title` | `2026-04-11 — Karpathy LLM Wiki` |
| Decision | `ADR — Title` | `ADR — Wiki Style for Brain` |

---

## Status Values

Use consistently across all document types:

**Projects:** `active` | `planning` | `completed` | `archived` | `on-hold`
**Concepts:** `active` | `graduated` | `archived`
**Decisions:** `accepted` | `superseded` | `deprecated`
**Sources:** (no status — immutable once created)
