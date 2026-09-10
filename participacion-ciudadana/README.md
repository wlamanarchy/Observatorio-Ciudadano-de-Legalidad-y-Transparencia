# CONSENSO

**Construcción ciudadana del país que todavía no existe.**

CONSENSO es una infraestructura digital abierta para participación ciudadana, planeación de largo plazo, co-creación normativa, construcción de planes de desarrollo y de gobierno propio, estrategias, alianzas, priorización democrática y seguimiento de compromisos públicos en Colombia.

## Relación con el Observatorio

CONSENSO es independiente del **Observatorio Ciudadano de Legalidad y Transparencia**, pero puede consumir únicamente información pública del Observatorio como insumo de diagnóstico. No comparte contactos privados, credenciales, notas internas ni bases reservadas.

Un diagnóstico verificable puede originar retos y propuestas, pero nunca automatiza una decisión política. La ciudadanía conserva la posibilidad de formular alternativas, deliberar, evaluar, priorizar y votar bajo reglas previamente publicadas.

## Del país al resguardo

La plataforma no reduce Colombia a Nación–departamento–municipio. El modelo distingue:

- **ámbito o territorio** donde ocurre el proceso;
- **entidad, órgano, autoridad o instancia** que tiene competencia;
- **instrumento jurídico o de planeación** donde puede aterrizar la decisión.

Esto permite trabajar con Nación, regiones, RAP, departamentos, distritos, municipios, localidades, comunas, corregimientos, veredas, áreas metropolitanas, provincias administrativas y de planificación, subregiones PDET, zonas de reserva campesina, cuencas de planificación, instituciones públicas y ámbitos étnico-territoriales.

Entre los ámbitos y gobiernos propios se incluyen, con verificación en registros oficiales cuando corresponda: **resguardos indígenas, territorios indígenas, comunidades o parcialidades, territorios ancestrales o tradicionales, cabildos, autoridades tradicionales, consejos indígenas, asociaciones de cabildos/autoridades, asociaciones de resguardos, consejos territoriales indígenas, consejos comunitarios NARP, tierras y territorios colectivos, organizaciones NARP, comunidades raizales y palenqueras, Kumpany y organizaciones del pueblo Rrom**.

Un resguardo puede ser simultáneamente una institución legal/sociopolítica y un ámbito territorial; por eso CONSENSO registra por separado la autoridad concreta que lo gobierna. Del mismo modo, el territorio colectivo NARP se distingue del consejo comunitario que lo administra y representa. La participación digital no sustituye la consulta previa ni otros procedimientos especiales obligatorios.

## Catálogo institucional

El catálogo cubre las ramas Ejecutiva, Legislativa y Judicial; organismos de control; organización electoral; órganos autónomos e independientes; entidades descentralizadas; esquemas asociativos territoriales; Sistema General de Regalías; instancias de planeación participativa; organizaciones de acción comunal y control social; autoridades y gobiernos colectivos étnicos.

La clasificación pública incluye para cada tipo: familia, rama o sistema, nivel de gobierno, naturaleza de su papel, resumen de competencia, instrumentos típicos, base normativa de referencia y fuente oficial.

Las fuentes maestras registradas en el backend incluyen el Manual de Estructura del Estado de Función Pública, DIVIPOLA del DANE, registros de pueblos y autoridades étnicas del Ministerio del Interior, información territorial de la Agencia Nacional de Tierras y referencias metodológicas de planeación participativa del DNP.

## Principios de legitimidad

- igualdad política: profesión, cargo, patrimonio o experticia no multiplican el voto;
- pluralismo territorial, institucional y étnico;
- competencia antes de promesa: cada acuerdo se dirige a quien jurídicamente puede decidirlo;
- reglas de votación definidas, publicadas y congeladas antes de abrir cada proceso;
- resultados consultivos salvo integración formal con un mecanismo jurídicamente competente;
- trazabilidad de versiones, moderación, evidencia, decisiones y respuestas institucionales;
- transparencia algorítmica y control humano de IA;
- separación entre evaluación técnica y preferencia democrática;
- protección de datos y minimización;
- accesibilidad WCAG 2.1 AA como mínimo;
- participación multicanal y medidas contra exclusión digital;
- auditoría de agregados y operaciones críticas;
- registro criptográfico append-only y anclaje blockchain opcional solo de hashes;
- respeto por consulta previa, gobierno propio y representación válida de pueblos y comunidades étnicas.

## Aplicación

El frontend React/Vite incorpora lectura pública de procesos, diagnósticos, propuestas, ámbitos y catálogos institucionales; autenticación passwordless; creación de propuestas; deliberación; votaciones y priorización; solicitud de habilitación; resultados agregados; recibos de integridad; administración de roles y procesos; y vínculo público con el Observatorio como plataforma hermana de diagnóstico.

## Backend

El backend Supabase/PostgreSQL es independiente del Observatorio. Sus migraciones implementan núcleo de participación, RLS, votación, procedencia, integridad, consenso, gobernanza, moderación, privacidad, runtime del piloto, administración, ciclo completo de votaciones y el catálogo de entidades/autoridades/ámbitos de CONSENSO.

La migración `015_consenso_entity_and_scope_catalog.sql` incorpora el modelo ampliado de Estado, participación y gobierno propio.

## Desarrollo

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

GitHub Actions valida y publica CONSENSO bajo una ruta pública propia, separada del Observatorio.

## Acceso público

`https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/consenso/`

La ruta antigua `/participacion/` redirige a esta dirección.
