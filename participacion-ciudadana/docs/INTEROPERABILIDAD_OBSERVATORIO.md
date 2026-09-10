# Interoperabilidad con el Observatorio Ciudadano de Legalidad y Transparencia

## Regla de separación

**Colombia Construye Futuro** y el **Observatorio Ciudadano de Legalidad y Transparencia** son plataformas hermanas, no módulos de una misma base de datos.

- El Observatorio documenta, contrasta y hace seguimiento a actuaciones públicas.
- Colombia Construye Futuro transforma diagnósticos y necesidades públicas en procesos de deliberación, propuestas, priorización y seguimiento de soluciones.

No se comparten credenciales, datos privados de reportantes, roles administrativos ni tablas internas.

## Flujo permitido

La interoperabilidad se limita a información pública y verificable:

1. El Observatorio publica una ficha o hallazgo.
2. Colombia Construye Futuro puede importarlo como **fuente diagnóstica**, conservando procedencia.
3. Un moderador o responsable de proceso decide si esa evidencia amerita formular un reto.
4. La ciudadanía propone alternativas.
5. Las alternativas se deliberan, evalúan y eventualmente priorizan.
6. La institución competente responde.
7. La implementación puede volver a ser monitoreada por el Observatorio.

Ningún hallazgo se transforma automáticamente en propuesta, y ninguna propuesta se convierte automáticamente en decisión.

## Contrato mínimo de procedencia

Todo insumo importado deberá registrar:

- `source_system`: sistema de origen;
- `source_record_id`: identificador en origen;
- `source_url`: URL pública estable;
- `source_version`: versión o fecha de corte;
- `source_hash`: hash SHA-256 del contenido normalizado o documento;
- `published_at`: fecha de publicación en origen;
- `retrieved_at`: fecha de importación;
- `integrity_status`: verificado, pendiente o discrepancia;
- `public_payload`: copia mínima de los campos públicos necesarios;
- `imported_by`: actor o proceso técnico que realizó la importación.

## API pública propuesta

El Observatorio podrá exponer, en una etapa posterior, un endpoint de solo lectura con fichas publicadas. Colombia Construye Futuro consumirá exclusivamente campos públicos.

Ejemplo conceptual:

```json
{
  "system": "observatorio-ciudadano-legalidad-transparencia",
  "record_id": "F-000123",
  "title": "...",
  "territory": "...",
  "entity": "...",
  "classification": "...",
  "verification": "documentado",
  "source_urls": ["..."],
  "published_at": "...",
  "record_hash": "sha256:..."
}
```

## Protección de datos

La integración jamás transferirá:

- contacto privado de reportantes;
- datos de autenticación;
- tokens;
- notas internas de curaduría no publicadas;
- datos personales innecesarios;
- información reservada o clasificada.

## Tratamiento de discrepancias

Si una ficha del Observatorio cambia después de haber sido usada como diagnóstico:

1. se conserva la versión importada;
2. se registra una nueva versión;
3. se muestra la discrepancia;
4. el reto o propuesta no se reescribe silenciosamente;
5. si el cambio altera materialmente el diagnóstico, se activa revisión humana.

## Trazabilidad pública

Toda propuesta que nazca de un diagnóstico del Observatorio debe mostrar públicamente la relación de procedencia, sin afirmar que el Observatorio respalda la solución propuesta.

La fórmula de interfaz será:

> “Esta propuesta utiliza como antecedente un diagnóstico/hallazgo público del Observatorio. La solución fue construida en Colombia Construye Futuro y no constituye una conclusión automática del Observatorio.”
