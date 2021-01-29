Param(
    [parameter(Mandatory = $false)]
    [string]$subscriptionName = "QBU-IM.SBox.Foglight.APM",
    [parameter(Mandatory = $false)]
    [string]$resourceGroupName = "rg-apm-devops-test",
    [parameter(Mandatory = $false)]
    [string]$resourceGroupLocaltion = "East US",
    [parameter(Mandatory = $false)]
    [string]$clusterName = "test-cluster",
    [parameter(Mandatory = $false)]
    [string]$dnsNamePrefix = "jtang",
    [parameter(Mandatory = $false)]
    [int16]$workerNodeCount = 4, #minimum 4 nodes required for SQL 2019 HA setup
    [parameter(Mandatory = $false)]
    [string]$kubernetesVersion = "1.13.5"

)

# Set Azure subscription name
Write-Host "Setting Azure subscription to $subscriptionName"  -ForegroundColor Yellow
az account set --subscription=$subscriptionName

# Create resource group name
Write-Host "Creating resource group $resourceGroupName in region $resourceGroupLocaltion" -ForegroundColor Yellow
az group create `
    --name=$resourceGroupName `
    --location=$resourceGroupLocaltion `
    --output=jsonc

# Create AKS cluster
Write-Host "Creating AKS cluster $clusterName with resource group $resourceGroupName in region $resourceGroupLocaltion" -ForegroundColor Yellow
az aks create `
    --resource-group=$resourceGroupName `
    --name=$clusterName `
    --node-count=$workerNodeCount `
    --dns-name-prefix=$dnsNamePrefix `
    --generate-ssh-keys `
    --node-vm-size=Standard_D2_v2 `
    --enable-addons http_application_routing
#    --kubernetes-version=$kubernetesVersion `

# Get credentials for newly created cluster
Write-Host "Getting credentials for cluster $clusterName" -ForegroundColor Yellow
az aks get-credentials `
    --resource-group=$resourceGroupName `
    --name=$clusterName

Write-Host "Successfully created cluster $clusterName with kubernetes version $kubernetesVersion and $workerNodeCount node(s)" -ForegroundColor Green

Write-Host "Creating cluster role binding for Kubernetes dashboard" -ForegroundColor Green
kubectl create clusterrolebinding kubernetes-dashboard -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard

Write-Host "Creating Tiller service account for Helm" -ForegroundColor Green

$currentWorkingDirectory = (Get-Location).Path | Split-Path -Parent

Set-Location "${currentWorkingDirectory}/helm/"
kubectl apply -f .\helm-rbac.yaml

Write-Host "Initializing Helm with Tiller service account" -ForegroundColor Green
helm init --service-account tiller

Set-Location "$currentWorkingDirectory/Powershell"