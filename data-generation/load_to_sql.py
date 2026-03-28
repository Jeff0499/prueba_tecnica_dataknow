import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv(override=True)

server = os.getenv('DB_SERVER')
database = os.getenv('DB_NAME')
username = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')

print("Server:", server)
print("Database:", database)

engine = create_engine(f"mssql+pymssql://{username}:{password}@{server}/{database}")

tables = [
    'OPE_CONDUCTORES',
    'CLI_REMITENTES',
    'GEO_ZONAS',
    'TMS_ENVIOS',
    'GPS_RUTAS',
    'CAL_DESTINATARIOS',
    'DIR_NOVEDADES'
]

for table in tables:
    try:
        df = pd.read_csv(f'output/csv/{table}.csv')
        print(f"Cargando {table} con {len(df)} registros...")
        df.to_sql(table, engine, if_exists='replace', index=False, chunksize=10000)
        print(f"✅ {table} cargada correctamente")
    except Exception as e:
        print(f"❌ Error en {table}: {e}")