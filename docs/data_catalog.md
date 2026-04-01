# Catálogo de Datos

## Capa Silver (Limpia y enmascarada)

### OPE_CONDUCTORES
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| cond_id | int | Identificador del conductor | No |
| nomb_cond_hash | string | Hash SHA-256 del nombre | Sí (enmascarado) |
| apell_cond_hash | string | Hash SHA-256 del apellido | Sí (enmascarado) |
| tip_doc | string | Tipo de documento | No |
| num_doc_hash | string | Hash SHA-256 del número de documento | Sí (enmascarado) |
| fec_ingreso | date | Fecha de ingreso | No |
| id_ciudad_base | string | Ciudad base | No |
| tip_vehiculo | string | Tipo de vehículo | No |
| cod_zona_asignada | int | Zona asignada | No |
| activo | int | 1=activo, 0=inactivo | No |
| calific_promedio_acum | float | Calificación promedio acumulada (nulos reemplazados por 3.0) | No |

### CLI_REMITENTES
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_remitente | int | Identificador del remitente | No |
| razon_social_hash | string | Hash SHA-256 de la razón social | Sí (enmascarado) |
| tipo_cliente_std | string | Tipo de cliente estandarizado (Ecommerce, Farmaceutico, Retail, Telecomunicaciones, Otro) | No |
| ciudad_principal | string | Ciudad principal | No |
| sla_entrega_horas_clean | int | SLA en horas (nulos reemplazados por 24) | No |
| penalidad_porc | int | Porcentaje de penalización por incumplimiento | No |
| activo | int | 1=activo, 0=inactivo | No |

### GEO_ZONAS
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_zona | int | Identificador de la zona | No |
| nom_zona_hash | string | Hash SHA-256 del nombre de la zona | Sí (enmascarado, opcional) |
| id_ciudad | string | Ciudad | No |
| barrio_referencia | string | Barrio de referencia | No |
| latitud_centroide | float | Latitud | No |
| longitud_centroide | float | Longitud | No |
| nivel_trafico_prom_clean | string | Nivel de tráfico limpio (Bajo, Medio, Alto) | No |
| tip_zona | string | Tipo de zona (Residencial, Comercial, Industrial, Mixto) | No |
| distancia_bodega_km_clean | float | Distancia a la bodega en km (nulos reemplazados por 20.0) | No |

### TMS_ENVIOS
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_envio | int | Identificador del envío | No |
| id_remitente | int | Remitente | No |
| cond_id | int | Conductor asignado | No |
| id_zona_destino | int | Zona destino | No |
| tip_paquete | string | Tipo de paquete | No |
| peso_kg | float | Peso en kg | No |
| fec_recepcion | date | Fecha de recepción | No |
| hra_recepcion | time | Hora de recepción | No |
| fec_entrega_programada | timestamp | Fecha y hora programada de entrega | No |
| fec_intento1 | date | Fecha del primer intento | No |
| hra_intento1 | time | Hora del primer intento | No |
| resultado_intento1 | string | Resultado del primer intento | No |
| fec_intento2 | date | Fecha del segundo intento | No |
| hra_intento2 | time | Hora del segundo intento | No |
| resultado_intento2 | string | Resultado del segundo intento | No |
| fec_entrega_real | timestamp | Fecha y hora real de entrega | No |
| estado_final | string | Estado final del envío | No |
| motivo_fallo_cod | string | Motivo de fallo (original) | No |
| vr_declarado | float | Valor declarado del envío | No |
| hra_intento1_fixed | string | Hora intento 1 con nulos reemplazados por '00:00:00' | No |
| motivo_fallo_cod_fixed | string | Motivo de fallo con nulos reemplazados por 'No especificado' | No |
| resultado_intento1_fixed | string | Resultado intento 1 con nulos reemplazados por 'Sin intento' | No |
| ... (otras columnas de auditoría batch_id, ingest_timestamp, source_system) | | | No |

### GPS_RUTAS
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_ruta | int | Identificador de la ruta | No |
| cond_id | int | Conductor | No |
| fec_ruta | date | Fecha de la ruta | No |
| hra_inicio | time | Hora inicio | No |
| hra_fin | time | Hora fin | No |
| km_recorridos | float | Kilómetros recorridos | No |
| num_paradas_plan | int | Número de paradas planificadas | No |
| num_paradas_real | int | Número de paradas reales | No |
| desviacion_ruta_km | float | Desviación de la ruta en km | No |
| consumo_combustible | float | Consumo de combustible | No |
| (tras limpieza se añaden columnas con valores por defecto) | | | No |

### CAL_DESTINATARIOS
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_calificacion | int | Identificador de la calificación | No |
| cond_id | int | Conductor | No |
| fec_calificacion | date | Fecha de calificación | No |
| puntualidad | int | Puntuación de puntualidad (1-5) | No |
| cortesia | int | Puntuación de cortesía (1-5) | No |
| comentario | string | Comentario (opcional) | No |

### DIR_NOVEDADES
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_novedad | int | Identificador de la novedad | No |
| id_envio | int | Envío relacionado | No |
| fec_novedad | date | Fecha de la novedad | No |
| tip_novedad | string | Tipo de novedad | No |
| desc_novedad | string | Descripción (posiblemente sensible) | Sí (si contiene datos personales) |
| id_agente_registro | int | Agente que registró | No |
| requiere_accion | bool | Si requiere acción | No |

---

## Capa Gold (Modelo Analítico)

