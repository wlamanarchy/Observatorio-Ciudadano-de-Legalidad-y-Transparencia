# Hoja de trabajo interna

> Identificador interno de desarrollo: **3.0**. Este número no debe mostrarse como nombre público del Observatorio.

## Objetivo de esta rama

Convertir la aplicación estática en una plataforma multiusuario con trazabilidad nacional y territorial, manteniendo el nombre público **Observatorio Ciudadano de Legalidad y Transparencia**.

## Incorporado en esta etapa

- backend opcional Supabase/PostgreSQL;
- autenticación por enlace temporal para el equipo interno;
- roles nacionales, regionales y territoriales;
- separación del contacto privado del reportante;
- Row Level Security por ámbito territorial;
- bitácora de auditoría de cambios;
- función pública controlada para recepción de reportes;
- función interna para promover o descartar reportes;
- compatibilidad de demostración con `localStorage` si Supabase no está configurado;
- capa de datos preparada para el flujo reporte → curaduría → ficha.

## Roles previstos

- `admin_nacional`
- `curador_nacional`
- `coordinador_regional`
- `curador_territorial`
- `lector_interno`
- `lector_territorial`

## Pendiente antes de producción

1. Crear proyecto Supabase y aplicar la migración SQL.
2. Asignar el primer `admin_nacional` manualmente en `profiles`.
3. Conectar la interfaz actual a la nueva capa `src/lib/store.js`.
4. Incorporar módulo de vencimientos de réplica, petición y traslado.
5. Probar RLS con usuarios de al menos tres ámbitos distintos.
6. Configurar política de privacidad y aviso de tratamiento de datos.
7. Definir canal seguro independiente para fuentes sensibles.
8. Añadir almacenamiento documental con buckets y permisos separados.
9. Añadir pruebas automatizadas del flujo completo.

## Regla de publicación

El nombre público y la metodología del instrumento no cambian por esta numeración interna. El estándar sigue siendo: acto identificable, fuente primaria, norma de contraste, verificación humana y derecho de réplica antes de publicación.
