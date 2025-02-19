# Stat Analysis Web Application Infrastructure
This project utilizes Terraform and Ansible to provision the necessary infrastructure for a web application hosted on AWS. The web application allows users to upload CSV files and request statistical analysis. The results are processed by AWS Lambda microservices and stored in an S3 bucket, while metadata about user requests and processed files are stored in an RDS database.

**Important Note:** This project only provisions the infrastructure required to support the application. It does not include the implementation of the microservices that process the CSV files. The microservices themselves (such as the statistical analysis logic) would need to be developed separately.

## Key features
1. **CSV File Upload**
Users can upload CSV files via the web interface. The CSV file and the analysis results are stored in an S3 bucket.

2. **Statistical Analysis Microservices**
The system provides a selection of statistical analyses, each implemented as a separate AWS Lambda function. The corresponding microservice retrieves the CSV file, processes it, and stores the results back in the S3 bucket.

3. **Database Logging**
User requests and associated metadata (file, type of analysis, status, etc.) are logged in an RDS MySQL database.

4. **Web Interface Hosting**
The web application is hosted on an EC2 instance running Ubuntu. It is configured with Ansible to install Apache and serve the web content.

5. **Secure Infrastructure**
The infrastructure is secured using VPC with public and private subnets for better availability and security. Security groups, IAM roles, and policies ensure the resources are properly secured and communication is restricted to necessary services.

## AWS Infrastructure
- VPC: Custom VPC with public and private subnets in different availability zones for high availability.
- S3: Bucket to store uploaded CSV files and analysis results.
- EC2: Instance for hosting the web application and interacting with S3.
- RDS MySQL: Database for logging user requests and processing data.
- IAM Roles/Policies: Proper roles and policies for secure communication between EC2, Lambda, and S3.

## Tools used
- Terraform: For provisioning and managing AWS resources.
- Ansible: For configuration management and installing Apache on the EC2 instance.

## How to set up
1. Generate and convert the SSH key
On a Windows machine, use CMD with administrator permissions to generate an SSH key pair for EC2 access:
- Run the following command to generate the key:
```cmd
ssh-keygen -t rsa -b 2048
```
- Then, convert the key to the PEM format using:
```cmd
ssh-keygen -p -m PEM -f C:/Users/'${YourUsername}'/.ssh/id_rsa
```

2. Set up your AWS credentials in the environment (e.g., AWS_Key, AWS_Secret, Region_AWS).
3. Initialize the Terraform configuration by running:
```hcl
terraform init
```
4. Apply the Terraform configuration to provision the AWS resources:
```hcl
terraform apply
```
5. Run the Ansible playbook to configure the EC2 instance and install Apache:
- Ensure that you have the correct private SSH key for connection to EC2.
- Run the following command to execute the playbook:
```bash
ansible-playbook apache.yml
```
6. Access the web application via the EC2 instance’s public IP.

## Security considerations
- VPC & Subnet Configuration: Resources like the RDS database are placed in private subnets to restrict direct public access. The EC2 instance is located in a public subnet to handle user traffic securely.
- NAT Gateway: A NAT gateway is configured in a public subnet to allow resources in private subnets (such as the RDS instance) to access the internet for updates or necessary outbound traffic, without exposing them directly to the public internet.
- IAM Roles & Policies: Appropriate roles and policies are used to limit access between AWS services (e.g., S3, Lambda, and EC2) and ensure that each resource has the minimal permissions needed.
- Security Groups: Security groups control traffic flow to and from the EC2 and RDS instances, based on required protocols and ports, ensuring only authorized connections are allowed.
