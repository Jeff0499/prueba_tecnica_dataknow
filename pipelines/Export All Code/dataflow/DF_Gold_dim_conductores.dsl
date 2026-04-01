source(allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	format: 'parquet') ~> source1
source1 derive(nomb_cond = toString(byName('nomb_cond')),
		apell_cond = toString(byName('apell_cond')),
		tip_doc = toString(byName('tip_doc')),
		num_doc_hash = toString(byName('num_doc_hash')),
		fec_ingreso = toString(byName('fec_ingreso')),
		id_ciudad_base = toString(byName('id_ciudad_base')),
		tip_vehiculo = toString(byName('tip_vehiculo')),
		cod_zona_asignada = toLong(byName('cod_zona_asignada')),
		activo = toLong(byName('activo')),
		calific_promedio_acum = toDouble(byName('calific_promedio_acum')),
		cond_id = toLong(byName('cond_id'))) ~> MapDrifted1
MapDrifted1 derive(antiguedad_anos = floor((currentDate() - toDate(fec_ingreso)) / 365),
		tip_vehiculo_std = iif(tip_vehiculo == 'Moto', 'Moto',
  iif(tip_vehiculo == 'Bicicleta', 'Bicicleta',
    iif(tip_vehiculo == 'Van', 'Van',
	 iif(tip_vehiculo == 'Camion', 'Camion', 'Otro')
    )
  )
)) ~> derivedColumn1
derivedColumn1 select(mapColumn(
		cond_id,
		num_doc_hash,
		antiguedad_anos,
		tip_vehiculo_std,
		id_ciudad_base,
		cod_zona_asignada,
		activo,
		calific_promedio_acum,
		nomb_cond,
		apell_cond
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