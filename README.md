# ServerStatus-Hotaru

雲探針、多伺服器探針、雲監控、多伺服器雲監控

基於 ServerStatus-Toyo 最新版本稍作修改。

## 特性

伺服器客戶端腳本支持系統：Centos 7、Debian 7、Ubuntu 14.04 及以上、ArchLinux

客戶端支持 Python 版本：Python 2.7 - Python 3

Golang客戶端：如果您的客戶端環境無法使用 Python， 可以使用 Golang 編寫的客戶端

開源地址：https://github.com/cokemine/ServerStatus-goclient

流量計算：客戶端可以選擇使用 vnStat 按月計算流量，會自動編譯安裝最新版本vnStat（ArchLinux 會從軟體源安裝最新版本）。如不使用 vnStat ，則預設計算流量方式為重啟後流量清零。請注意 ServerStatus 不會與協議為 GPLv2 的 vnStat 強耦合。

前端基於 Vue 3.0 和 SemanticUI 製作，如需修改前端建議自行修改打包。

前端所使用一些靜態資源見前端專案下的聲明。

前端開源地址：https://github.com/cokemine/hotaru_theme

## 其他說明

ServerStatus-Hotaru 將會停留在輕量級的 ServerStatus，不會再添加新的功能

如果你有以下需求：

1、Websocket

2、Docker

3、客戶端離線 Telegram Bot 通知

4、使用 Web 管理、添加、修改客戶端信息

歡迎使用 NodeStatus: https://github.com/cokemine/nodestatus （請到 beta 版再實際使用）

ServerStatus-Hotaru 仍會繼續維護

## 安裝方法

伺服器：

```bash
wget https://raw.githubusercontent.com/Chromeina/ServerStatus-Hotaru/master/status.sh
# wget https://cokemine.coding.net/p/hotarunet/d/ServerStatus-Hotaru/git/raw/master/status.sh 若伺服器位於中國大陸建議選擇Coding.net倉庫
bash status.sh s
```

客戶端：

```bash
bash status.sh c
```

具體可見：https://www.cokemine.com/serverstatus-hotaru.html

## 手動安裝伺服器

```bash
mkdir -p /usr/local/ServerStatus/server
apt install wget unzip curl vim build-essential
cd /tmp
wget https://github.com/Chromeina/ServerStatus-Hotaru/archive/master.zip
unzip master.zip
cd ./ServerStatus-Hotaru-master/server
make #編譯生成二進製文件
chmod +x sergate
mv sergate /usr/local/ServerStatus/server
vim /usr/local/ServerStatus/server/config.json #修改配置文件 
#下載前端
cd /tmp && wget https://github.com/Chromeina/Hotaru_theme/releases/latest/download/hotaru-theme.zip
unzip hotaru-theme.zip
mv ./hotaru-theme /usr/local/ServerStatus/web #此為站點根目錄，請自行設置
nohup ./sergate --config=config.json --web-dir=/usr/local/ServerStatus/web --port=35601 > /tmp/serverstatus_server.log 2>&1 & #預設端口 35601
```

## 手動安裝客戶端

使用 Psutil 版客戶端即可使 ServerStatus 客戶端在 Windows 等其他平台運行

```powershell
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py # 若未安裝pip
python get-pip.py
python pip install psutil
# 修改 status-psutil.py
python status-psutil.py
```

Linux 版客戶端支持絕大部分 Linux 發行版系統，一般不需要使用 psutil 版客戶端。

```bash
apt install python3 python3-pip wget
pip3 install psutil
wget https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-psutil.py
vim status-psutil.py #修改客戶端配置文件
python3 status-psutil.py
# https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-client.py 預設版本無需 psutil 依賴
```

## 更新前端

預設伺服器更新不會更新前端。因為更新前端會導致自己自定義的前端消失。

```bash
rm -rf /usr/local/ServerStatus/web/*
wget "https://github.com/cokemine/hotaru_theme/releases/download/latest/hotaru-theme.zip"
unzip hotaru-theme.zip
mv ./hotaru-theme/* /usr/local/ServerStatus/web/
service status-server restart
# systemctl restart status-server
```

## 關於前端旗幟圖標

目前通過腳本使用旗幟圖標僅支援當前國家/地區在 ISO 3166-1 標準裡，否則可能會出現無法添加的情況，如歐盟 `EU`，但是前端是具備該旗幟的。你可能需要手動加入。方法是修改`/usr/local/ServerStatus/server/config.json`，將你想修改的伺服器的`region`改成你需要的。

同時，前端還具備以下特殊旗幟，可供選擇使用，啟用也是需要上述修改。

Transgender flag: `trans`

Rainbow flag: `rainbow`

Pirate flag: `pirate`

## Toyo版本修改方法

如果你使用 Toyo 版本或其他版本的 ServerStatus，請備份你的config文件並重新編譯安裝本版本伺服器

配置文件: /usr/local/ServerStatus/server/config.json 備份並自行添加`region`

```json
{
   "username": "Name",
   "password": "Password",
   "name": "Your Servername",
   "type": "KVM",
   "host": "None",
   "location": "洛杉磯",
   "disabled": false,
   "region": "US"
},
```

替換配置文件，重啟 ServerStatus

## 效果演示

![RktuH.png](https://img.ams1.imgbed.xyz/2021/09/02/xbuk1.png)

## 相關開源項目：

* ServerStatus-Toyo：https://github.com/ToyoDAdoubiBackup/ServerStatus-Toyo MIT License
* ServerStatus：https://github.com/BotoX/ServerStatus WTFPL License
* mojeda's ServerStatus: https://github.com/mojeda/ServerStatus WTFPL License -> GNU GPLv3 License (ServerStatus is a full rewrite of mojeda's ServerStatus script and not affected by GPL)
* BlueVM's project: http://www.lowendtalk.com/discussion/comment/169690#Comment_169690 WTFPL License

## 感謝

* i18n-iso-countries: https://github.com/michaelwittig/node-i18n-iso-countries MIT License (To convert country name in Chinese to iso 3166-1 and check if the code is valid)
* jq: https://github.com/stedolan/jq CC BY 3.0 License
* caddy: https://github.com/caddyserver/caddy Apache-2.0 License
* twemoji: https://github.com/twitter/twemoji CC-BY 4.0 License (The flag icons are designed by Twitter)
