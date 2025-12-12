# BespinFinal
## Aws
기본 인프라 + bastion 서버 코드\n
VPN + AWS DMS 완성(
DMS는 콘솔에서 진행)

## Azure
기본 vm 테스트

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
ssh-keygen -m PEM -f mykey -N ""
ssh_public_key_path = "../keys/mykey.pub"
