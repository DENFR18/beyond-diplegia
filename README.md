# Beyond Diplegia

Site de sensibilisation au handicap — diplégie spastique, paralysie cérébrale, dyslexie et dyspraxie — déployé automatiquement sur AWS via une stack DevOps complète.

---

## Stack technique

| Outil | Role |
|---|---|
| **Terraform** | Provisioning de l'infrastructure AWS (VPC, EC2, Elastic IP) |
| **Ansible** | Configuration du serveur et déploiement du site (nginx, Jinja2) |
| **GitHub Actions** | Pipeline CI/CD : validate → plan → apply → configure → deploy |
| **Python** | Validation syntaxique des fichiers YAML avant chaque déploiement |
| **AWS EC2** | Hébergement du site (Ubuntu 22.04, t3.micro, Paris) |
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
        ├── Job 1 : Terraform
        │     ├── terraform init / validate / plan / apply
        │     └── VPC + Subnet + IGW + Security Group + EC2 + Elastic IP
        │
        └── Job 2 : Ansible
              ├── Inventaire dynamique (IP issue de Terraform output)
              ├── Installation et configuration nginx
              ├── Template Jinja2
              └── Déploiement du site HTML/CSS
```

---

## Structure du projet

```
beyond-diplegia/
├── .github/
│   └── workflows/
│       ├── deploy.yml          # Pipeline CI/CD complet
│       └── destroy.yml         # Destruction de l'infra
├── terraform/
│   ├── providers.tf            # Provider AWS + backend S3
│   ├── variables.tf            # Variables (région, instance type, clé SSH)
│   ├── main.tf                 # VPC, subnet, IGW, SG, EC2, Elastic IP
│   └── outputs.tf              # IP publique de l'EC2
├── ansible/
│   ├── playbook.yml            # Point d'entrée Ansible
│   ├── inventory/
│   │   └── hosts.ini           # Inventaire dynamique généré par le pipeline
│   └── roles/
│       └── webserver/
│           ├── tasks/main.yml      # Installation et configuration nginx
│           ├── handlers/main.yml   # Reload nginx
│           └── templates/
│               └── nginx.conf.j2  # Config nginx (Jinja2)
├── scripts/
│   └── validate_yaml.py        # Validation YAML (ansible + workflows)
└── site/
    └── index.html              # Page web (HTML/CSS)
```

---

## Secrets GitHub requis

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | Clé d'accès IAM AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret IAM AWS |
| `EC2_SSH_PUBLIC_KEY` | Clé publique SSH |
| `EC2_SSH_PRIVATE_KEY` | Clé privée SSH encodée en base64 |

---

## Déploiement

Chaque push sur `main` déclenche automatiquement le pipeline complet.

```
git push origin main
```

Pour détruire l'infrastructure :

```
Actions -> Destroy -> Run workflow
```
