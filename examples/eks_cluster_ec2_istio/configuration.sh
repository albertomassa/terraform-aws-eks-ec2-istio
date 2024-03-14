
#!/bin/bash

custom_kubectl_apply() {
    local file_path="$1"
    local placeholder="$2"
    local value="$3"
    if [ -z "$file_path" ] || [ -z "$placeholder"  ] || [ -z "$value"  ]; then
        echo "[ERROR] custom_kubectl_apply input params error."
        return 1
    fi
    local yaml_content=$(cat "$file_path")
    local yaml_content_modified=$(echo "$yaml_content" | sed "s|$placeholder|$value|g")
    echo "$yaml_content_modified" > "$file_path"
    echo "kubectl apply -f $file_path"
    kubectl apply -f "$file_path"
    local yaml_content_restored=$(echo "$yaml_content_modified" | sed "s|$value|$placeholder|g")
    echo "$yaml_content_restored" > "$file_path"
}

#get vars from terraform output
CLUSTER_ROLE_ARN=$(jq -r .cluster_controller_role_arn.value outputs.json)
CLUSTER_NAME=$(jq -r .cluster_name.value outputs.json)
CLUSTER_VPC_ID=$(jq -r .cluster_vpc_id.value outputs.json)
EC2_DEFAULT_SECURITY_GROUP=$(jq -r .ec2_default_security_group.value outputs.json)
PROJECT_REGION=$(jq -r .project_region.value outputs.json)

echo "CLUSTER_ROLE_ARN = $CLUSTER_ROLE_ARN"
echo "CLUSTER_NAME = $CLUSTER_NAME"
echo "CLUSTER_VPC_ID = $CLUSTER_VPC_ID"
echo "EC2_DEFAULT_SECURITY_GROUP = $EC2_DEFAULT_SECURITY_GROUP"
echo "PROJECT_REGION = $PROJECT_REGION"

#update kubeconfig
echo "aws eks update-kubeconfig --region $PROJECT_REGION --name $CLUSTER_NAME"
aws eks update-kubeconfig --region $PROJECT_REGION --name $CLUSTER_NAME

#service-account for aws-load-balancer-controller 
custom_kubectl_apply "conf_files/yaml/service.yaml" "<cluster_role_arn>" "$CLUSTER_ROLE_ARN"

#kube metrics
echo "kubectl apply -f conf_files/yaml/metrics.yaml"
kubectl apply -f conf_files/yaml/metrics.yaml

#install aws-load-balancer-controller with helm
echo "update helm repo"
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
echo "helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=$CLUSTER_NAME --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=$PROJECT_REGION --set vpcId=$CLUSTER_VPC_ID -n kube-system"
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=$CLUSTER_NAME --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=$PROJECT_REGION --set vpcId=$CLUSTER_VPC_ID -n kube-system
echo "kubectl get deployment -n kube-system aws-load-balancer-controller"

#aws-load-balancer-controller check
echo "waiting for aws-load-balancer-controller"
sleep 60
kubectl get deployment -n kube-system aws-load-balancer-controller

#istio install/configuration
USER_NAMESPACE="my-namespace"
echo "install istio"
kubectl create namespace istio-system
kubectl apply -f conf_files/yaml/istio.yaml
kubectl create namespace $USER_NAMESPACE
kubectl label namespace $USER_NAMESPACE istio-injection=enabled
kubectl get namespace $USER_NAMESPACE -L istio-injection 

#test
custom_kubectl_apply "conf_files/yaml/test-app-alb.yml" "<user_namespace>" "$USER_NAMESPACE"
custom_kubectl_apply "conf_files/yaml/test-app-nlb.yml" "<user_namespace>" "$USER_NAMESPACE"

echo "configuration script completed"