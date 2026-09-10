# Seguridad, privacidad y accesibilidad

## Privacidad por diseño

- minimización de datos;
- identidad separada de contenidos públicos;
- finalidades explícitas;
- retención limitada;
- control de acceso por rol e institución;
- bitácora de accesos administrativos;
- exportación, corrección y supresión cuando proceda;
- no uso de datos sensibles para ponderar participación.

## Seguridad

- HTTPS obligatorio;
- RLS en todas las tablas expuestas;
- funciones privilegiadas con permisos explícitos y `search_path` fijo;
- rate limiting y CAPTCHA accesible en acciones de alto riesgo;
- MFA para administradores y moderadores;
- backups, recuperación y pruebas de restauración;
- logs inmutables o append-only para eventos críticos;
- revisión de dependencias y CI;
- separación de ambientes desarrollo/piloto/producción.

## Voto

Para el piloto, las votaciones son consultivas. Para votaciones de alta legitimidad se debe separar elegibilidad de la boleta, generar recibo verificable sin revelar la selección, impedir doble voto y habilitar auditoría independiente. Para usos jurídicamente vinculantes se requiere integrar el mecanismo formal y sus garantías específicas.

## Accesibilidad e inclusión

Objetivo mínimo WCAG 2.1 AA: navegación por teclado, foco visible, contraste suficiente, textos alternativos, etiquetas de formularios, subtítulos, lenguaje claro, diseño responsive, lectores de pantalla y no depender únicamente de color. Deben existir canales asistidos/offline con reglas contra doble contabilización.
