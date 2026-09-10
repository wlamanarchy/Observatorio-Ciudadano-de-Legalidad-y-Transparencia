# Colombia Construye Futuro

Plataforma independiente de participación ciudadana para construir visión de largo plazo, propuestas normativas, planes de desarrollo, estrategias, alianzas y prioridades públicas en Colombia.

## Relación con el Observatorio

Esta plataforma es independiente del **Observatorio Ciudadano de Legalidad y Transparencia**, pero se conecta conceptualmente con él. El Observatorio aporta diagnóstico, evidencia y seguimiento; Colombia Construye Futuro transforma esos diagnósticos y los aportes ciudadanos en retos, propuestas, deliberación, priorización y seguimiento institucional.

**Loop:** Diagnóstico → Reto → Propuesta → Deliberación → Evaluación → Priorización → Votación → Respuesta institucional → Implementación → Vigilancia → Evaluación → nuevo diagnóstico.

## Principios de legitimidad

- igualdad política: una persona verificada no obtiene más peso por profesión, cargo o patrimonio;
- reglas de votación definidas antes de abrir cada proceso y congeladas durante la votación;
- resultados no vinculantes salvo que el proceso se articule formalmente a un mecanismo jurídico competente;
- trazabilidad de versiones, moderación, evidencia, decisiones y respuestas institucionales;
- transparencia algorítmica: IA puede ayudar a resumir, agrupar o detectar duplicados, pero no decide ganadores;
- separación entre evaluación técnica y preferencia democrática;
- protección de datos personales y minimización de datos;
- accesibilidad WCAG 2.1 AA como mínimo;
- participación multicanal y medidas contra exclusión digital;
- auditoría pública de agregados y auditoría interna de operaciones.

## MVP

El frontend incluye: Inicio, Diagnóstico, Retos, Propuestas, Deliberación, Priorizar, Votar, Instituciones y Seguimiento. La capa Supabase queda preparada en `supabase/migrations`.

## Desarrollo

```bash
npm install
npm run dev
```

## Despliegue

En este repositorio/monorepo se puede desplegar bajo `/participacion/`. Para producción institucional se recomienda repositorio y proyecto Supabase propios, conservando la interoperabilidad con el Observatorio mediante API/eventos públicos.
