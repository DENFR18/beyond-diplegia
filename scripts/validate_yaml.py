#!/usr/bin/env python3
"""
validate_yaml.py
Parcourt les fichiers YAML des dossiers ansible/ et .github/workflows/
et vérifie que la syntaxe est correcte.
Exit code 1 si une erreur est détectée — bloque le pipeline CI/CD.
"""

import sys
import os
import yaml

BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
SCAN_DIRS = ["ansible", ".github/workflows"]
EXTENSIONS = (".yaml", ".yml")

errors = []
checked = 0

for scan_dir in SCAN_DIRS:
    target = os.path.join(BASE_DIR, scan_dir)
    if not os.path.exists(target):
        continue

    for dirpath, _, filenames in os.walk(target):
        for filename in filenames:
            if not filename.endswith(EXTENSIONS):
                continue

            filepath = os.path.join(dirpath, filename)
            checked += 1

            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    list(yaml.safe_load_all(f))
                print(f"  OK  {filepath}")
            except yaml.YAMLError as e:
                errors.append((filepath, str(e)))
                print(f"  FAIL  {filepath}\n       {e}")

print(f"\n{checked} fichier(s) verifie(s), {len(errors)} erreur(s) detectee(s).")

if errors:
    print("\nFichiers invalides :")
    for path, msg in errors:
        print(f"  - {path}")
    sys.exit(1)

print("Tous les fichiers YAML sont valides.")
sys.exit(0)
