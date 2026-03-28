import pandas as pd
import numpy as np
from faker import Faker
import hashlib
import yaml
from datetime import datetime, timedelta
import random
import os

# ========== 1. Cargar configuración ==========
with open('config.yaml', 'r') as f:
    config = yaml.safe_load(f)

seed = config['seed']
np.random.seed(seed)
random.seed(seed)
fake = Faker()
fake.seed_instance(seed)

start_date = datetime.strptime(config['date_range']['start'], "%Y-%m-%d")
end_date = datetime.strptime(config['date_range']['end'], "%Y-%m-%d")
date_span = (end_date - start_date).days
output_formats = config['output_formats']
anomalies = config['anomalies']
volumes = config['volumes']

# ========== 2. Funciones auxiliares ==========
def add_anomalies(df, table_name):
    """Añade duplicados y nulos según tasas definidas."""
    # Duplicados: copiar un porcentaje de registros y añadirlos al final
    dup_count = int(len(df) * anomalies['duplicate_rate'])
    if dup_count > 0:
        dup_df = df.sample(n=dup_count, random_state=seed)
        df = pd.concat([df, dup_df], ignore_index=True)
    
    # Nulos en columnas no críticas (definir por tabla)
    if table_name == 'TMS_ENVIOS':
        null_mask = np.random.random(len(df)) < anomalies['null_rate']
        df.loc[null_mask, 'hra_intento1'] = None
        df.loc[null_mask, 'motivo_fallo_cod'] = None
    # Puedes añadir más condiciones para otras tablas si lo deseas
    
    return df

def out_of_range_date(base_date):
    """Devuelve una fecha fuera del rango configurado con probabilidad."""
    if random.random() < anomalies['out_of_range_rate']:
        delta = timedelta(days=random.choice([-365, 365]))
        return base_date + delta
    return base_date

def invalid_id(id_list):
    """Devuelve un ID inválido con probabilidad."""
    if random.random() < anomalies['referential_integrity_violation_rate']:
        return max(id_list) + random.randint(1, 100)  # ID no existente
    return random.choice(id_list)

# ========== 3. Generar dimensiones ==========
def generate_conductores(n):
    ciudades = ['Bogotá', 'Medellín', 'Cali', 'Barranquilla', 'Cartagena', 
                'Bucaramanga', 'Pereira', 'Manizales', 'Santa Marta', 'Cúcuta']
    vehiculos = ['Moto', 'Bicicleta', 'Van', 'Camion']
    data = []
    for i in range(1, n+1):
        doc = fake.unique.random_number(digits=10)
        doc_hash = hashlib.sha256(str(doc).encode()).hexdigest()
        fec_ingreso = fake.date_between(start_date='-5y', end_date='today')
        ciudad = np.random.choice(ciudades)
        vehiculo = np.random.choice(vehiculos, p=[0.5,0.2,0.2,0.1])
        zona = np.random.randint(1, volumes['GEO_ZONAS']+1)  # luego se generará, pero el id es numérico
        activo = np.random.choice([1,0], p=[0.95,0.05])
        calif = np.clip(np.random.normal(4.0, 0.5), 1, 5)
        data.append({
            'cond_id': i,
            'nomb_cond': fake.first_name(),
            'apell_cond': fake.last_name(),
            'tip_doc': 'CC',
            'num_doc_hash': doc_hash,
            'fec_ingreso': fec_ingreso,
            'id_ciudad_base': ciudad,
            'tip_vehiculo': vehiculo,
            'cod_zona_asignada': zona,
            'activo': activo,
            'calific_promedio_acum': round(calif, 2)
        })
    df = pd.DataFrame(data)
    df = add_anomalies(df, 'OPE_CONDUCTORES')
    return df

def generate_remitentes(n):
    tipos = ['Ecommerce', 'Farmaceutico', 'Retail', 'Telecomunicaciones', 'Otro']
    ciudades = ['Bogotá', 'Medellín', 'Cali', 'Barranquilla', 'Cartagena']
    data = []
    for i in range(1, n+1):
        penalidad = np.random.choice([2,3,4,5,6,7,8], p=[0.1,0.15,0.2,0.2,0.15,0.1,0.1])
        sla_horas = np.random.choice([12, 24, 48], p=[0.6,0.3,0.1])
        data.append({
            'id_remitente': i,
            'razon_social': fake.company(),
            'tipo_cliente': np.random.choice(tipos),
            'ciudad_principal': np.random.choice(ciudades),
            'sla_entrega_horas': sla_horas,
            'penalidad_porc': penalidad,
            'activo': np.random.choice([1,0], p=[0.95,0.05])
        })
    df = pd.DataFrame(data)
    df = add_anomalies(df, 'CLI_REMITENTES')
    return df

