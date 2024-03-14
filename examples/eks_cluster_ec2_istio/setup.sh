echo "terraform apply script"
terraform apply -auto-approve -var-file=variables.tfvars
echo "create new configuration file"
terraform output -json > outputs.json 
echo "launch configuration script"
sh configuration.sh
echo "remove configuration"
rm -rf outputs.json
echo "launch platform deploy script"
sh platform.sh
echo "setup script completed"