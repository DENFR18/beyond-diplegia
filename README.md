# Beyond Diplegia

Site de sensibilisation au handicap — diplégie spastique, paralysie cérébrale, dyslexie et dyspraxie — déployé automatiquement sur AWS via une stack DevSecOps complète.

---

## Stack technique

| Outil | Rôle |
|---|---|
| **Terraform** | Provisioning de l'infrastructure AWS (VPC, EC2, Elastic IP) |
| **Ansible** | Configuration du serveur et déploiement du site (nginx, Jinja2) |
| **Docker / GHCR** | Build de l'image nginx du site, scan et publication sur GitHub Container Registry |
| **GitHub Actions** | Pipeline CI/CD : validate → security-scan → docker-build + terraform → ansible |
| **Checkov** | Analyse IaC des manifests Terraform |
| **Trivy** | Scan de vulnérabilités (filesystem, secrets, image Docker) |
| **SonarQube Cloud** | Qualité et sécurité du code |
| **Python** | Validation syntaxique des fichiers YAML avant chaque déploiement |
| **AWS EC2** | Hébergement du site (Ubuntu 22.04, Paris) |
| **S3** | Stockage du Terraform state (versioning + chiffrement) |

---

## Architecture

```
GitHub push (main)
        │
        ▼
 [GitHub Actions]
        │
        ├── Job 0 : Validate YAML (Python)
        │     └── Validation syntaxique ansible/ et .github/workflows/
        │
        ├── Job 1 : Security Scan
        │     ├── Checkov — IaC Terraform
        │     ├── Trivy — filesystem + secrets
        │     └── SonarQube Cloud — qualité & sécurité code
        │         → SARIF uploadé dans l'onglet Security du repo
        │
        ├── Job 2 : Docker Build & Scan
        │     ├── Build image nginx locale
        │     ├── Trivy — scan image (CRITICAL)
        │     └── Push sur GHCR (tags SHA + latest)
        │
        ├── Job 3 : Terraform (parallèle au Docker)
        │     ├── terraform init / validate / plan / apply
        │     └── VPC + Subnet + IGW + Security Group + EC2 + Elastic IP
        │
        └── Job 4 : Ansible
              ├── Inventaire dynamique (IP issue de Terraform output)
              ├── Installation et configuration nginx + fail2ban
              ├── Template Jinja2
              └── Déploiement du site HTML/CSS
```

---

## Structure du projet

```
beyond-diplegia/
├── .github/
│   └── workflows/
│       ├── deploy.yml             # Pipeline CI/CD complet
│       └── destroy.yml            # Destruction de l'infra
├── .checkov.yaml                  # Config Checkov (skip-check documentés)
├── sonar-project.properties       # Config SonarQube Cloud
├── Dockerfile                     # Image nginx:alpine servant le site statique
├── terraform/
│   ├── providers.tf               # Provider AWS + backend S3
│   ├── variables.tf               # Variables (région, instance type, clé SSH)
│   ├── main.tf                    # VPC, subnet, IGW, SG, EC2, Elastic IP
│   └── outputs.tf                 # IP publique de l'EC2
├── ansible/
│   ├── playbook.yml               # Point d'entrée Ansible
│   ├── inventory/
│   │   └── hosts.ini              # Inventaire dynamique généré par le pipeline
│   └── roles/
│       └── webserver/
│           ├── tasks/main.yml     # Installation nginx + fail2ban
│           ├── handlers/main.yml  # Reload nginx / restart fail2ban
│           └── templates/
│               └── nginx.conf.j2  # Config nginx (Jinja2)
├── scripts/
│   └── validate_yaml.py           # Validation YAML (ansible + workflows)
└── site/
    └── index.html                 # Page web (HTML/CSS)
```

---

## Secrets GitHub requis

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | Clé d'accès IAM AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret IAM AWS |
| `EC2_SSH_PUBLIC_KEY` | Clé publique SSH |
| `EC2_SSH_PRIVATE_KEY` | Clé privée SSH encodée en base64 |
| `SONAR_TOKEN` | Token SonarQube Cloud (optionnel — la step est skip si absent) |

---

## Posture DevSecOps

Les scans de sécurité (Checkov, Trivy, SonarQube Cloud) sont **non-bloquants** : leurs findings sont publiés dans l'onglet **Security** du repo via des rapports SARIF, mais ne cassent pas le pipeline. Les règles intentionnellement ignorées (ports publics nécessaires à un site web, SSH admin) sont documentées dans `.checkov.yaml`.

---

## Déploiement

Chaque push sur `main` déclenche automatiquement le pipeline complet.

```
git push origin main
```

Pour détruire l'infrastructure :

```
Actions -> Destroy Infrastructure -> Run workflow (taper "destroy")
```
