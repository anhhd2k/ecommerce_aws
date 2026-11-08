# eCommerce

A cloud-native eCommerce application with a React single-page frontend, an
application/backend tier, and AWS infrastructure provisioned with Terraform.

## Architecture

```
                 viewer (HTTPS)
                      |
                 CloudFront  ──(OAC, signed)──►  private S3 bucket (React build)
                      |
          Cognito (sign-up / sign-in, OAuth2 Hosted UI)
                      |
                 Internal ALB
                      |
        ┌─────────────┴─────────────┐
        │   VPC (10.10.0.0/16)       │
        │                            │
        │  public   → ALB + NAT GW   │
        │  app      → application    │
        │  db       → PostgreSQL/RDS │
        └────────────────────────────┘
```

- **Frontend** – React SPA built with Create React App, deployed to a private
  S3 bucket and served through CloudFront using Origin Access Control (OAC).
  SPA routing is handled by rewriting 403/404 responses to `/index.html`.
- **Authentication** – Amazon Cognito user pool with email sign-in and a
  hosted UI / OAuth2 domain.
- **Networking** – A VPC spanning two Availability Zones with three subnet
  tiers: public (ALB + NAT), private application, and isolated database.
- **State** – Terraform state stored remotely in an S3 backend (see
  `Infrastructure/backend.tf`).

## Repository Structure

```
eCommerce/
├── frontend/
│   ├── react-app/            # React SPA (see its own README)
│   └── FRONTEND_COMPLETE.md
├── Infrastructure/           # Terraform (VPC, Cognito, S3, CloudFront)
│   ├── provider.tf
│   ├── network.tf            # VPC, subnets, NAT, routing
│   ├── authentication.tf     # Cognito user pool + client + domain
│   ├── frontend.tf           # S3 bucket + CloudFront + OAC
│   ├── variables.tf
│   ├── output.tf
│   ├── locals.tf
│   ├── backend.tf            # remote S3 state backend
│   └── terraform.tfvars      # local variables (git-ignored)
├── ecommerce-web-app/
│   └── install-prerequisites.sh   # installs Docker, Node.js, etc.
└── README.md
```

## Prerequisites

- Node.js 18+ (20 LTS recommended)
- Terraform 1.5.0+
- AWS CLI configured with credentials for the target account
- Docker (optional, for containerized frontend)

On Linux/macOS you can install the toolchain with:

```bash
cd ecommerce-web-app
./install-prerequisites.sh
```

## Getting Started

### 1. Provision infrastructure

```bash
cd Infrastructure
terraform init
terraform plan
terraform apply
```

Key variables live in `terraform.tfvars` (git-ignored). After `apply`, note the
outputs — especially `cloudfront_domain_name`, `frontend_bucket_name`,
`cognito_user_pool_id`, and `cognito_client_id`.

### 2. Build and deploy the frontend

```bash
cd frontend/react-app
npm install
npm run build
aws s3 sync build/ s3://<frontend_bucket_name> --delete
```

The app is then reachable at the CloudFront domain from the Terraform outputs.

For local development of the frontend, see
[`frontend/react-app/README.md`](frontend/react-app/README.md).

## Terraform Outputs

| Output | Description |
| --- | --- |
| `cloudfront_domain_name` | Public URL of the frontend |
| `frontend_bucket_name` | S3 bucket holding the React build |
| `cloudfront_distribution_id` | CloudFront distribution ID (for cache invalidation) |
| `cognito_user_pool_id` | Cognito user pool ID |
| `cognito_client_id` | Cognito web client ID |
| `cognito_hosted_ui_url` | Base URL for the Cognito hosted UI / OAuth2 endpoints |
| `vpc_id` | VPC ID |
| `public_subnet_ids` / `app_subnet_ids` / `db_subnet_ids` | Subnet IDs per tier |
| `db_subnet_group_name` | DB subnet group for RDS placement |

## Security Notes

- `*.tfvars`, `*.tfstate`, and the `.terraform/` directory are git-ignored to
  avoid committing secrets and raw infrastructure data.
- The S3 frontend bucket blocks all public access; only the CloudFront
  distribution (matched by ARN) can read objects.
- Do not store real credentials in tracked files.
