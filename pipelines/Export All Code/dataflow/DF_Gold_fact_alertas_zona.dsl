source(allowSchemaDrift: true,
	validateSchema: false,
	inferDriftedColumnTypes: true,
	ignoreNoFilesFound: false,
	format: 'parquet') ~> source1
source1 derive(id_envio = toLong(byName('id_envio')),
		id_remitente = toLong(byName('id_remitente')),
		cond_id = toLong(byName('cond_id')),
		id_zona_destino = toLong(byName('id_zona_destino')),
		tip_paquete = toString(byName('tip_paquete')),
		peso_kg = toDouble(byName('peso_kg')),
		fec_recepcion_date = toDate(byName('fec_recepcion_date')),
		hra_recepcion = toString(byName('hra_recepcion')),
		fec_entrega_programada = toString(byName('fec_entrega_programada')),
		fec_entrega_real_date = toDate(byName('fec_entrega_real_date')),
		vr_declarado = toDouble(byName('vr_declarado')),
		tiempo_entrega_real_horas = toDouble(byName('tiempo_entrega_real_horas')),
		cumple_sla = toInteger(byName('cumple_sla')),
		numero_intentos = toInteger(byName('numero_intentos')),
		retraso_categoria = toString(byName('retraso_categoria'))) ~> MapDrifted1
MapDrifted1 derive(fecha = fec_entrega_real_date) ~> derivedColumn1
derivedColumn1 derive(dia_semana = dayOfWeek(fecha),
		es_fallo = iif(retraso_categoria == 'No entregado', 1, 0)) ~> derivedColumn2
derivedColumn2 aggregate(groupBy(id_zona_destino,
		fecha,
		dia_semana),
	total_envios = count(1),
		fallos = sum(es_fallo)) ~> aggregate1
aggregate1 derive(tasa_fallo = fallos / total_envios) ~> derivedColumn3
derivedColumn3 filter(fecha >= addDays(currentDate(), -28) && fecha < currentDate()) ~> filter1
filter1 aggregate(groupBy(id_zona_destino,
		dia_semana),
	promedio_historico = avg(tasa_fallo)) ~> aggregate2
derivedColumn3, aggregate2 join(aggregate1@id_zona_destino == aggregate2@id_zona_destino
	&& aggregate1@dia_semana == aggregate2@dia_semana,
	joinType:'left',
	matchType:'exact',
	ignoreSpaces: false,
	broadcast: 'auto')~> join1
join1 derive(desviacion_porcentaje = iif(isNull(promedio_historico) || promedio_historico == 0, -1.0, toFloat((tasa_fallo - promedio_historico) / promedio_historico * 100)),
		alerta_generada = iif(tasa_fallo > promedio_historico * 1.25, 1, 0)) ~> derivedColumn4
derivedColumn4 select(mapColumn(
		id_zona_destino = aggregate1@id_zona_destino,
		fecha,
		tasa_fallo,
		promedio_historico,
		desviacion_porcentaje,
		alerta_generada
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