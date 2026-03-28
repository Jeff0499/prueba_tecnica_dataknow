# Prueba Técnica Ingeniero de Datos – Escenario D (Logística)

## 1. Selección del escenario y plataforma

**Escenario elegido:** D – Logística y Cadena de Suministro  
**Plataforma cloud:** Microsoft Azure  
**Justificación:**  
Azure ofrece servicios gestionados como Azure SQL Database, Data Lake Storage Gen2, Data Factory y Databricks, que se alinean con los requisitos de la prueba. La elección permite construir una solución escalable, segura y con gobierno de datos integrado.

---

## 2. Fase 1 – Generación de datos sintéticos

### 2.1 Herramientas utilizadas
- **Python 3.12** con las librerías:
  - `pandas`, `numpy` → manipulación y generación de datos.
  - `Faker` → generación de datos realistas (nombres, direcciones, etc.).
  - `hashlib` → enmascaramiento de datos sensibles (documentos).
  - `pyyaml` → gestión de configuración.
- **Formato de salida:** CSV y Parquet (para simular ingesta heterogénea).

### 2.2 Configuración de generación
Los parámetros de volumen, fechas y tasas de anomalías se definieron en `config.yaml`:
```
yaml
seed: 42
date_range:
  start: "2024-01-01"
  end: "2024-12-31"
output_formats: ["csv", "parquet"]
volumes:
  OPE_CONDUCTORES: 500
  CLI_REMITENTES: 200
  GEO_ZONAS: 300
  TMS_ENVIOS: 2000000
  GPS_RUTAS: 100000
  CAL_DESTINATARIOS: 300000
  DIR_NOVEDADES: 150000
anomalies:
  duplicate_rate: 0.001
  null_rate: 0.05
  out_of_range_rate: 0.001
  referential_integrity_violation_rate: 0.005

---
```

## 3. Fase 2 – Infraestructura como Código (Terraform)

Se utilizó Terraform para aprovisionar los siguientes recursos en Azure:
- **Resource Group**: `rg-prueba-tecnica`
- **Storage Account (ADLS Gen2)**: con contenedores `bronze`, `silver`, `gold`
- **Azure Data Factory**: orquestación del pipeline
- **Azure Databricks Workspace**: transformaciones Silver y Gold
- **Azure Key Vault**: almacenamiento de secretos
- **Log Analytics Workspace**: monitoreo
- **Action Group**: alertas por correo

### Justificación de elecciones
- **Terraform** permite la gestión declarativa y versionada de la infraestructura.
- **Backend remoto** en Azure Storage garantiza que el estado no se almacene localmente ni se suba al repositorio.
- Los parámetros están parametrizados para soportar múltiples entornos (dev/prod).

### Instrucciones para desplegar
1. Instalar Terraform y Azure CLI.
2. Autenticarse con `az login`.
3. Crear manualmente la cuenta de almacenamiento para el estado (ver sección).
4. Copiar `terraform.tfvars.example` a `terraform.tfvars` y ajustar valores.
5. Ejecutar `terraform init`, `terraform plan`, `terraform apply`.

### Evidencias
![Terraform apply output](docs/terraform-apply.png)
![Recursos en Azure Portal](docs/azure-resources.png)
