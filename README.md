# 💻 Azure VM Deployment with Makefile & Bicep

This project uses a `Makefile` to streamline the provisioning and management of Azure infrastructure using Bicep templates. It includes automatic SSH key generation, resource deployment, configuration, and teardown.

---

## 📁 Project Structure

```
.
├── main.bicep          # Your Bicep file defining the infrastructure
├── configure.sh        # Optional script to run on the VM after deployment
├── Makefile            # Main automation file
└── keys/               # SSH key files will be stored here
```

---

## ⚙️ Configuration

You can override default values by setting environment variables when running `make`:

| Variable           | Description                                  | Default              |
|--------------------|----------------------------------------------|----------------------|
| `KEY_PATH`         | Path to store the SSH key pair               | `./keys/id_rsa`      |
| `KEY_COMMENT`      | Comment added to the SSH key                 | `generated-key`      |
| `KEY_TYPE`         | Type of SSH key                              | `rsa`                |
| `KEY_BITS`         | Number of bits in SSH key                    | `4096`               |
| `RESOURCE_GROUP`   | Name of Azure resource group                 | `rg-beast`           |
| `LOCATION`         | Azure region for deployment                  | `uaenorth`           |
| `BICEP_FILE`       | Path to the Bicep template                   | `./main.bicep`       |
| `DEPLOYMENT_NAME`  | Name of the deployment                       | `beast-deployment`   |
| `USERNAME`         | Admin username for the VM                    | `azureuser`          |
| `VNET_NAME`        | Name of the virtual network                  | `vnet-beast`         |
| `SUBNET_NAME`      | Name of the subnet                           | `subnet-beast`       |
| `VM_NAME`          | Name of the virtual machine                  | `vm-beast`           |

---

## 🚀 Available Make Targets

| Command           | Description                                      |
|------------------|--------------------------------------------------|
| `make help`      | Show available commands                          |
| `make keys`      | Generate an SSH key pair                         |
| `make rg`        | Create the Azure resource group                  |
| `make infra`     | Deploy infrastructure using Bicep (runs `rg` and `keys`) |
| `make connect`   | SSH into the deployed VM                         |
| `make configure` | Run the `configure.sh` script on the VM          |
| `make ssh-config`| Add the VM to your `~/.ssh/config`               |
| `make clean`     | Delete the generated SSH key files               |
| `make destroy`   | Delete the entire resource group                 |

---

## 🔐 SSH Key Generation

Generate an RSA key pair with:

```bash
make keys
```

---

## ☁️ Deploying Infrastructure

Run this to create the resource group and deploy the VM using Bicep:

```bash
make infra
```

---

## 🖥 Connect to VM

After deployment:

```bash
make connect
```

---

## ⚙️ Configure VM (Optional)

If you have a `configure.sh` script, run it remotely:

```bash
make configure
```

---

## 🧠 Add SSH Config Entry

Simplify future SSH access with:

```bash
make ssh-config
```

Then you can connect using:

```bash
ssh vm-beast
```

---

## 🧹 Cleanup

Delete only the SSH keys:

```bash
make clean
```

Destroy all deployed resources:

```bash
make destroy
```

---

## 📌 Requirements

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- `ssh-keygen`, `scp`, and `ssh` installed (available on most Unix systems)
- Logged in via `az login`