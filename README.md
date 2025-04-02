# OpenFaas Minio Notify Function

**minio-notify** is an [OpenFaaS](https://www.openfaas.com/) function that
receives [MinIO](https://min.io/) Bucket Notifications via Webhook, extracts
relevant object metadata, and sends a formatted email notification.

Authentication is secured via a Bearer token. SMTP email settings and the
Bearer token are managed via an OpenFaaS secret.

## Usage

* Deploy minio-notify to your OpenFaaS instance.
* Create a secret minio-notify with SMTP settings and authentication token.
* Configure MinIO to send bucket events (e.g., s3:ObjectCreated:*) to
  minio-notify via Webhook.

## Example Email

```text
To: supervisor@example.com
From: faas@example.com
Subject: Object 'test-bucket/image.jpg' successfully created
Date: Sun, 27 Apr 2025 07:08:02 +0000

* Event Type: s3:ObjectCreated:Put
* Timestamp: 2025-02-06T01:04:31.998Z
* Bucket Name: test-bucket
* File Name: image.jpg
* File Size: 84452 bytes
* Content Type: image/jpeg
* Endpoint: https://minio.test.svc.cluster.local
* Object URL: https://minio.test.svc.cluster.local/test-bucket/image.jpg
```

## Configuration

Create a secret file  named `minio-notify` with the following JSON content:

```json
{
  "host": "mail.example.com",
  "ssl": 1,
  "port": 587,
  "username": "john.doe@example.com",
  "password": "qwe123$!",
  "from": "faas@example.com",
  "to": "supervisor@example.com",
  "auth_token": "6496d3ca5e0440f8d91c6738c059f14ed77804d6e37bd5f3be5d2fc5ef564af8"
}
```
| Field        | Description                                     |
|--------------|-------------------------------------------------|
| `host`       | SMTP server hostname                            |
| `ssl`        | Use SSL/TLS (1 = yes, 0 = no)                   |
| `port`       | SMTP server port (typically 587 for TLS)        |
| `username`   | SMTP authentication username                    |
| `password`   | SMTP authentication password                    |
| `from`       | Sender email address                            |
| `to`         | Recipient email address                         |
| `auth_token` | Bearer token used to authorize incoming webhook |

## Deployment

Create the secret:

```bash
faas-cli secret create minio-notify --from-file=minio-notify.json
```

Then deploy the function:

```bash
faas-cli deploy \
    --image ghcr.io/tschaefer/minio-notify:0.0.1 \
    --name minio-notify \
    --secret minio-notify
```

## MinIO Setup

Follow the official [MinIO documentation](https://min.io/docs/minio/linux/administration/monitoring/publish-events-to-webhook.html).
