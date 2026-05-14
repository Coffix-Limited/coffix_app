#!/usr/bin/env bash
# Migrates specific Firestore collections from dev to prod using gcloud.
#
# Prerequisites:
#   - gcloud CLI installed and authenticated (gcloud auth login)
#   - Sufficient IAM permissions on both projects
#   - A GCS bucket accessible by both projects for the export/import handoff
#
# Usage:
#   ./scripts/migrate_dev_to_prod.sh
#
# Optional env overrides:
#   EXPORT_BUCKET  — GCS bucket used as transfer staging (default: coffix-db-migration-staging)
#   SKIP_CONFIRM   — set to "1" to bypass the confirmation prompt

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────────────
DEV_PROJECT="coffix-app-dev"
DEV_DATABASE="(default)"

PROD_PROJECT="coffix-app-prod"
PROD_DATABASE="coffix-prod-australia"

EXPORT_BUCKET="${EXPORT_BUCKET:-coffix-db-migration-staging}"
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
EXPORT_PATH="gs://${EXPORT_BUCKET}/migrate/${TIMESTAMP}"

COLLECTIONS=(
  emails
  global
  modifierGroups
  modifiers
  orders
  productCategories
  products
  stores
)

# ── Helpers ──────────────────────────────────────────────────────────────────
red()   { echo -e "\033[0;31m$*\033[0m"; }
green() { echo -e "\033[0;32m$*\033[0m"; }
blue()  { echo -e "\033[0;34m$*\033[0m"; }

check_deps() {
  if ! command -v gcloud &>/dev/null; then
    red "Error: gcloud CLI not found. Install it from https://cloud.google.com/sdk/docs/install"
    exit 1
  fi
}

# ── Preflight ─────────────────────────────────────────────────────────────────
check_deps

blue "╔══════════════════════════════════════════════════════════╗"
blue "║         Firestore Dev → Prod Migration                   ║"
blue "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  Source : ${DEV_PROJECT} / ${DEV_DATABASE}"
echo "  Dest   : ${PROD_PROJECT} / ${PROD_DATABASE}"
echo "  Staging: ${EXPORT_PATH}"
echo "  Collections:"
for col in "${COLLECTIONS[@]}"; do
  echo "    • ${col}"
done
echo ""

if [[ "${SKIP_CONFIRM:-0}" != "1" ]]; then
  read -r -p "Proceed? This will OVERWRITE matching documents in prod. [y/N] " confirm
  if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# Build the --collection-ids flag (comma-separated list for gcloud)
COLLECTION_IDS=$(IFS=,; echo "${COLLECTIONS[*]}")

# ── Ensure staging bucket exists ──────────────────────────────────────────────
if ! gcloud storage buckets describe "gs://${EXPORT_BUCKET}" --project="${PROD_PROJECT}" &>/dev/null; then
  blue "Staging bucket not found. Creating gs://${EXPORT_BUCKET}..."
  gcloud storage buckets create "gs://${EXPORT_BUCKET}" \
    --project="${PROD_PROJECT}" \
    --location=australia-southeast1
  green "Bucket created."
else
  echo "Staging bucket gs://${EXPORT_BUCKET} already exists."
fi

# ── Grant Firestore service accounts Storage access ───────────────────────────
blue "Granting Storage access to Firestore service accounts..."

DEV_PROJECT_NUMBER=$(gcloud projects describe "${DEV_PROJECT}" --format="value(projectNumber)")
PROD_PROJECT_NUMBER=$(gcloud projects describe "${PROD_PROJECT}" --format="value(projectNumber)")

DEV_SA="service-${DEV_PROJECT_NUMBER}@gcp-sa-firestore.iam.gserviceaccount.com"
PROD_SA="service-${PROD_PROJECT_NUMBER}@gcp-sa-firestore.iam.gserviceaccount.com"

gcloud storage buckets add-iam-policy-binding "gs://${EXPORT_BUCKET}" \
  --member="serviceAccount:${DEV_SA}" \
  --role="roles/storage.admin" \
  --project="${PROD_PROJECT}" &>/dev/null

gcloud storage buckets add-iam-policy-binding "gs://${EXPORT_BUCKET}" \
  --member="serviceAccount:${PROD_SA}" \
  --role="roles/storage.admin" \
  --project="${PROD_PROJECT}" &>/dev/null

green "Permissions granted."

# ── Step 1: Export from dev ───────────────────────────────────────────────────
blue "\n[1/2] Exporting from dev (${DEV_PROJECT})..."
gcloud firestore export "${EXPORT_PATH}" \
  --project="${DEV_PROJECT}" \
  --database="${DEV_DATABASE}" \
  --collection-ids="${COLLECTION_IDS}"

green "Export complete → ${EXPORT_PATH}"

# ── Step 2: Import into prod ──────────────────────────────────────────────────
blue "\n[2/2] Importing into prod (${PROD_PROJECT})..."
gcloud firestore import "${EXPORT_PATH}" \
  --project="${PROD_PROJECT}" \
  --database="${PROD_DATABASE}" \
  --collection-ids="${COLLECTION_IDS}"

green "\nMigration complete."
echo "Verify in Firebase Console: https://console.firebase.google.com/project/${PROD_PROJECT}/firestore"