def generate_zonas(n):
    ciudades = ['Bogotá', 'Medellín', 'Cali', 'Barranquilla', 'Cartagena', 
                'Bucaramanga', 'Pereira', 'Manizales', 'Santa Marta', 'Cúcuta']
    niveles_trafico = ['Bajo', 'Medio', 'Alto']
    tipos_zona = ['Residencial', 'Comercial', 'Industrial', 'Mixto']
    data = []
    for i in range(1, n+1):
        ciudad = np.random.choice(ciudades)
        trafico = np.random.choice(niveles_trafico, p=[0.3,0.5,0.2])
        if trafico == 'Alto':
            distancia = np.random.uniform(5, 15)
        elif trafico == 'Medio':
            distancia = np.random.uniform(10, 25)
        else:
            distancia = np.random.uniform(20, 40)
        data.append({
            'id_zona': i,
            'nom_zona': f"Zona_{i}",
            'id_ciudad': ciudad,
            'barrio_referencia': fake.street_name(),
            'latitud_centroide': np.random.uniform(4, 12),
            'longitud_centroide': np.random.uniform(-80, -70),
            'nivel_trafico_prom': trafico,
            'tip_zona': np.random.choice(tipos_zona),
            'distancia_bodega_km': round(distancia, 1)
        })
    df = pd.DataFrame(data)
    df = add_anomalies(df, 'GEO_ZONAS')
    return df

# ========== 4. Generar hechos ==========
def generate_envios(n, df_conductores, df_remitentes, df_zonas):
    cond_ids = df_conductores['cond_id'].tolist()
    remit_ids = df_remitentes['id_remitente'].tolist()
    zona_ids = df_zonas['id_zona'].tolist()
    tipos_paquete = ['Sobre', 'Caja pequeña', 'Caja mediana', 'Caja grande', 'Palé']
    resultados = ['Entregado', 'Intento fallido', 'Devuelto', 'Perdido']
    motivos = ['Destinatario ausente', 'Dirección incorrecta', 'Zona difícil', 'Paquete rechazado', 'Otro']
    
    data = []
    for i in range(1, n+1):
        # Fecha de recepción (con estacionalidad: más en nov-dic)
        offset = np.random.randint(0, date_span)
        fec_recepcion = start_date + timedelta(days=offset)
        fec_recepcion = out_of_range_date(fec_recepcion)
        hora_recepcion = f"{np.random.randint(0,24):02d}:{np.random.randint(0,60):02d}:00"
        
        # Obtener SLA del remitente (seleccionamos uno al azar con pesos uniformes)
        remitente = df_remitentes.sample(1).iloc[0]
        sla_horas = remitente['sla_entrega_horas']
        fec_programada = fec_recepcion + timedelta(hours=int(sla_horas))
        
        # Decidir estado final
        resultado_final = np.random.choice(resultados, p=[0.7,0.2,0.08,0.02])
        if resultado_final == 'Entregado':
            fec_entrega_real = fec_programada + timedelta(hours=np.random.uniform(-4, 8))
            motivo = None
        else:
            fec_entrega_real = None
            motivo = np.random.choice(motivos)
        
        # Intentos
        if resultado_final != 'Entregado':
            fec_intento1 = fec_programada
            hra_intento1 = f"{np.random.randint(8,20):02d}:00:00"
            resultado_intento1 = resultado_final
            # segundo intento solo si es 'Intento fallido' y no 'Devuelto' o 'Perdido'
            if resultado_final == 'Intento fallido' and np.random.rand() < 0.6:
                fec_intento2 = fec_intento1 + timedelta(days=1)
                hra_intento2 = f"{np.random.randint(8,20):02d}:00:00"
                resultado_intento2 = np.random.choice(['Entregado', 'Intento fallido'], p=[0.5,0.5])
            else:
                fec_intento2 = None
                hra_intento2 = None
                resultado_intento2 = None
        else:
            fec_intento1 = None
            hra_intento1 = None
            resultado_intento1 = None
            fec_intento2 = None
            hra_intento2 = None
            resultado_intento2 = None
        
        # ID de conductor con posible violación de integridad referencial
        cond_id = invalid_id(cond_ids)
        remit_id = invalid_id(remit_ids)
        zona_id = invalid_id(zona_ids)
        
        data.append({
            'id_envio': i,
            'id_remitente': remit_id,
            'cond_id': cond_id,
            'id_zona_destino': zona_id,
            'tip_paquete': np.random.choice(tipos_paquete),
            'peso_kg': round(np.random.exponential(5), 2),
            'fec_recepcion': fec_recepcion,
            'hra_recepcion': hora_recepcion,
            'fec_entrega_programada': fec_programada,
            'fec_intento1': fec_intento1,
            'hra_intento1': hra_intento1,
            'resultado_intento1': resultado_intento1,
            'fec_intento2': fec_intento2,
            'hra_intento2': hra_intento2,
            'resultado_intento2': resultado_intento2,
            'fec_entrega_real': fec_entrega_real,
            'estado_final': resultado_final,
            'motivo_fallo_cod': motivo,
            'vr_declarado': round(np.random.lognormal(5, 1), 2)
        })
    df = pd.DataFrame(data)
    df = add_anomalies(df, 'TMS_ENVIOS')
    return df

