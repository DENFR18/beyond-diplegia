# Beyond Diplegia 🌐

Site de sensibilisation au handicap — diplégie spastique, paralysie cérébrale, dyslexie et dyspraxie — déployé automatiquement sur AWS via une stack DevOps complète.

🔗 **[Voir le site](http://13.36.160.227)**

---

## Stack technique

| Outil | Rôle |
|---|---|
| **Terraform** | Provisioning de l'infrastructure AWS (VPC, EC2, Elastic IP) |
| **Ansible** | Configuration du serveur et déploiement du site (nginx) |
| **GitHub Actions** | Orchestration CI/CD — plan → apply → configure → deploy |
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
        ├── Job 1 : Terraform
        │     ├── terraform init
        │     ├── terraform validate
        │     ├── terraform plan
        │     └── terraform apply
        │           └── VPC + Subnet + IGW + Security Group + EC2 + Elastic IP
        │
        └── Job 2 : Ansible
              ├── Génération inventaire dynamique (IP issue de Terraform output)
              ├── Installation nginx
              ├── Configuration nginx (template Jinja2)
              └── Déploiement du site HTML/CSS
```

---

## Structure du projet

```
beyond-diplegia/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Pipeline GitHub Actions
├── terraform/
│   ├── providers.tf            # Provider AWS + backend S3
│   ├── variables.tf            # Variables (région, env, instance type, clé SSH)
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
└── site/
    └── index.html              # Page web (HTML/CSS)
```

---

## Prérequis

- Compte AWS avec un utilisateur IAM (droits EC2, VPC, S3)
- Bucket S3 pour le Terraform state (`beyond-diplegia-tfstate`)
- Paire de clés SSH (publique + privée)

## Secrets GitHub à configurer

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | Clé d'accès IAM AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret IAM AWS |
| `EC2_SSH_PUBLIC_KEY` | Clé publique SSH (`ssh-ed25519 AAAA...`) |
| `EC2_SSH_PRIVATE_KEY` | Clé privée SSH encodée en base64 |

---

## Déploiement

Chaque push sur `main` déclenche automatiquement le pipeline complet.

```bash
git push origin main
```

---

## Auteur

**Denilsson** — Étudiant Mastère DevOps, SUP DE VINCI
