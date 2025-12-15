# BespinFinal
VPN, DMS 테스트를 위한 테라폼
## Aws 구현사항
기본 인프라 + bastion 서버 코드
VPN, route53 resolver

### 추가
AWS DMS 테스트(
DMS는 콘솔에서 진행)

## Azure
기본 vm,db,private resolver

### Azure 사전 설정
```
#AzureCLI설치
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
#login하기
az login
#윈도우 로그인이 어려울 때
#az login --use-device-code
#azure 구독 아이디 확인
az account list --output table
```

## 추가
### 키 파일 위치 
ssh_public_key_path = "../keys/mykey.pub"

```
mkdir keys
cd keys
ssh-keygen -m PEM -f mykey -N ""
```
### 진행
1. key 생성 + vasriables에 대하여 terraform.tfvars
2. azure에서 마지막 vpn connection 부분을 주석 처리하고 apply
3. output에서의 값을 aws variable에 마저 채워넣기
4. aws apply
5. azure에서 apply

## Route53 test
1. alb에 대한 https 접속 테스트(콘솔 사용)
2. route53 failover test