def generate_gps_rutas(n, df_conductores):
    cond_ids = df_conductores['cond_id'].tolist()
    data = []
    for i in range(1, n+1):
        fecha = fake.date_between(start_date=datetime(2024, 1, 1), end_date=datetime(2024, 12, 31))
        data.append({
            'id_ruta': i,
            'cond_id': invalid_id(cond_ids),
            'fec_ruta': fecha,
            'hra_inicio': f"{np.random.randint(6,10):02d}:00:00",
            'hra_fin': f"{np.random.randint(14,20):02d}:00:00",
            'km_recorridos': round(np.random.uniform(20, 120), 1),
            'num_paradas_plan': np.random.randint(5, 30),
            'num_paradas_real': np.random.randint(5, 30),
            'desviacion_ruta_km': round(np.random.exponential(2), 1),
            'consumo_combustible': round(np.random.uniform(5, 20), 2)
        })
    df = pd.DataFrame(data)
    df = add_anomalies(df, 'GPS_RUTAS')
    return df

def generate_cal_destinatarios(n, df_conductores):
    # Nota: Esta tabla es CAL_DESTINATARIOS (no DIR_NOVEDADES) según el enunciado.
    # El nombre en el enunciado es CAL_DESTINATARIOS.
    cond_ids = df_conductores['cond_id'].tolist()
    data = []
    for i in range(1, n+1):
        fecha = fake.date_between(start_date=datetime(2024, 1, 1), end_date=datetime(2024, 12, 31))
        # Para simular una tabla de calificaciones de destinatarios, usamos campos adecuados
        data.append({
            'id_calificacion': i,
            'cond_id': invalid_id(cond_ids),
            'fec_calificacion': fecha,
            'puntualidad': np.random.randint(1,6),
            'cortesia': np.random.randint(1,6),
            'comentario': fake.sentence() if np.random.rand() > 0.7 else None
        })
    df = pd.DataFrame(data)
    df = add_anomalies(df, 'CAL_DESTINATARIOS')
    return df

def generate_dir_novedades(n, df_envios):
    envio_ids = df_envios['id_envio'].tolist()
    data = []
    for i in range(1, n+1):
        fecha = fake.date_between(start_date=datetime(2024, 1, 1), end_date=datetime(2024, 12, 31))
        data.append({
            'id_novedad': i,
            'id_envio': invalid_id(envio_ids),
            'fec_novedad': fecha,
            'tip_novedad': np.random.choice(['Reclamo', 'Cambio dirección', 'Paquete dañado', 'Otro']),
            'desc_novedad': fake.sentence(),
            'id_agente_registro': np.random.randint(1, volumes['OPE_CONDUCTORES']+1),
            'requiere_accion': np.random.choice([True, False], p=[0.3,0.7])
        })
    df = pd.DataFrame(data)
    df = add_anomalies(df, 'DIR_NOVEDADES')
    return df

# ========== 5. Guardar en formatos ==========
def save_dataframe(df, name, formats):
    for fmt in formats:
        os.makedirs(f'output/{fmt}', exist_ok=True)
        if fmt == 'csv':
            df.to_csv(f'output/csv/{name}.csv', index=False)
        elif fmt == 'parquet':
            df.to_parquet(f'output/parquet/{name}.parquet', index=False)

# ========== 6. Ejecutar generación ==========
def main():
    print("Generando dimensiones...")
    df_conductores = generate_conductores(volumes['OPE_CONDUCTORES'])
    df_remitentes = generate_remitentes(volumes['CLI_REMITENTES'])
    df_zonas = generate_zonas(volumes['GEO_ZONAS'])
    
    save_dataframe(df_conductores, 'OPE_CONDUCTORES', output_formats)
    save_dataframe(df_remitentes, 'CLI_REMITENTES', output_formats)
    save_dataframe(df_zonas, 'GEO_ZONAS', output_formats)
    
    print("Generando TMS_ENVIOS (puede tomar varios minutos)...")
    df_envios = generate_envios(volumes['TMS_ENVIOS'], df_conductores, df_remitentes, df_zonas)
    save_dataframe(df_envios, 'TMS_ENVIOS', output_formats)
    
    print("Generando GPS_RUTAS...")
    df_gps = generate_gps_rutas(volumes['GPS_RUTAS'], df_conductores)
    save_dataframe(df_gps, 'GPS_RUTAS', output_formats)
    
    print("Generando CAL_DESTINATARIOS...")
    df_cal = generate_cal_destinatarios(volumes['CAL_DESTINATARIOS'], df_conductores)
    save_dataframe(df_cal, 'CAL_DESTINATARIOS', output_formats)
    
    print("Generando DIR_NOVEDADES...")
    df_novedades = generate_dir_novedades(volumes['DIR_NOVEDADES'], df_envios)
    save_dataframe(df_novedades, 'DIR_NOVEDADES', output_formats)
    
    print("Generación completada. Archivos en output/")

if __name__ == "__main__":
    main()