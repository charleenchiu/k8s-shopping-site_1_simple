如何刪除先前jenkins建置失敗，但terraform已建立的AWS資源：
ssh 連線進入Jenkins server EC2
```sh
cd /var/lib/jenkins/workspace/<item name>
```

編輯建立資源的tf檔
```sh
sudo nano main.tf
```

最前面加上
```js
provider "aws" {
  region = "us-east-1"
  access_key = "AKIASOEPH5NOGRJ2TBVE"
  secret_key = "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"
}
```
ctrl + X 離開 按Y選擇存檔

destroy已建的資源，刪除建置時留下的暫存檔
```sh
sudo terraform destroy -auto-approve
sudo rm -rf .terraform*
sudo rm -rf terraform.tfstate*
```
