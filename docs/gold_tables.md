# Tablas de Agregación en la Capa Gold

Este documento describe las tablas de la capa Gold, que contienen el modelo dimensional y los hechos analíticos del Escenario D (Logística).

## Tablas de Dimensión

### dim_conductores
**Descripción**: Dimensión de conductores, con datos demográficos y de desempeño histórico.  
**Fuente**: `OPE_CONDUCTORES` (Silver)  
**Transformaciones clave**:
- Cálculo de `antiguedad_anos` a partir de `fec_ingreso`.
- Estandarización de `tip_vehiculo` a categorías controladas.
- Se mantienen los hashes de nombres y documentos generados en Silver.

**Columnas principales**:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| cond_id | int | Identificador único del conductor |
| num_doc_hash | string | Hash del documento de identidad |
| antiguedad_anos | int | Años de antigüedad en la empresa |
| tip_vehiculo_std | string | Tipo de vehículo estandarizado (Moto, Bicicleta, Van, Camion, Otro) |
| id_ciudad_base | string | Ciudad base |
| cod_zona_asignada | int | Zona operativa asignada |
| activo | int | 1=activo, 0=inactivo |
| calific_promedio_acum | float | Calificación promedio acumulada |
| nomb_cond_hash | string | Hash del nombre |
| apell_cond_hash | string | Hash del apellido |

---

### dim_remitentes
**Descripción**: Dimensión de clientes remitentes (empresas que envían paquetes).  
**Fuente**: `CLI_REMITENTES` (Silver)  
**Transformaciones clave**:
- Estandarización de `tipo_cliente` en categorías: Ecommerce, Farmaceutico, Retail, Telecomunicaciones, Otro.
- Limpieza de `sla_entrega_horas` (nulos reemplazados por 24).

**Columnas principales**:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id_remitente | int | Identificador único del remitente |
| razon_social_hash | string | Hash de la razón social |
| tipo_cliente_std | string | Tipo de cliente estandarizado |
| ciudad_principal | string | Ciudad principal |
| sla_entrega_horas_clean | int | SLA en horas (valor limpio) |
| penalidad_porc | int | Porcentaje de penalización por incumplimiento |
| activo | int | Estado activo |

---

### dim_zonas
**Descripción**: Dimensión de zonas geográficas, con indicadores de dificultad operativa.  
**Fuente**: `GEO_ZONAS` (Silver)  
**Transformaciones clave**:
- Cálculo de `dificultad_operativa` en escala 1–5 combinando `nivel_trafico_prom` (1,2,3) y `distancia_bodega_km` (normalizada a 0–2).

**Columnas principales**:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id_zona | int | Identificador de la zona |
| nom_zona_hash | string | Hash del nombre de la zona (opcional) |
| id_ciudad | string | Ciudad |
| barrio_referencia | string | Barrio de referencia |
| latitud_centroide | float | Latitud |
| longitud_centroide | float | Longitud |
| nivel_trafico_prom_clean | string | Nivel de tráfico limpio |
| tip_zona | string | Tipo de zona (Residencial, Comercial, Industrial, Mixto) |
| distancia_bodega_km_clean | float | Distancia a la bodega en km |
| dificultad_operativa | int | Índice de dificultad (1=más fácil, 5=más difícil) |

---

## Tablas de Hechos

### fact_envios
**Descripción**: Hechos de envíos con métricas de cumplimiento de SLA y clasificación de retraso.  
**Fuente**: `TMS_ENVIOS` (Silver) + `dim_remitentes` (Gold)  
**Transformaciones clave**:
- Cálculo de `tiempo_entrega_real_horas` como diferencia entre `fec_entrega_real` y `fec_recepcion`.
- `cumple_sla` = 1 si `tiempo_entrega_real_horas <= sla_entrega_horas_clean`.
- `numero_intentos` = 1 si solo existe primer intento, 2 si existe segundo intento.
- `retraso_categoria` según rangos: ≤0 → 'A tiempo', 1-4 → 'Retraso leve', 4-24 → 'Retraso moderado', >24 → 'Retraso critico', si estado_final ≠ 'Entregado' → 'No entregado'.

**Columnas principales**:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id_envio | int | Identificador único del envío |
| id_remitente | int | Remitente (FK a dim_remitentes) |
| cond_id | int | Conductor (FK a dim_conductores) |
| id_zona_destino | int | Zona destino (FK a dim_zonas) |
| tip_paquete | string | Tipo de paquete |
| peso_kg | float | Peso en kg |
| fec_recepcion | date | Fecha de recepción |
| hra_recepcion | time | Hora de recepción |
| fec_entrega_programada | timestamp | Fecha/hora programada de entrega |
| fec_entrega_real | timestamp | Fecha/hora real de entrega |
| vr_declarado | float | Valor declarado |
| tiempo_entrega_real_horas | double | Diferencia real en horas |
| cumple_sla | int | 1 si cumple SLA, 0 en caso contrario |
| numero_intentos | int | Número de intentos realizados |
| retraso_categoria | string | Categoría de retraso (o 'No entregado') |

---

### fact_rutas
**Descripción**: Métricas de eficiencia de las rutas realizadas por los conductores.  
**Fuente**: `GPS_RUTAS` (Silver)  
**Transformaciones clave**:
- Cálculo de `horas_trabajadas` a partir de `hra_inicio` y `hra_fin` (manejo de cruce de medianoche).
- `eficiencia_ruta` = `num_paradas_real / num_paradas_plan` (protección contra división por cero).
- `velocidad_promedio_kmh` = `km_recorridos / horas_trabajadas`.
- `desviacion_porcentaje` = `(desviacion_ruta_km / km_recorridos) * 100`.

