source(allowSchemaDrift: true,
	validateSchema: false,
	inferDriftedColumnTypes: true,
	ignoreNoFilesFound: false,
	format: 'parquet') ~> source1
source(allowSchemaDrift: true,
	validateSchema: false,
	inferDriftedColumnTypes: true,
	ignoreNoFilesFound: false,
	format: 'parquet') ~> source2
source1, source2 join(toString(byName('TMS_ENVIOS.id_remitente')) == toString(byName('dim_remitentes.id_remitente')),
	joinType:'left',
	matchType:'exact',
	ignoreSpaces: false,
	broadcast: 'auto')~> join1
MapDrifted1 derive(tiempo_entrega_real_horas = iif(
    isNull(fec_entrega_real_date) || isNull(hra_recepcion),
    0.0,
    (
	   toLong(toTimestamp(toString(fec_entrega_real_date))) -
	   toLong(toTimestamp(toString(fec_recepcion_date) + ' ' + hra_recepcion))
    ) / 3600.0
)) ~> derivedColumn1
join1 derive(tip_paquete = toString(byName('tip_paquete')),
		id_remitente = toLong(byName('id_remitente')),
		cond_id = toLong(byName('cond_id')),
		id_zona_destino = toLong(byName('id_zona_destino')),
		peso_kg = toDouble(byName('peso_kg')),
		fec_recepcion_date = toDate(byName('fec_recepcion')),
		hra_recepcion = toString(byName('hra_recepcion')),
		fec_entrega_programada = toString(byName('fec_entrega_programada')),
		fec_intento1 = toString(byName('fec_intento1')),
		hra_intento1 = toString(byName('hra_intento1')),
		resultado_intento1 = toString(byName('resultado_intento1')),
		fec_intento2 = toString(byName('fec_intento2')),
		hra_intento2 = toString(byName('hra_intento2')),
		resultado_intento2 = toString(byName('resultado_intento2')),
		fec_entrega_real_date = toDate(byName('fec_entrega_real')),
		estado_final = toString(byName('estado_final')),
		motivo_fallo_cod = toString(byName('motivo_fallo_cod')),
		vr_declarado = toDouble(byName('vr_declarado')),
		id_envio = toLong(byName('id_envio')),
		razon_social = toString(byName('razon_social')),
		tipo_cliente_std = toString(byName('tipo_cliente_std')),
		ciudad_principal = toString(byName('ciudad_principal')),
		sla_entrega_horas_clean = toLong(byName('sla_entrega_horas_clean')),
		penalidad_porc = toLong(byName('penalidad_porc')),
		activo = toLong(byName('activo'))) ~> MapDrifted1
derivedColumn1 derive(cumple_sla = iif(isNull(tiempo_entrega_real_horas), 0, iif(tiempo_entrega_real_horas <= sla_entrega_horas_clean, 1, 0)),
		numero_intentos = iif(isNull(resultado_intento2), 1, 2),
		retraso_categoria = iif(estado_final != 'Entregado', 'No entregado',
  iif(tiempo_entrega_real_horas <= 0, 'A tiempo',
    iif(tiempo_entrega_real_horas <= 4, 'Retraso leve',
	 iif(tiempo_entrega_real_horas <= 24, 'Retraso moderado', 'Retraso critico')
    )
  )
)) ~> derivedColumn2
derivedColumn2 select(mapColumn(
		id_envio,
		id_remitente,
		cond_id,
		id_zona_destino,
		tip_paquete,
		peso_kg,
		fec_recepcion_date,
		hra_recepcion,
		fec_entrega_programada,
		fec_entrega_real_date,
		vr_declarado,
		tiempo_entrega_real_horas,
		cumple_sla,
		numero_intentos,
		retraso_categoria
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> select1
select1 sink(allowSchemaDrift: true,
	validateSchema: false,
	format: 'parquet',
	partitionFileNames:['data.parquet'],
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	partitionBy('hash', 1)) ~> sink1