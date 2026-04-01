source(allowSchemaDrift: true,
	validateSchema: false,
	inferDriftedColumnTypes: true,
	ignoreNoFilesFound: false,
	format: 'parquet') ~> source1
source1 derive(razon_social = toString(byName('razon_social')),
		tipo_cliente = toString(byName('tipo_cliente')),
		ciudad_principal = toString(byName('ciudad_principal')),
		sla_entrega_horas = toLong(byName('sla_entrega_horas')),
		penalidad_porc = toLong(byName('penalidad_porc')),
		activo = toLong(byName('activo')),
		id_remitente = toLong(byName('id_remitente'))) ~> MapDrifted1
MapDrifted1 derive(tipo_cliente_std = iif(tipo_cliente == 'Ecommerce', 'Ecommerce',
  iif(tipo_cliente == 'Farmaceutico', 'Farmaceutico',
    iif(tipo_cliente == 'Retail', 'Retail',
	 iif(tipo_cliente == 'Telecomunicaciones', 'Telecomunicaciones',
	   'Otro'
	 )
    )
  )
),
		sla_entrega_horas_clean = coalesce(sla_entrega_horas, 24)) ~> derivedColumn1
derivedColumn1 select(mapColumn(
		id_remitente,
		razon_social,
		tipo_cliente_std,
		ciudad_principal,
		sla_entrega_horas_clean,
		penalidad_porc,
		activo
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