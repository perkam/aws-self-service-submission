# Infrastruktura

Kod infrastruktury dla `status-api` w AWS. Moduły są napisane w Terraformie, a Terragrunt łączy je w konfigurację środowisk. Opis decyzji i całego rozwiązania znajduje się w [głównym README](../README.md).

## Struktura

```text
infra/
├── modules/                 Moduły Terraform
└── live/
    ├── root.hcl             Wspólna konfiguracja backendu i providera
    ├── dev/
    │   ├── account.hcl      Konto AWS i bucket na stan
    │   └── eu-north-1/      Unity środowiska dev
    └── prod/
        ├── account.hcl
        └── eu-north-1/      Unity środowiska prod (bez deploymentu)
```

| Moduł | Co tworzy |
| --- | --- |
| `tfstate-bucket` | Bucket S3 na stan Terraform |
| `vpc` | VPC, podsieci, internet gateway, NAT gateway i route tables |
| `alb` | Application Load Balancer, listener HTTP, alarm 5xx i SNS topic |
| `ecs-cluster` | Klaster ECS z capacity providerami Fargate |
| `github-oidc` | OIDC provider GitHuba |
| `ecr` | Repozytorium obrazów, lifecycle policy i rola do publikacji obrazów |
| `ecs-alb-service` | ECS service, task definition, log group, execution role, rola do deploymentu, security group, target group i listener rule |

## Narzędzia

Wersje narzędzi są przypięte w [`.tool-versions`](.tool-versions): Terraform 1.17.2 i Terragrunt 1.2.2.

## Weryfikacja bez konta AWS

Polecenia uruchamiaj z głównego katalogu repozytorium.

```sh
terraform fmt -check -recursive infra

for module in infra/modules/*/; do
  terraform -chdir="$module" init -backend=false -input=false
  terraform -chdir="$module" validate
done

(cd infra && terragrunt hcl fmt --check)
(cd infra/live && terragrunt hcl validate --inputs --strict)
```

Pipeline uruchamia te checki, a także TFLint i Checkov, przy każdym pull requeście.

## Tworzenie środowiska

Terragrunt ustala kolejność unitów na podstawie bloków `dependency`. Nowe środowisko wymaga jednak trzech etapów, ponieważ bucket na stan i pierwszy obraz muszą istnieć wcześniej.

**1. Utwórz bucket na stan** w katalogu `infra/live/<env>/eu-north-1/tfstate-bucket`: odkomentuj lokalny blok `remote_state`, uruchom `terragrunt apply`, zakomentuj blok ponownie i uruchom `terragrunt init -migrate-state`.

**2. Utwórz pozostałe zasoby oprócz serwisu:**

```sh
cd infra/live/<env>/eu-north-1
terragrunt run --all \
  --filter '!./tfstate-bucket' \
  --filter '!./services/status-api' \
  -- apply
```

**3. Opublikuj pierwszy obraz i utwórz serwis:** uruchom workflow `app`, ustaw `initial_image_tag` w `services/status-api/terragrunt.hcl` na SHA commita opublikowanego obrazu, a następnie wykonaj:

```sh
terragrunt run --all -- apply
```

W istniejącym środowisku wystarczą `terragrunt run --all -- plan` oraz `terragrunt run --all -- apply`. Polecenie `apply` z opcją `--all` nie prosi o potwierdzenie każdego unitu, dlatego najpierw warto sprawdzić wynik `plan`.

## Pominięte checki Checkova

Checkov pomija 16 checków, a każde pominięcie ma uzasadnienie w kodzie:

| Powód | Checki |
| --- | --- |
| HTTPS odłożone do czasu udostępnienia domeny | `CKV_AWS_2`, `CKV_AWS_103`, `CKV2_AWS_20` |
| Ruch z ALB do tasków pozostaje wewnątrz VPC | `CKV_AWS_378` |
| Domyślne szyfrowanie zamiast customer-managed KMS key | `CKV_AWS_26`, `CKV_AWS_136`, `CKV_AWS_145`, `CKV_AWS_158` |
| Access logi i flow logi odłożone do hardeningu prod | `CKV_AWS_18`, `CKV_AWS_91`, `CKV2_AWS_11` |
| WAF odłożony do hardeningu prod | `CKV2_AWS_28` |
| ALB jest celowo publiczny | `CKV_AWS_260` |
| Deletion protection ustawiane per środowisko | `CKV_AWS_150` |
| Niepotrzebne dla bucketu ze stanem | `CKV_AWS_144`, `CKV2_AWS_62` |
