## Mylo SCRIPT VPS INSTALL



## 1 INSTALL SCRIPT 

```
apt install -y && apt update -y && apt upgrade -y && wget -q https://raw.githubusercontent.com/mylo1998/Mylo/refs/heads/main/install && chmod +x install  && ./install 
```

## 2. UPDATE 

```
cd root
rm update.sh
wget https://raw.githubusercontent.com/mylo1998/Mylo/refs/heads/main/menu/update.sh && chmod +x update.sh && ./update.sh
```

## For Debian 10 / 11 / 12 For First Time Installation (Update Repo

```
apt update -y && apt upgrade -y && apt dist-upgrade -y && reboot
```
 
## For Ubuntu / 22.04 / 24.04 For First Time Installation (Update Repo)

```
apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
```