**Columnas principales**:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id_ruta | int | Identificador de la ruta |
| cond_id | int | Conductor (FK a dim_conductores) |
| fec_ruta | date | Fecha de la ruta |
| hra_inicio | time | Hora de inicio |
| hra_fin | time | Hora de fin |
| km_recorridos_clean | float | Kilómetros recorridos |
| num_paradas_plan_clean | int | Paradas planificadas |
| num_paradas_real_clean | int | Paradas reales |
| desviacion_ruta_km_clean | float | Desviación en km |
| consumo_combustible | float | Consumo de combustible |
| horas_trabajadas | double | Horas trabajadas |
| eficiencia_ruta | double | Relación paradas reales/planificadas |
| velocidad_promedio_kmh | double | Velocidad media |
| desviacion_porcentaje | double | Desviación porcentual |

---

### fact_desempeno_conductor
**Descripción**: Tabla de hechos que consolida métricas de desempeño diario por conductor y calcula un score ponderado.  
**Fuente**: Unión de `TMS_ENVIOS`, `GPS_RUTAS` y `CAL_DESTINATARIOS` (Silver)  
**Transformaciones clave**:
- Agregación diaria para obtener `tasa_exito`, `adherencia_ruta_prom`, `velocidad_promedio`, `intentos_promedio`, `calificacion_promedio`.
- Normalización (escala 0-1) de cada componente usando valores mínimos y máximos globales.
- Inversión de la métrica de intentos (menor número es mejor).
- Score ponderado:  
  `(tasa_norm × 0.35) + (adherencia_norm × 0.20) + (velocidad_norm × 0.20) + (inversa_intentos_norm × 0.15) + (calificacion_norm × 0.10)`  
  redondeado a dos decimales.

**Columnas principales**:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| cond_id | int | Conductor |
| fecha | date | Día del desempeño |
| tasa_exito | double | Proporción de entregas exitosas |
| adherencia_ruta_prom | double | Promedio de adherencia a la ruta |
| velocidad_promedio | double | Velocidad media (km/h) |
| intentos_promedio | double | Promedio de intentos por envío |
| calificacion_promedio | double | Promedio de puntualidad+cortesía |
| tasa_norm | double | Tasa normalizada (0-1) |
| adherencia_norm | double | Adherencia normalizada (0-1) |
| velocidad_norm | double | Velocidad normalizada (0-1) |
| inversa_intentos_norm | double | Intentos invertidos normalizados (0-1) |
| calificacion_norm | double | Calificación normalizada (0-1) |
| score_desempeno | double | Score ponderado final (0-1) |
| total_envios | int | Total de envíos en el día |

---

### fact_trazabilidad_envio
**Descripción**: Línea de tiempo completa de cada envío, con todos los eventos (recepción, intentos, entrega) y novedades, incluyendo el tiempo transcurrido entre eventos consecutivos.  
**Fuente**: Unión de `TMS_ENVIOS` y `DIR_NOVEDADES` (Silver)  
**Transformaciones clave**:
- Cada registro de `TMS_ENVIOS` se descompone en eventos individuales (recepción, intento1, intento2, entrega).
- Los eventos se unen con las novedades (`DIR_NOVEDADES`).
- Se ordenan cronológicamente por envío y se calcula `tiempo_desde_anterior_horas` mediante una función `lag`.

**Columnas principales**:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id_envio | int | Envío asociado |
| timestamp_evento | timestamp | Momento exacto del evento |
| tipo_evento | string | Tipo: 'Recepcion', 'Intento1', 'Intento2', 'Entrega', 'Novedad' |
| descripcion | string | Descripción (para novedades) |
| resultado | string | Resultado del intento o tipo de novedad |
| tiempo_desde_anterior_horas | double | Diferencia en horas con el evento anterior del mismo envío |

---

### fact_alertas_zona
**Descripción**: Tabla de alertas diarias para zonas donde la tasa de fallo supera en más del 25% el promedio de las últimas cuatro semanas (mismo día de la semana).  
**Fuente**: `fact_envios` (Gold)  
**Transformaciones clave**:
- Se define fallo cuando `retraso_categoria == 'No entregado'`.
- Agregación diaria por zona y día de semana para obtener `tasa_fallo_actual`.
- Cálculo del promedio histórico de las últimas 4 semanas (excluyendo hoy) para cada zona y día de semana.
- Alerta = 1 si `tasa_actual > promedio_historico × 1.25`.

**Columnas principales**:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| zona_id | int | Identificador de la zona (FK a dim_zonas) |
| fecha | date | Fecha de la alerta |
| tasa_fallo_actual | double | Tasa de fallo del día actual |
| promedio_historico | double | Promedio de las últimas 4 semanas (mismo día) |
| desviacion_porcentaje | double | (tasa_actual - promedio)/promedio × 100 |
| alerta_generada | int | 1 si se supera el umbral, 0 en caso contrario |

---

**Nota**: Este documento cubre todas las tablas Gold construidas en la solución. Las tablas destacadas como `fact_envios`, `fact_desempeno_conductor` y `fact_alertas_zona` constituyen las tablas de agregación requeridas en el entregable de la Fase 3.