# func-app-infra

## Project structure

The repository separates infrastructure and application code into sibling
directories. This keeps the Terraform provider cache (`.terraform/`, ~242 MB)
out of the function app deployment package.

```text
func-app-infra/
├── app/                 ← Azure Functions Python app
│   ├── function_app.py
│   ├── host.json
│   ├── requirements.txt
│   ├── pyproject.toml
│   └── .funcignore
└── infra/               ← Terraform configuration
    ├── main.tf
    ├── func_app.tf
    ├── event_hub.tf
    └── scripts/setup.sh
```

Deploy the function app from the `app/` directory so only application code is
uploaded. Run Terraform commands from the `infra/` directory.

## Infrastructure

All Terraform configuration lives in the `infra/` directory and targets the
**AzureRM provider v4.x**. Every resource uses a configurable `resource_prefix`
variable so names stay consistent and collision-free. The infrastructure deploys
to the **West US 2** region.

### Provider and core configuration (`main.tf`)

- Pins `hashicorp/azurerm` to `~> 4.0`.
- Enables `storage_use_azuread = true` at the provider level so all storage
  data-plane operations authenticate through Azure AD instead of access keys.
- Sets `prevent_deletion_if_contains_resources = false` on resource groups,
  allowing Terraform to destroy groups that contain auto-created resources not
  managed by Terraform (e.g., Smart Detector alert rules).
- Declares two variables: `resource_prefix` (naming prefix for every resource)
  and `azure_subscription_id`.
- Creates a single resource group (`<prefix>_infrafly_rg`) that holds all other
  resources.

### Function App and supporting resources (`func_app.tf`)

- **Storage Account** — Backing store for the function app's internal state
  (triggers, logs). Key-based authentication is disabled
  (`shared_access_key_enabled = false`); access is Azure AD only.
- **App Service Plan** — Linux plan on the **S1** SKU that hosts the function
  app.
- **Application Insights** — Provides monitoring, diagnostics, and distributed
  tracing for the function app.
- **Linux Function App** — Runs **Python 3.12** with the v2 programming model.
  Uses a **system-assigned managed identity**
  (`storage_uses_managed_identity = true`) to connect to its storage account
  without any secrets. Application Insights is wired in through both
  `app_settings` and `site_config`.
- **Role Assignment — Storage Blob Data Owner** — Grants the function app's
  managed identity full read/write/delete access to blob data in the storage
  account.

### Event Hub (`event_hub.tf`)

- **Event Hub Namespace** — Standard-SKU namespace that supports up to 20
  consumer groups and 1,000 brokered connections.
- **Event Hub** — Created inside the namespace with **8 partitions** (controls
  consumer parallelism, immutable after creation) and **1-day message
  retention**.
- **Role Assignment — Azure Event Hubs Data Receiver** — Grants the function
  app's managed identity permission to receive events from the namespace, again
  avoiding connection strings or shared access policies.

### Security posture

The infrastructure follows a **zero-secret, managed-identity-first** approach:

- No storage account keys are generated or used.
- No Event Hub connection strings are stored in app settings.
- All cross-resource authentication flows through **Azure RBAC role
  assignments** scoped to the minimum required resource.

## Function App

The function app is implemented in `app/function_app.py` with a single
HTTP-triggered route (`/health`) that returns "OK". The app uses the v2
programming model and is configured to run on Python 3.12. The `host.json` file
specifies the extension bundle version for runtime extensions.

### Deployment of function app

The function app code is not automatically deployed by Terraform. To deploy the
app, you can use the Azure Functions Core Tools or set up a CI/CD pipeline that
pushes the code to the function app after infrastructure deployment. The app
will be able to authenticate to Azure resources using its system-assigned
managed identity, which is granted the necessary permissions through role
assignments in Terraform.

You can deploy the function app code using the Azure Functions Core Tools from
the `app/` directory:

```bash
cd app
func azure functionapp publish <function_app_name>
```

Make sure to replace `<function_app_name>` with the actual name of your function
app, which is defined in your Terraform configuration as
`${var.resource_prefix}-funcapp`.
