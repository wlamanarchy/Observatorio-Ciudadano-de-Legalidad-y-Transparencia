# Votación de alta integridad

La plataforma distingue deliberación, priorización participativa y votación jurídicamente formal. No todas requieren el mismo nivel de seguridad.

## Nivel A — apoyo abierto

Uso: señal temprana de interés.

Garantías:
- cuenta y controles antiabuso;
- el apoyo no se presenta como voto formal;
- resultados descriptivos, no representativos.

## Nivel B — prioridad consultiva verificada

Uso: ordenar propuestas en procesos ciudadanos o institucionales consultivos.

Garantías:
- elegibilidad definida;
- una participación por persona/proceso;
- reglas y opciones congeladas;
- validación server-side de selección;
- recibo de integridad;
- acceso restringido a boletas;
- auditoría y publicación de agregados;
- separación lógica entre elegibilidad y selección.

Este nivel corresponde al objetivo inicial del piloto.

## Nivel C — votación secreta reforzada

Uso: decisiones participativas de alto impacto donde el secreto sea esencial.

Requisitos adicionales:
- componente de votación separado del sistema de perfiles;
- cifrado de la boleta antes de persistirla;
- claves de descifrado distribuidas entre varios custodios cuando sea viable;
- protocolos criptográficos y bibliotecas públicamente revisados, nunca criptografía inventada para el proyecto;
- verificabilidad extremo a extremo o mecanismo equivalente evaluado independientemente;
- auditoría externa previa y posterior;
- plan de respuesta a incidentes;
- pruebas de carga y ataques;
- publicación de hashes/checkpoints sin revelar selecciones.

No se debe almacenar una relación directa `user_id -> receipt -> selection`.

## Nivel D — mecanismo jurídicamente vinculante

Uso: cuando una autoridad pretenda que la votación tenga el efecto de referendo, consulta popular, mecanismo electoral u otra figura formal.

La plataforma no presume aptitud para este nivel. Se requiere:
- habilitación jurídica específica;
- autoridad competente;
- procedimiento formal aplicable;
- certificación/auditoría exigible;
- garantías electorales correspondientes;
- integración con sistemas oficiales o componentes certificados cuando sea necesario.

La utilización de blockchain no convierte por sí sola un proceso en jurídicamente vinculante ni resuelve los riesgos de votación remota.

## Principios de diseño del secreto

1. Autenticar a la persona no significa almacenar su identidad junto a la selección.
2. El comprobante no debe permitir demostrar a un tercero por quién se votó, para reducir riesgos de compra o coacción.
3. Los timestamps de identidad y voto pueden facilitar correlación; en niveles reforzados deben desacoplarse mediante arquitectura específica.
4. Administradores ordinarios no deben poder leer votos individuales.
5. Cualquier operación extraordinaria sobre urnas o resultados requiere autorización múltiple y registro auditable.

## Certificación del resultado

Un resultado certificado debe enlazar:
- proceso;
- reglas congeladas;
- opciones congeladas;
- método de tabulación;
- versión/commit del software;
- total de habilitados;
- total de participantes;
- incidencias;
- hash del conjunto de votos o prueba criptográfica equivalente;
- hash de resultados;
- checkpoint público;
- informe de auditoría cuando corresponda.

## Blockchain

La cadena pública, si se usa, almacena únicamente pruebas de integridad: hashes de reglas, lote de recibos, resultado y checkpoint. Nunca boletas en claro, identificadores de personas o datos sensibles.
