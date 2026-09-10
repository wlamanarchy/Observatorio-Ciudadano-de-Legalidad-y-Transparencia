# Observatorio Ciudadano de Legalidad y Transparencia

Plataforma abierta de **control ciudadano de la gestión pública en Colombia**, con una metodología uniforme de evidencia, contraste jurídico, derecho de réplica, traslado competente, seguimiento y publicación trazable.

El Observatorio es la plataforma hermana de **CONSENSO**. Sus funciones son distintas: el Observatorio documenta y controla actuaciones públicas; CONSENSO puede tomar únicamente información pública del Observatorio como insumo de diagnóstico para construir soluciones, prioridades y visión futura.

## Cobertura

El control no se reduce a Nación–departamento–municipio. La interfaz reconoce 25 tipos de ámbito: nacional, regional, RAP, departamental, distrital, municipal, localidad, comuna, corregimiento, vereda, área metropolitana, provincia administrativa y de planificación, subregión PDET, Zona de Reserva Campesina, cuenca/POMCA, institucional y ámbitos de gobierno propio o étnico-territorial.

Esto incluye resguardos y territorios indígenas, comunidades o parcialidades, territorios ancestrales, tierras y territorios colectivos NARP, ámbitos de consejos comunitarios, comunidades raizales y palenqueras y Kumpany del pueblo Rrom. El sistema diferencia **ámbito, autoridad y entidad** y no sustituye consulta previa, gobierno propio ni jurisdicciones especiales.

El catálogo de sujetos comprende ramas Ejecutiva, Legislativa y Judicial; organismos de control; organización electoral; órganos autónomos e independientes; entidades descentralizadas; gobiernos territoriales; esquemas asociativos; Sistema General de Regalías; universidades públicas; CAR; instancias de planeación; gobiernos y autoridades étnicas; y otras organizaciones cuando exista una relación jurídicamente verificable con gestión o recursos públicos.

## Cadena de control

**Evidencia → Verificación → Contraste jurídico → Réplica → Traslado competente → Seguimiento → Resultado público.**

Una alerta ciudadana nunca se publica automáticamente como hallazgo. Las fichas pueden clasificarse como **defecto jurídico**, **riesgo de integridad** o **conforme a derecho**. Un riesgo no equivale a responsabilidad penal, disciplinaria o fiscal.

## Calidad metodológica

- fuente primaria para el sello DOCUMENTADO;
- norma o estándar concreto de contraste;
- oportunidad de réplica de la entidad observada;
- competencia verificada antes de un traslado;
- datos privados del reportante separados del contenido público;
- roles nacionales y territoriales con Row Level Security;
- historial de fuentes, réplicas, traslados y eventos de expediente;
- correcciones visibles y conservación de trazabilidad;
- mismo estándar sin importar gobierno, partido, entidad o territorio observado;
- publicación explícita después de superar las garantías metodológicas.

## Infraestructura

Frontend React/Vite publicado con GitHub Pages. Backend Supabase/PostgreSQL independiente de CONSENSO, con autenticación, RLS, auditoría y seguimiento de expedientes.

El repositorio mantiene las migraciones en `supabase/migrations/` y la aplicación pública en `src/`.

## Acceso público

Observatorio:

`https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/`

CONSENSO:

`https://wlamanarchy.github.io/Observatorio-Ciudadano-de-Legalidad-y-Transparencia/participacion/`

## Identidad visual

Las dos plataformas usan la misma familia visual: verde bosque y verde institucional como colores principales, dorado como acento, fondos claros y rojo reservado para alertas o acciones críticas. La identidad común muestra que pertenecen al mismo ecosistema ciudadano, manteniendo sus funciones independientes.