### dim_conductores
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| cond_id | int | Identificador del conductor | No |
| num_doc_hash | string | Hash del documento | Sí (enmascarado) |
| antiguedad_anos | int | Años de antigüedad en la empresa | No |
| tip_vehiculo_std | string | Tipo de vehículo estandarizado (Moto, Bicicleta, Van, Camion, Otro) | No |
| id_ciudad_base | string | Ciudad base | No |
| cod_zona_asignada | int | Zona asignada | No |
| activo | int | 1=activo, 0=inactivo | No |
| calific_promedio_acum | float | Calificación promedio acumulada | No |
| nomb_cond_hash | string | Hash del nombre | Sí (enmascarado) |
| apell_cond_hash | string | Hash del apellido | Sí (enmascarado) |

### dim_remitentes
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_remitente | int | Identificador del remitente | No |
| razon_social_hash | string | Hash de la razón social | Sí (enmascarado) |
| tipo_cliente_std | string | Tipo de cliente estandarizado | No |
| ciudad_principal | string | Ciudad principal | No |
| sla_entrega_horas_clean | int | SLA en horas | No |
| penalidad_porc | int | Penalización porcentual | No |
| activo | int | Estado activo | No |

### dim_zonas
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_zona | int | Identificador de la zona | No |
| nom_zona_hash | string | Hash del nombre de la zona | Sí (enmascarado, opcional) |
| id_ciudad | string | Ciudad | No |
| barrio_referencia | string | Barrio de referencia | No |
| latitud_centroide | float | Latitud | No |
| longitud_centroide | float | Longitud | No |
| nivel_trafico_prom_clean | string | Nivel de tráfico limpio | No |
| tip_zona | string | Tipo de zona | No |
| distancia_bodega_km_clean | float | Distancia a bodega limpia | No |
| dificultad_operativa | int | Índice de dificultad (1-5) | No |

### fact_envios
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_envio | int | Identificador del envío | No |
| id_remitente | int | Remitente | No |
| cond_id | int | Conductor | No |
| id_zona_destino | int | Zona destino | No |
| tip_paquete | string | Tipo de paquete | No |
| peso_kg | float | Peso | No |
| fec_recepcion | date | Fecha de recepción | No |
| hra_recepcion | time | Hora de recepción | No |
| fec_entrega_programada | timestamp | Fecha/hora programada | No |
| fec_entrega_real | timestamp | Fecha/hora real de entrega | No |
| vr_declarado | float | Valor declarado | No |
| tiempo_entrega_real_horas | double | Diferencia real (horas) | No |
| cumple_sla | int | 1 si cumple SLA, 0 en caso contrario | No |
| numero_intentos | int | Número de intentos realizados | No |
| retraso_categoria | string | Categoría de retraso o 'No entregado' | No |
| batch_id | string | ID del lote de procesamiento | No |
| ingest_timestamp | timestamp | Marca de tiempo de ingesta | No |
| source_system | string | Sistema de origen | No |

### fact_rutas
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_ruta | int | Identificador de la ruta | No |
| cond_id | int | Conductor | No |
| fec_ruta | date | Fecha de la ruta | No |
| hra_inicio | time | Hora inicio | No |
| hra_fin | time | Hora fin | No |
| km_recorridos_clean | float | Kilómetros recorridos | No |
| num_paradas_plan_clean | int | Paradas planificadas | No |
| num_paradas_real_clean | int | Paradas reales | No |
| desviacion_ruta_km_clean | float | Desviación en km | No |
| consumo_combustible | float | Consumo de combustible | No |
| horas_trabajadas | double | Horas trabajadas | No |
| eficiencia_ruta | double | Relación paradas reales/planificadas | No |
| velocidad_promedio_kmh | double | Velocidad media (km/h) | No |
| desviacion_porcentaje | double | Desviación porcentual | No |

### fact_desempeno_conductor
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| cond_id | int | Conductor | No |
| fecha | date | Día del desempeño | No |
| tasa_exito | double | Proporción de entregas exitosas | No |
| adherencia_ruta_prom | double | Promedio de adherencia a la ruta | No |
| velocidad_promedio | double | Velocidad media (km/h) | No |
| intentos_promedio | double | Promedio de intentos por envío | No |
| calificacion_promedio | double | Promedio de puntualidad+cortesía | No |
| tasa_norm | double | Tasa normalizada (0-1) | No |
| adherencia_norm | double | Adherencia normalizada (0-1) | No |
| velocidad_norm | double | Velocidad normalizada (0-1) | No |
| inversa_intentos_norm | double | Intentos invertidos normalizados (0-1) | No |
| calificacion_norm | double | Calificación normalizada (0-1) | No |
| score_desempeno | double | Score ponderado final (0-1) | No |
| total_envios | int | Total de envíos en el día | No |

### fact_trazabilidad_envio
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| id_envio | int | Envío | No |
| timestamp_evento | timestamp | Momento exacto del evento | No |
| tipo_evento | string | Tipo de evento (Recepcion, Intento1, Intento2, Entrega, Novedad) | No |
| descripcion | string | Descripción (para novedades) | No |
| resultado | string | Resultado del intento o tipo de novedad | No |
| tiempo_desde_anterior_horas | double | Diferencia en horas con el evento anterior (mismo envío) | No |

### fact_alertas_zona
| Campo | Tipo | Descripción | Sensible |
|-------|------|-------------|----------|
| zona_id | int | Identificador de la zona | No |
| fecha | date | Fecha de la alerta | No |
| tasa_fallo_actual | double | Tasa de fallo del día actual | No |
| promedio_historico | double | Promedio de las últimas 4 semanas (mismo día de semana) | No |
| desviacion_porcentaje | double | (tasa_actual - promedio)/promedio * 100 | No |
| alerta_generada | int | 1 si la tasa actual supera en 25% el promedio histórico | No |

---

**Nota:** Todas las columnas sensibles en la capa Silver han sido enmascaradas mediante hash SHA-256, y las columnas originales han sido eliminadas. En la capa Gold se mantienen los hashes, asegurando que ningún dato personal sea accesible.