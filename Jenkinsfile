pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_REGION = 'us-east-1'    // AWS 區域
        AWS_ACCOUNT_ID = '167804136284' // AWS 帳戶 ID
        SITE_ECR_REPO = ''   // ECR Repository 名稱（將在 Terraform 階段後更新）
        USER_SERVICE_ECR_REPO = ''  // User Service 的 ECR Repository
        PRODUCT_SERVICE_ECR_REPO = '' // Product Service 的 ECR Repository
        ORDER_SERVICE_ECR_REPO = '' // Order Service 的 ECR Repository
        PAYMENT_SERVICE_ECR_REPO = '' // Payment Service 的 ECR Repository
        EKS_CLUSTER_ARN = '' // EKS Cluster ARN（將在 Terraform 階段後更新）
        EKS_CLUSTER_URL = '' // EKS Cluster URL（將在 Terraform 階段後更新）
        KUBECONFIG_CERTIFICATE_AUTHORITY_DATA = '' // Kubernetes 憑證授權中心的資料
        IMAGE_TAG = 'latest' // Docker Image Tag
    }

    stages {
        stage('Checkout Code') {
            steps {
                // 從 Git 獲取程式碼
                git branch: '1_simple', url: 'https://github.com/charleenchiu/k8s-shopping-site.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                script {
                    // 初始化 Terraform 並應用配置
                    /* Jenkins 的每一個 sh 步驟都在一個新的 shell 中執行，
                        因此要在同一個 sh 步驟中執行所有相關的 Terraform 命令
                        才不會發生找不到路徑的問題 */
                    sh '''
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                    '''

                    // 取得 Terraform 的輸出，儲存輸出到 Jenkins 全域環境變數
                    env.SITE_ECR_REPO = sh(script: 'cd terraform && terraform output -raw site_ecr_repo', returnStdout: true).trim()
                    env.USER_SERVICE_ECR_REPO = sh(script: 'cd terraform && terraform output -raw user_service_ecr_repo', returnStdout: true).trim()
                    env.PRODUCT_SERVICE_ECR_REPO = sh(script: 'cd terraform && terraform output -raw product_service_ecr_repo', returnStdout: true).trim()
                    env.ORDER_SERVICE_ECR_REPO = sh(script: 'cd terraform && terraform output -raw order_service_ecr_repo', returnStdout: true).trim()
                    env.PAYMENT_SERVICE_ECR_REPO = sh(script: 'cd terraform && terraform output -raw payment_service_ecr_repo', returnStdout: true).trim()
                    env.EKS_CLUSTER_ARN = sh(script: 'cd terraform && terraform output -raw eks_cluster_arn', returnStdout: true).trim()
                    env.EKS_CLUSTER_URL = sh(script: 'cd terraform && terraform output -raw eks_cluster_url', returnStdout: true).trim()
                    env.KUBECONFIG_CERTIFICATE_AUTHORITY_DATA = sh(script: 'cd terraform && terraform output -raw kubeconfig_certificate_authority_data', returnStdout: true).trim()
                }
            }
        }

        /*
        stage('Ansible Configuration') {
            steps {
                script {
                    // 使用 Ansible 配置 EC2 或其他服務，並使用從 Terraform 獲得的變數
                    sh "ansible-playbook -i inventory.yml -e 'site_ecr_repo=$SITE_ECR_REPO eks_cluster_arn=$EKS_CLUSTER_ARN' setup.yml"
                }
            }
        }
        */

        stage('Build Docker Image') {
            steps {
                script {
                    // 使用 Dockerfile 建構 Image
                    sh 'docker build -t $SITE_ECR_REPO:$IMAGE_TAG .'
                    sh 'docker build -t $USER_SERVICE_ECR_REPO:$IMAGE_TAG .'
                    sh 'docker build -t $PRODUCT_SERVICE_ECR_REPO:$IMAGE_TAG .'
                    sh 'docker build -t $ORDER_SERVICE_ECR_REPO:$IMAGE_TAG .'
                    sh 'docker build -t $PAYMENT_SERVICE_ECR_REPO:$IMAGE_TAG .'
                }
            }
        }

        stage('Login to ECR & Push Image') {
            steps {
                script {
                    // 透過 AWS CLI 登入 ECR
                    sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com'

                    // Push Image 到 ECR
                    sh 'docker tag $SITE_ECR_REPO:$IMAGE_TAG ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$SITE_ECR_REPO:$IMAGE_TAG'
                    sh 'docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$SITE_ECR_REPO:$IMAGE_TAG'
                    sh 'docker tag $USER_SERVICE_ECR_REPO:$IMAGE_TAG ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$USER_SERVICE_ECR_REPO:$IMAGE_TAG'
                    sh 'docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$USER_SERVICE_ECR_REPO:$IMAGE_TAG'
                    sh 'docker tag $PRODUCT_SERVICE_ECR_REPO:$IMAGE_TAG ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$PRODUCT_SERVICE_ECR_REPO:$IMAGE_TAG'
                    sh 'docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$PRODUCT_SERVICE_ECR_REPO:$IMAGE_TAG'
                    sh 'docker tag $ORDER_SERVICE_ECR_REPO:$IMAGE_TAG ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$ORDER_SERVICE_ECR_REPO:$IMAGE_TAG'
                    sh 'docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$ORDER_SERVICE_ECR_REPO:$IMAGE_TAG'
                    sh 'docker tag $PAYMENT_SERVICE_ECR_REPO:$IMAGE_TAG ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$PAYMENT_SERVICE_ECR_REPO:$IMAGE_TAG'
                    sh 'docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$PAYMENT_SERVICE_ECR_REPO:$IMAGE_TAG'
                }
            }
        }

        stage('Update Kubernetes Deployment') {
            steps {
                script {
                    // 檢查當前工作目錄
                    sh 'pwd'

                    // 使用 sed 替換 YAML 中的 Docker image 欄位
                    sh "sed -i 's#your-dockerhub-username/k8s-shopping-site:latest#${env.SITE_ECR_REPO}:${env.IMAGE_TAG}#' ../k8s/site-service-deployment.yaml"
                    sh "sed -i 's#your-dockerhub-username/k8s-shopping-site:latest#${env.USER_SERVICE_ECR_REPO}:${env.IMAGE_TAG}#' ../k8s/user-service-deployment.yaml"
                    sh "sed -i 's#your-dockerhub-username/k8s-shopping-site:latest#${env.PRODUCT_SERVICE_ECR_REPO}:${env.IMAGE_TAG}#' ../k8s/product-service-deployment.yaml"
                    sh "sed -i 's#your-dockerhub-username/k8s-shopping-site:latest#${env.ORDER_SERVICE_ECR_REPO}:${env.IMAGE_TAG}#' ../k8s/order-service-deployment.yaml"
                    sh "sed -i 's#your-dockerhub-username/k8s-shopping-site:latest#${env.PAYMENT_SERVICE_ECR_REPO}:${env.IMAGE_TAG}#' ../k8s/payment-service-deployment.yaml"
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // 使用 kubectl 部署到 EKS
                    sh 'kubectl apply -f ../k8s/site-service-deployment.yaml'
                    sh 'kubectl apply -f ../k8s/user-service-deployment.yaml'
                    sh 'kubectl apply -f ../k8s/product-service-deployment.yaml'
                    sh 'kubectl apply -f ../k8s/order-service-deployment.yaml'
                    sh 'kubectl apply -f ../k8s/payment-service-deployment.yaml'
                }
            }
        }

        stage('Clean up Docker image') {
            steps {
                script {
                    // 清除Docker build cache
                    sh 'docker builder prune -f'
                }
            }
        }
    }

    post {
        always {
            // 無論成功與否，確保清理 Jenkins workspace
            cleanWS()
        }
    }
}
