source(allowSchemaDrift: true,
	validateSchema: false,
	inferDriftedColumnTypes: true,
	ignoreNoFilesFound: false,
	format: 'parquet') ~> source1
MapDrifted1 aggregate(groupBy(cond_id,
		fec_calificacion,
		puntualidad,
		cortesia,
		comentario),
	id_calificacion = first(id_calificacion)) ~> aggregate1
aggregate1 derive(puntualidad = coalesce(puntualidad, 3)) ~> derivedColumn1
source1 derive(id_calificacion = toLong(byName('id_calificacion')),
		cond_id = toLong(byName('cond_id')),
		fec_calificacion = toString(byName('fec_calificacion')),
		puntualidad = toLong(byName('puntualidad')),
		cortesia = toLong(byName('cortesia')),
		comentario = toString(byName('comentario'))) ~> MapDrifted1
derivedColumn1 sink(allowSchemaDrift: true,
	validateSchema: false,
	format: 'parquet',
	partitionFileNames:['data.parquet'],
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	partitionBy('hash', 1)) ~> sink1