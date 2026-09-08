# Arquitectura para operación pública nacional y territorial

El nombre público se mantiene: **Observatorio Ciudadano de Legalidad y Transparencia**. La numeración de desarrollo se usa solo internamente.

## Frontend

React + Vite. Puede desplegarse en GitHub Pages para demostración. En producción conviene un hosting con variables de entorno y dominio propio.

## Backend recomendado

Supabase/PostgreSQL por autenticación, Row Level Security, funciones SQL y auditoría. La rama interna incorpora una capa que detecta si existen `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`; si no existen, mantiene modo local de demostración.

## Modelo de datos

- `profiles`: identidad y rol global del equipo.
- `territorial_roles`: permisos por región, departamento o municipio.
- `findings`: fichas del registro.
- `reports`: cola ciudadana de reportes.
- `reporter_private`: contacto del reportante, separado del contenido público.
- `audit_log`: bitácora de cambios.

La ficha conserva además un `payload` JSONB para mantener compatibilidad con el modelo actual mientras se normalizan fuentes, réplicas y traslados en fases posteriores.

## Roles

- `admin_nacional`: administración completa.
- `curador_nacional`: revisión y edición en todo el país.
- `coordinador_regional`: curaduría de su región o ámbito asignado.
- `curador_territorial`: curaduría de departamento/municipio asignado.
- `lector_interno` / `lector_territorial`: lectura interna sin publicación.
- público: lectura de fichas publicadas y envío de reportes mediante función controlada.

## Seguridad

- Nunca exponer `service_role` en el navegador.
- RLS habilitado en todas las tablas.
- El formulario público debe usar `submit_report()` y no INSERT directo a `reports`.
- El contacto del reportante queda fuera del JSON público.
- La promoción o descarte usa `resolve_report()` y valida competencia territorial.
- Los cambios relevantes quedan en `audit_log`.
- Un formulario web común no se presenta como canal anónimo seguro para fuentes internas.

## Flujo operativo

1. Ciudadanía reporta una actuación.
2. El sistema identifica el ámbito territorial.
3. Curador competente revisa fuente y norma.
4. Si procede, el reporte se promueve a ficha; si no, se descarta con trazabilidad.
5. La ficha pasa por verificación, réplica y, cuando corresponda, traslado.
6. Solo se publica cuando cumple los filtros metodológicos.
7. El boletín consume únicamente fichas publicables.

## Despliegue

1. Crear proyecto Supabase.
2. Ejecutar `supabase/migrations/001_internal_v3.sql`.
3. Configurar `.env` a partir de `.env.example`.
4. Integrar la interfaz con `src/lib/store.js`.
5. Probar con una cuenta de administrador y otra territorial antes de abrir el formulario.

## Principio operativo

La automatización puede identificar actos, fechas, entidades y documentos; la clasificación jurídica, el sello DOCUMENTADO y la publicación deben permanecer bajo revisión humana.
