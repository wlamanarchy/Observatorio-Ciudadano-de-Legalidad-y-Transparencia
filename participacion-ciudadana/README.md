# Colombia Construye Futuro

Infraestructura digital abierta para participación ciudadana, planeación de largo plazo, co-creación normativa, construcción de planes de desarrollo, estrategias, alianzas, priorización democrática y seguimiento de compromisos públicos en Colombia.

> Nombre provisional de producto. La arquitectura y los estándares se diseñan para poder adoptar posteriormente un nombre institucional definitivo sin alterar el modelo técnico.

## Relación con el Observatorio

Esta plataforma es independiente del **Observatorio Ciudadano de Legalidad y Transparencia**, pero puede consumir únicamente información pública del Observatorio como insumo de diagnóstico. No comparte contactos privados, credenciales, notas internas ni bases reservadas.

Un diagnóstico verificable puede originar retos y propuestas, pero nunca automatiza una decisión política. La ciudadanía conserva la posibilidad de formular alternativas, deliberar, evaluar, priorizar y votar bajo reglas previamente publicadas.

## Principios de legitimidad

- igualdad política: profesión, cargo, patrimonio o experticia no multiplican el voto;
- reglas de votación definidas, publicadas y congeladas antes de abrir cada proceso;
- resultados consultivos salvo integración formal con un mecanismo jurídicamente competente;
- trazabilidad de versiones, moderación, evidencia, decisiones y respuestas institucionales;
- transparencia algorítmica y control humano de IA;
- separación entre evaluación técnica y preferencia democrática;
- protección de datos y minimización;
- accesibilidad WCAG 2.1 AA como mínimo;
- participación multicanal y medidas contra exclusión digital;
- auditoría de agregados y operaciones críticas;
- registro criptográfico append-only y anclaje blockchain opcional solo de hashes.

## Aplicación

El frontend React/Vite ya incorpora:

- lectura pública de procesos, diagnósticos y propuestas;
- autenticación passwordless por correo cuando Supabase está configurado;
- creación de propuestas asociadas a procesos públicos;
- deliberación con argumentos a favor/en contra, alternativas, preguntas, enmiendas y evidencia;
- directorio de votaciones publicadas;
- solicitud de habilitación para votar;
- emisión de voto mediante RPC para métodos habilitados;
- recibo de integridad sin publicar selección individual;
- vínculo público con el Observatorio como fuente hermana de diagnóstico;
- modo demostración cuando todavía no existe backend propio.

## Backend

Las migraciones en `supabase/migrations` separan:

1. núcleo de participación;
2. RLS y votación;
3. procedencia, integridad y consenso;
4. gobernanza, moderación y validación de selecciones;
5. vistas seguras y endurecimiento de privacidad;
6. runtime del piloto: onboarding de ciudadanía, creación segura de propuestas/aportes y solicitudes de elegibilidad.

Para producción debe utilizarse un proyecto Supabase propio, separado del Observatorio, con ambientes diferenciados y auditoría de RLS.

## Desarrollo

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

El proyecto se valida mediante GitHub Actions. En el monorepo actual, el workflow principal construye el Observatorio y añade esta aplicación al artefacto de GitHub Pages bajo `/participacion/`.

## Despliegue transitorio

Mientras se crea el repositorio independiente, el sitio puede publicarse en:

`https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/participacion/`

La separación definitiva recomendada es: repositorio GitHub propio + proyecto Supabase propio + interoperabilidad pública documentada con el Observatorio.
