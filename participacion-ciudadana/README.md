# Colombia Construye Futuro

Infraestructura digital abierta para participación ciudadana, planeación de largo plazo, co-creación normativa, construcción de planes de desarrollo, estrategias, alianzas, priorización democrática y seguimiento de compromisos públicos en Colombia.

> Nombre provisional de producto. La arquitectura y los estándares se diseñan para poder adoptar posteriormente un nombre institucional definitivo sin alterar el modelo técnico.

## Propósito

La plataforma busca que la ciudadanía pueda participar de manera informada, trazable e inclusiva en la construcción del futuro de Colombia, desde el nivel nacional hasta departamentos, distritos, municipios, territorios e instituciones públicas autónomas o administrativas.

No es una plataforma de encuestas ni un contador de popularidad. Cada proceso debe declarar su competencia, naturaleza jurídica, reglas, universo, método, mecanismos de inclusión, forma de usar los aportes y sistema de rendición de cuentas.

## Relación con el Observatorio

Esta plataforma es **hermana e independiente** del **Observatorio Ciudadano de Legalidad y Transparencia**.

El Observatorio puede aportar diagnósticos, evidencia pública y seguimiento. Colombia Construye Futuro convierte diagnósticos y necesidades públicas en retos, propuestas, deliberación, evaluación, priorización y seguimiento de soluciones.

La interoperabilidad es de solo información pública y conserva procedencia criptográfica. No se comparten bases de datos, credenciales, información privada de reportantes ni facultades administrativas.

## Ciclo democrático continuo

**Diagnóstico → Reto → Propuesta → Deliberación → Evaluación → Priorización → Votación → Resultado participativo → Respuesta institucional → Implementación → Vigilancia → Evaluación → nuevo diagnóstico.**

Este ciclo es una función del producto. El desarrollo de la plataforma, a su vez, se somete a mejora continua técnica, normativa, de seguridad, accesibilidad, inclusión y legitimidad.

## Principios irrenunciables

- participación significativa: no abrir procesos simbólicos sin capacidad real de incidencia;
- igualdad política: una persona habilitada no recibe mayor peso por profesión, cargo o patrimonio;
- reglas publicadas y congeladas antes de votar;
- deliberación previa a decisiones de alto impacto;
- evaluación técnica separada de la preferencia democrática;
- trazabilidad completa de versiones, decisiones, moderación y respuestas;
- neutralidad política y reglas simétricas para mayorías y minorías;
- datos personales minimizados y separados de contenidos públicos;
- voto secreto cuando corresponda y elegibilidad separada de la selección;
- accesibilidad WCAG 2.1 AA como mínimo;
- canales híbridos para reducir exclusión digital;
- resultados contextualizados: nunca publicar solo un porcentaje;
- transparencia algorítmica e IA subordinada a reglas humanas;
- auditoría pública y posibilidad de verificación independiente;
- distinción estricta entre participación consultiva y mecanismos jurídicamente vinculantes.

## Arquitectura de confianza

La arquitectura recomendada es híbrida:

- **GitHub** para código abierto, documentación, versiones y auditoría del software;
- **Supabase/PostgreSQL independiente** para datos operativos;
- almacenamiento documental con hashes y permisos;
- registro criptográfico append-only de eventos críticos;
- checkpoints públicos de reglas, opciones, resultados y software;
- anclaje opcional de hashes en blockchain pública, sin publicar datos personales ni votos individuales;
- exportaciones abiertas y verificables.

La blockchain se usa como capa de prueba de integridad, no como sustituto de legitimidad democrática, protección de datos ni requisitos legales de una elección formal.

## Instituciones y niveles

El modelo admite procesos de:

- Nación;
- departamentos;
- distritos y municipios;
- esquemas regionales y supraterritoriales;
- ministerios y departamentos administrativos;
- superintendencias, agencias y unidades administrativas especiales;
- establecimientos públicos;
- corporaciones autónomas regionales;
- universidades públicas y entes universitarios autónomos;
- empresas y entidades públicas con procesos participativos;
- otras autoridades u organismos que abran espacios compatibles con el marco jurídico aplicable.

## MVP actual

El frontend contiene: Inicio, Diagnóstico, Propuestas, Crear propuesta, Priorización y Reglas. La base técnica Supabase está preparada en `supabase/migrations` y ahora incluye procedencia de diagnósticos, reglas congeladas, integridad criptográfica, criterios de consenso y checkpoints de transparencia.

## Documentos de diseño

- `docs/ESTANDAR_MAXIMO_PARTICIPACION.md`
- `docs/CICLO_DEMOCRATICO_CONTINUO.md`
- `docs/INTEROPERABILIDAD_OBSERVATORIO.md`
- `docs/MODELO_DE_CONSENSO_Y_PRIORIZACION.md`
- `docs/ARQUITECTURA_CONFIANZA_BLOCKCHAIN.md`
- `docs/GOBERNANZA_Y_LEGITIMIDAD.md`
- `docs/PROTOCOLO_PARTICIPACION_Y_VOTACION.md`
- `docs/MATRIZ_NORMATIVA.md`
- `docs/SEGURIDAD_PRIVACIDAD_ACCESIBILIDAD.md`
- `docs/MODELO_DE_RIESGOS_DEMOCRATICOS.md`

## Desarrollo

```bash
npm install
npm run dev
```

## Despliegue

Mientras se valida el MVP, la aplicación vive aislada en `participacion-ciudadana/` dentro del repositorio actual y en una rama propia. Para producción debe migrarse a un repositorio GitHub propio y a un proyecto Supabase propio, manteniendo la interoperabilidad con el Observatorio únicamente mediante API/eventos públicos.

## Regla de lanzamiento

Antes de abrir votaciones reales deben completarse, como mínimo: revisión jurídica del tipo de proceso, pruebas de RLS, pruebas anti-doble-voto, auditoría de seguridad, evaluación de accesibilidad, pruebas de carga, plan de incidentes, verificación del registro criptográfico y publicación de reglas de gobernanza.
