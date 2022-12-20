
export nona='k8s-magic-neos'

# Create a resource group
az group create --name ${nona} --location "westus"

## Create a keyvault
az keyvault create --name ${nona} --resource-group ${nona} --location "westus"

# Create a Azure Container Registry
az acr create --resource-group ${nona} --name ${nona//-} --sku Basic --location "westus"




# Create a managed Kubernetes cluster
az aks create -y -g ${nona} -n ${nona}  --enable-managed-identity --load-balancer-sku standard --attach-acr ${nona//-} \
    --enable-cluster-autoscaler --min-count 1 --max-count 3 --node-count 1 \
    --node-vm-size Standard_DS2_v2 --enable-blob-driver --generate-ssh-keys --location "westus"

# add cluster extensions
export list=('http_application_routing'
             'monitoring'
             'azure-policy'
             'ingress-appgw'
             'open-service-mesh'
             'azure-keyvault-secrets-provider'
             'web_application_routing'
             'kube-dashboard'
             'gitops'
             'confcom')

for ext in ${list}; do echo ${ext} && az aks enable-addons --addons ${ext} --name ${nona} --resource-group ${nona} ;done;



# Create a managed Kubernetes cluster with a node pool
# Notice that the price value is -1. This means that you will get the
# 1) The default price will be up-to on-demand.
# 2) The instance won't be evicted based on price.
# 3) The price for the instance will be the current price for Spot or the price for a standard instance, which ever is less, as long as there is capacity and quota available.
az aks nodepool add \
    --resource-group ${nona} \
    --cluster-name ${nona} \
    --name spotnodepool \
    --priority Spot \
    --eviction-policy Delete \
    --spot-max-price -1 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 50 \
    --labels cost=low


# Create a managed Kubernetes cluster with a node pool
# Notice that the this will be ARM based 
az aks nodepool add \
    --resource-group ${nona} \
    --cluster-name ${nona} \
    --enable-cluster-autoscaler \
    --name armpool \
    --min-count 1 \
    --max-count 50 \
    --node-vm-size Standard_D2ps_v5 \
    --labels cpu=arm

# Get the credentials for the cluster
az aks get-credentials \
    --resource-group ${nona} \
    --name ${nona}
    
az account set --subscription ${subscription} && az aks get-credentials --resource-group ${nona} --name ${nona}


# Get the nodes
kubectl get nodes
