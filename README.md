# connersmith.net

Source for [connersmith.net](https://connersmith.net) — a personal portfolio site, plus the AWS infrastructure that runs it. Static HTML in `src/`, deployed to S3 + CloudFront via Terraform, with a Lambda-backed visitor counter.

## Stack

- **Static site** — single-page HTML/CSS in `src/index.html`, no build step
- **Hosting** — S3 (origin) + CloudFront (CDN, HTTPS, cache)
- **DNS / TLS** — Route 53 + ACM (wildcard cert covers subdomains)
- **Visitor counter** — API Gateway → Lambda (Node.js, `terraform/backend/visitor_count.mjs`) → DynamoDB
- **Subdomains** — `resume.connersmith.net` 302-redirects to a Google Doc via a CloudFront Function (see `terraform/resume_subdomain.tf`)
- **CI/CD** — GitHub Actions (`.github/workflows/deploy.yml`) runs `terraform apply`, syncs `src/` to S3 (root + www buckets), invalidates CloudFront

## Layout

```
src/                       static site (index.html, 404.html, sitemap, robots, favicon)
terraform/                 AWS infrastructure as code
  backend/visitor_count.mjs  Lambda handler for visitor counter
  *.tf                     resources: cloudfront, s3, lambda, dynamodb, route53, acm, api gateway
.github/workflows/         CI/CD pipeline
```

## Deployment

Pushes to `main` trigger the workflow. It:

1. Injects build date into `index.html`
2. Zips & hashes the Lambda, uploads to artifact bucket
3. Runs `terraform init / plan / apply` (state stored in S3)
4. Syncs `src/` to both root and www S3 buckets
5. Invalidates the CloudFront cache

### Required GitHub secrets

| Name | Purpose |
|---|---|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | IAM creds for the deploy role |
| `AWS_S3_BUCKET` | Root S3 bucket (`connersmith.net`) |
| `AWS_S3_BUCKET_2` | WWW S3 bucket (`www.connersmith.net`) |
| `CLOUDFRONT_DISTRIBUTION_ID` | Main distribution ID for cache invalidation |

### One-time bootstrap

The Terraform backend lives in an S3 bucket (`connersmith.net-statefile`). That bucket has to exist before `terraform init` can use it — bootstrap it manually once.

## Local development

```bash
# preview the site
cd src && python3 -m http.server 8000

# plan terraform changes
cd terraform && terraform init && terraform plan
```

## Acknowledgments

Portions of the site and infrastructure were iterated on with [Claude](https://claude.com/claude-code).
