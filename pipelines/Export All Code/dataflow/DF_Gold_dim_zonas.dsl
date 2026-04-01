source(allowSchemaDrift: true,
	validateSchema: false,
	inferDriftedColumnTypes: true,
	ignoreNoFilesFound: false,
	format: 'parquet') ~> source1
source1 derive(nom_zona = toString(byName('nom_zona')),
		id_ciudad = toString(byName('id_ciudad')),
		barrio_referencia = toString(byName('barrio_referencia')),
		latitud_centroide = toDouble(byName('latitud_centroide')),
		longitud_centroide = toDouble(byName('longitud_centroide')),
		nivel_trafico_prom = toString(byName('nivel_trafico_prom')),
		tip_zona = toString(byName('tip_zona')),
		distancia_bodega_km = toDouble(byName('distancia_bodega_km')),
		id_zona = toLong(byName('id_zona'))) ~> MapDrifted1
MapDrifted1 derive(nivel_trafico_prom_clean = coalesce(nivel_trafico_prom, 'Medio'),
		distancia_bodega_km_clean = coalesce(distancia_bodega_km, 20.0)) ~> derivedColumn1
derivedColumn1 derive(trafico_val = iif(nivel_trafico_prom_clean == 'Bajo', 1,
  iif(nivel_trafico_prom_clean == 'Medio', 2,
    iif(nivel_trafico_prom_clean == 'Alto', 3, 2)
  )
)) ~> derivedColumn2
derivedColumn2 derive(calc_dificultad = iif(toInteger(round(trafico_val + (distancia_bodega_km_clean / 40) * 2, 0)) < 1, 1,
  iif(toInteger(round(trafico_val + (distancia_bodega_km_clean / 40) * 2, 0)) > 5, 5,
    toInteger(round(trafico_val + (distancia_bodega_km_clean / 40) * 2, 0))
  )
)) ~> derivedColumn3
derivedColumn3 sink(allowSchemaDrift: true,
	validateSchema: false,
	format: 'parquet',
	partitionFileNames:['data.parquet'],
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	partitionBy('hash', 1)) ~> sink1