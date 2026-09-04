# Daily ECB Exchange Rates

Automatización diaria que descarga tipos de cambio del Banco Central Europeo y guarda el resultado como JSON en Amazon S3.

## Arquitectura

1. EventBridge Scheduler invoca AWS Lambda diariamente.
2. Lambda consulta la API del Banco Central Europeo.
3. Python procesa los tipos de cambio de GBP, JPY y USD frente al EUR.
4. Lambda guarda un archivo JSON en Amazon S3.
5. Terraform administra la infraestructura.
6. GitHub Actions prueba y despliega los cambios de `main`.

## Tecnologías

- Python 3.13
- Pytest
- AWS Lambda
- Amazon S3
- Amazon EventBridge Scheduler
- Terraform
- GitHub Actions
- AWS OIDC

## Estructura

```text
.
├── .github/workflows/deploy.yml
├── bootstrap/
├── src/
│   └── lambda_function.py
├── terraform/
└── tests/
    └── test_lambda_function.py