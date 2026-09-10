# Arquitectura de confianza, trazabilidad y blockchain

## Decisión arquitectónica

La transparencia no se resolverá poniendo toda la plataforma dentro de una blockchain. La arquitectura recomendada es **híbrida**:

1. **GitHub**: código fuente, historial de cambios, documentación y versiones públicas.
2. **Supabase/PostgreSQL independiente**: datos operativos, perfiles, propuestas, procesos, moderación, reglas y resultados.
3. **Almacenamiento documental**: evidencia y anexos con controles de acceso y hashes.
4. **Registro criptográfico append-only**: cadena de eventos críticos dentro de la base de datos.
5. **Anclaje externo opcional**: publicación periódica de raíces hash/checkpoints en una blockchain pública u otro registro público inmutable.
6. **Exportaciones abiertas firmadas**: reglas, resultados y auditoría disponibles para verificación independiente.

## Qué sí se puede anclar públicamente

- hash de las reglas congeladas de un proceso;
- hash del conjunto de opciones de una votación;
- raíz hash de lotes de recibos de voto;
- hash del resultado certificado;
- hash de un corte del registro de auditoría;
- hash de un paquete de evidencia pública;
- versión del software desplegado.

## Qué nunca debe ir a una blockchain pública

- nombres, documentos o teléfonos;
- datos sensibles;
- credenciales o tokens;
- selección individual de voto;
- correlaciones identidad-voto;
- denuncias reservadas;
- evidencia que deba poder suprimirse por obligación legal.

La blockchain se usa como **prueba de integridad y existencia**, no como almacén de datos personales.

## Registro criptográfico interno

Los eventos críticos se encadenan mediante SHA-256:

`event_hash = SHA256(previous_hash + event_type + object_type + object_id + payload + timestamp)`

Cada evento conserva el hash anterior. Modificar o eliminar un registro histórico rompe la cadena y puede detectarse.

Para impedir carreras concurrentes, la función de escritura debe tomar un bloqueo transaccional antes de calcular el siguiente hash.

## Checkpoints públicos

Periódicamente se genera un checkpoint con:

- primer y último evento incluidos;
- hash de cabecera de la cadena;
- raíz de recibos de votación cuando corresponda;
- hash de reglas;
- hash de resultados;
- versión del software;
- fecha;
- referencia del anclaje externo.

Un checkpoint puede publicarse simultáneamente en:

- GitHub Release;
- repositorio de datos abiertos;
- blockchain pública;
- sitio web de transparencia de la plataforma.

## Blockchain: criterio de selección

No se escogerá red por mercadeo. Antes de adoptar una cadena se documentarán:

- costo previsible por anclaje;
- permanencia y descentralización;
- disponibilidad de exploradores públicos;
- facilidad de verificación independiente;
- huella ambiental;
- estabilidad técnica;
- dependencia de proveedores;
- soporte de bibliotecas auditadas;
- riesgos regulatorios.

La plataforma debe poder cambiar de red sin alterar el modelo de datos. El anclaje se modela como un adaptador.

## Votaciones

Para votaciones participativas consultivas, la plataforma puede operar en línea con controles de identidad, elegibilidad, secreto y auditoría.

Para mecanismos jurídicamente vinculantes o de alto riesgo, el sistema no debe afirmar equivalencia con una elección oficial por el solo hecho de usar blockchain. Debe integrarse al mecanismo legal competente y someterse a requisitos adicionales de seguridad, auditoría independiente y certificación.

## Principios de seguridad electoral aplicados

- auditabilidad;
- secreto de la selección cuando corresponda;
- mínimo privilegio;
- integridad del software;
- protección de datos;
- detección y monitoreo;
- criptografía pública, estandarizada y ampliamente revisada;
- posibilidad de verificar los resultados sin revelar la selección individual.

## Gobernanza de claves

Las claves administrativas y de firma no pueden depender de una sola persona. Para procesos críticos se recomienda:

- MFA obligatorio;
- rotación;
- custodia separada;
- aprobación de dos personas para operaciones extraordinarias;
- registro de toda acción privilegiada;
- recuperación documentada;
- uso de KMS/HSM cuando el nivel de riesgo lo justifique.

## Transparencia del software

Cada proceso de alta importancia debe registrar el commit exacto del software utilizado. La interfaz pública podrá mostrar:

- commit Git;
- fecha de despliegue;
- hash de reglas;
- hash de opciones;
- hash de resultados;
- checkpoint de auditoría;
- referencia de anclaje externo.

Así cualquier auditor puede reconstruir qué versión del sistema produjo un resultado determinado.
