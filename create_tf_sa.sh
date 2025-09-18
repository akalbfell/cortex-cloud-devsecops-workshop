#!/bin/bash
# One-liner service account key generator for HCP Terraform
# Run inside GCP Cloud Shell

# Get active project from gcloud config
PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID

SA_NAME="hcp-deployment"

# Enable IAM API if not already
gcloud services enable iam.googleapis.com --project "$PROJECT_ID" >/dev/null 2>&1

# Create service account (idempotent – will skip if exists)
gcloud iam service-accounts create "$SA_NAME" \
  --description="HCP Terraform Deployment Service Account" \
  --display-name="HCP Terraform SA" \
  --project "$PROJECT_ID" >/dev/null 2>&1 || true

# Grant Owner role
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/owner" \
  --condition=None \
  --quiet >/dev/null 2>&1

# Generate a new key and output JSON to stdout (never saved to disk)
KEY_JSON=$(gcloud iam service-accounts keys create /dev/stdout \
  --iam-account="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project "$PROJECT_ID")

# Convert to single-line JSON
ONE_LINE=$(echo "$KEY_JSON" | jq -c .)

echo
echo "✅ Service account key created and converted!"
echo "👉 Copy the line below and paste into HCP Terraform as secret env var GOOGLE_CREDENTIALS:"
echo
echo "$ONE_LINE"
