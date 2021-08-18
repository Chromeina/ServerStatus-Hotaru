#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#  System Required: CentOS/Debian/Ubuntu/ArchLinux
#  Description: ServerStatus client + server
#  Version: Test v0.2.0
#  Author: Toyo,Modified by APTX
#=================================================

sh_ver="0.3.1"
filepath=$(
  cd "$(dirname "$0")" || exit
  pwd
)
file_1=$(echo -e "${filepath}" | awk -F "$0" '{print $1}')
file="/usr/local/ServerStatus"
web_file="/usr/local/ServerStatus/web"
server_file="/usr/local/ServerStatus/server"
server_conf="/usr/local/ServerStatus/server/config.json"
server_conf_1="/usr/local/ServerStatus/server/config.conf"
client_file="/usr/local/ServerStatus/client"

client_log_file="/tmp/serverstatus_client.log"
server_log_file="/tmp/serverstatus_server.log"
jq_file="${file}/jq"
region_json="${file}/region.json"

github_prefix="https://raw.githubusercontent.com/Chromeina/ServerStatus-Hotaru/master"
coding_prefix="https://cokemine.coding.net/p/hotarunet/d/ServerStatus-Hotaru/git/raw/master"
link_prefix=${github_prefix}

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[訊息]${Font_color_suffix}"
Error="${Red_font_prefix}[錯誤]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

#檢查系統
check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif grep -q -E -i "debian|ubuntu" /etc/issue; then
    release="debian"
  elif grep -q -E -i "centos|red hat|redhat" /etc/issue; then
    release="centos"
  elif grep -q -E -i "debian|ubuntu" /proc/version; then
    release="debian"
  elif grep -q -E -i "centos|red hat|redhat" /proc/version; then
    release="centos"
  elif grep -q -E -i "Arch|Manjaro" /etc/issue; then
    release="archlinux"
  else
    echo -e 'ServerStatus 暫時不支援此Linux版本'
  fi
  bit=$(uname -m)
}
check_installed_server_status() {
  [[ ! -e "${server_file}/sergate" ]] && echo -e "${Error} ServerStatus 伺服器端尚未安裝，請檢查 !" && exit 1
}
check_installed_client_status() {
  if [[ ! -e "${client_file}/status-client.py" ]]; then
    if [[ ! -e "${file}/status-client.py" ]]; then
      echo -e "${Error} ServerStatus 客戶端沒有安裝，請檢查 !" && exit 1
    fi
  fi
}
check_pid_server() {
  #PID=$(ps -ef | grep "sergate" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(pgrep -f "sergate")
}
check_pid_client() {
  #PID=$(ps -ef | grep "status-client.py" | grep -v grep | grep -v ".sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  PID=$(pgrep -f "status-client.py")
}
check_region() {
  if ${jq_file} "[.countries | has(\"${region_s}}\")]" "${region_json}" | grep -q 'true' >/dev/null 2>&1; then
    return 0
  elif grep -qw "${region_s}" "${region_json}"; then
    region_s=$(grep -w "${region_s}" "${region_json}" | sed "s/[[:space:]]//g")
    region_s=${region_s:1:2}
    return 0
  fi
  return 1
}
Download_Server_Status_server() {
  cd "/tmp" || exit 1
  [[ ${mirror_num} == 2 ]] && bundle_link="https://cokemine.coding.net/p/hotarunet/d/ServerStatus-Hotaru/git/archive/master/?download=true" || bundle_link="https://github.com/cokemine/ServerStatus-Hotaru/archive/master.zip"
  wget -N --no-check-certificate "${bundle_link}" -O "master.zip"
  [[ ! -e "master.zip" ]] && echo -e "${Error} ServerStatus 伺服器端下載失敗 !" && exit 1
  unzip master.zip
  rm -rf master.zip
  [[ -d "/tmp/chromeina-hotarunet-ServerStatus-Hotaru-master" ]] && mv "/tmp/chromeina-hotarunet-ServerStatus-Hotaru-master" "/tmp/ServerStatus-Hotaru-master"
  [[ ! -d "/tmp/ServerStatus-Hotaru-master" ]] && echo -e "${Error} ServerStatus 伺服器端解壓縮失敗 !" && exit 1
  cd "/tmp/ServerStatus-Hotaru-master/server" || exit 1
  make
  [[ ! -e "sergate" ]] && echo -e "${Error} ServerStatus 伺服器端編譯失敗 !" && cd "${file_1}" && rm -rf "/tmp/ServerStatus-Hotaru-master" && exit 1
  cd "${file_1}" || exit 1
  [[ ! -e "${file}" ]] && mkdir "${file}"
  if [[ ! -e "${server_file}" ]]; then
    mkdir "${server_file}"
    mv "/tmp/ServerStatus-Hotaru-master/server/sergate" "${server_file}/sergate"
    wget -N --no-check-certificate https://github.com/Chromeina/Hotaru_theme/releases/latest/download/hotaru-theme.zip
    unzip hotaru-theme.zip && mv "./hotaru-theme" "${web_file}"
  else
    if [[ -e "${server_file}/sergate" ]]; then
      mv "${server_file}/sergate" "${server_file}/sergate1"
      mv "/tmp/ServerStatus-Hotaru-master/server/sergate" "${server_file}/sergate"
    else
      mv "/tmp/ServerStatus-Hotaru-master/server/sergate" "${server_file}/sergate"
      wget -N --no-check-certificate https://github.com/Chromeina/Hotaru_theme/releases/latest/download/hotaru-theme.zip
      unzip hotaru-theme.zip && mv "./hotaru-theme" "${web_file}"
    fi
  fi
  if [[ ! -e "${server_file}/sergate" ]]; then
    echo -e "${Error} ServerStatus 伺服器端移動重新命名失敗 !"
    [[ -e "${server_file}/sergate1" ]] && mv "${server_file}/sergate1" "${server_file}/sergate"
    rm -rf "/tmp/ServerStatus-Hotaru-master"
    exit 1
  else
    [[ -e "${server_file}/sergate1" ]] && rm -rf "${server_file}/sergate1"
    rm -rf "/tmp/ServerStatus-Hotaru-master"
  fi
}
Download_Server_Status_client() {
  cd "/tmp" || exit 1
  wget -N --no-check-certificate "${link_prefix}/clients/status-client.py"
  [[ ! -e "status-client.py" ]] && echo -e "${Error} ServerStatus 客戶端下載失敗 !" && exit 1
  cd "${file_1}" || exit 1
  [[ ! -e "${file}" ]] && mkdir "${file}"
  if [[ ! -e "${client_file}" ]]; then
    mkdir "${client_file}"
    mv "/tmp/status-client.py" "${client_file}/status-client.py"
  else
    if [[ -e "${client_file}/status-client.py" ]]; then
      mv "${client_file}/status-client.py" "${client_file}/status-client1.py"
      mv "/tmp/status-client.py" "${client_file}/status-client.py"
    else
      mv "/tmp/status-client.py" "${client_file}/status-client.py"
    fi
  fi
  if [[ ! -e "${client_file}/status-client.py" ]]; then
    echo -e "${Error} ServerStatus 客戶端移動失敗 !"
    [[ -e "${client_file}/status-client1.py" ]] && mv "${client_file}/status-client1.py" "${client_file}/status-client.py"
    rm -rf "/tmp/status-client.py"
    exit 1
  else
    [[ -e "${client_file}/status-client1.py" ]] && rm -rf "${client_file}/status-client1.py"
    rm -rf "/tmp/status-client.py"
  fi
}
Service_Server_Status_server() {
  if [[ ${release} == "centos" ]]; then
    if ! wget --no-check-certificate "${link_prefix}/service/server_status_server_centos" -O /etc/init.d/status-server; then
      echo -e "${Error} ServerStatus 伺服器端服務管理腳本下載失敗 !" && exit 1
    fi
    chmod +x /etc/init.d/status-server
    chkconfig --add status-server
    chkconfig status-server on
  elif [[ ${release} == "debian" ]]; then
    if ! wget --no-check-certificate "${link_prefix}/service/server_status_server_debian" -O /etc/init.d/status-server; then
      echo -e "${Error} ServerStatus 伺服器端服務管理腳本下載失敗 !" && exit 1
    fi
    chmod +x /etc/init.d/status-server
    update-rc.d -f status-server defaults
  elif [[ ${release} == "archlinux" ]]; then
    if [ ! -d "/etc/init.d" ]; then
      mkdir /etc/init.d
    fi
    if ! wget --no-check-certificate "${link_prefix}/service/server_status_server_archlinux" -O /etc/init.d/status-server; then
      echo -e "${Error} ServerStatus 客戶端服務管理腳本下載失敗 !" && exit 1
    fi
    chmod +x /etc/init.d/status-server
    cat >/usr/lib/systemd/system/status-server.service <<-EOF
[Unit]
Description=Statusserver
Documentation=https://github.com/Chromeina/ServerStatus-Hotaru
After=network.target
[Service]
ExecStart=/etc/init.d/status-server start
ExecStop=/etc/init.d/status-server stop
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable status-server.service
  fi
  echo -e "${Info} ServerStatus 伺服器端服務管理腳本下載完成 !"
}
Service_Server_Status_client() {
  if [[ ${release} == "centos" ]]; then
    if ! wget --no-check-certificate "${link_prefix}/service/server_status_client_centos" -O /etc/init.d/status-client; then
      echo -e "${Error} ServerStatus 客戶端服務管理腳本下載失敗 !" && exit 1
    fi
    chmod +x /etc/init.d/status-client
    chkconfig --add status-client
    chkconfig status-client on
  elif [[ ${release} == "debian" ]]; then
    if ! wget --no-check-certificate "${link_prefix}/service/server_status_client_debian" -O /etc/init.d/status-client; then
      echo -e "${Error} ServerStatus 客戶端服務管理腳本下載失敗 !" && exit 1
    fi
    chmod +x /etc/init.d/status-client
    update-rc.d -f status-client defaults
  elif [[ ${release} == "archlinux" ]]; then
    if [ ! -d "/etc/init.d" ]; then
      mkdir /etc/init.d
    fi
    if ! wget --no-check-certificate "${link_prefix}/service/server_status_client_archlinux" -O /etc/init.d/status-client; then
      echo -e "${Error} ServerStatus 客戶端服務管理腳本下載失敗 !" && exit 1
    fi
    chmod +x /etc/init.d/status-client
    cat >/usr/lib/systemd/system/status-client.service <<-EOF
[Unit]
Description=StatusClient
Documentation=https://github.com/cokemine/ServerStatus-Hotaru
After=network.target
[Service]
ExecStart=/etc/init.d/status-client start
ExecStop=/etc/init.d/status-client stop
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable status-client.service
  fi
  echo -e "${Info} ServerStatus 客戶端服務管理腳本下載完成 !"
}
Installation_dependency() {
  mode=$1
  if python3 --help >/dev/null 2>&1; then
    ln -s /usr/bin/python3 /usr/bin/python
    python_status=1
  elif python --help >/dev/null 2>&1; then
    python_status=1
  else
    python_status=0
  fi
  if [[ ${mode} == "server" ]]; then
    if [[ ${release} == "centos" ]]; then
      yum -y update
      if [ ${python_status} -eq 0 ]; then
        yum -y install python3 unzip vim make
        ln -s /usr/bin/python3 /usr/bin/python
        yum -y groupinstall "Development Tools"
      elif [ ${python_status} -eq 1 ]; then
        yum -y install unzip vim make
        yum -y groupinstall "Development Tools"
      fi
    elif [[ ${release} == "debian" ]]; then
      apt-get update -y
      if [ ${python_status} -eq 0 ]; then
        apt-get -y install python3 unzip vim build-essential
        ln -s /usr/bin/python3 /usr/bin/python
      elif [ ${python_status} -eq 1 ]; then
        apt-get -y install unzip vim build-essential
      fi
    elif [[ ${release} == "archlinux" ]]; then
      if [ ${python_status} -eq 0 ]; then
        pacman -Sy python python-pip --noconfirm
      elif [ ${python_status} -eq 1 ]; then
        pacman -Sy base-devel --noconfirm
      fi
    fi
  elif [[ ${mode} == "client" ]]; then
    if [ ${release} == "centos" ]; then
      if [ "${python_status}" -eq 0 ]; then
        yum -y update
        yum -y install python3
        ln -s /usr/bin/python3 /usr/bin/python
      fi
    elif [[ ${release} == "debian" ]]; then
      if [ "${python_status}" -eq 0 ]; then
        apt-get -y update
        apt-get -y install python3
        ln -s /usr/bin/python3 /usr/bin/python
      fi
    elif [[ ${release} == "archlinux" ]]; then
      if [ ${python_status} -eq 0 ]; then
        pacman -Sy python python-pip --noconfirm
      fi
    fi
  fi
}
Write_server_config() {
  cat >${server_conf} <<-EOF
{"servers":
 [
  {
   "username": "username01",
   "password": "password",
   "name": "Server 01",
   "type": "KVM",
   "host": "",
   "location": "Hong Kong",
   "disabled": false,
   "region": "HK"
  }
 ]
}
EOF
}
Write_server_config_conf() {
  cat >${server_conf_1} <<-EOF
PORT = ${server_port_s}
EOF
}
Read_config_client() {
  if [[ ! -e "${client_file}/status-client.py" ]]; then
    if [[ ! -e "${file}/status-client.py" ]]; then
      echo -e "${Error} ServerStatus 客戶端文件不存在 !" && exit 1
    else
      client_text="$(sed 's/\"//g;s/,//g;s/ //g' "${file}/status-client.py")"
      rm -rf "${file}/status-client.py"
    fi
  else
    client_text="$(sed 's/\"//g;s/,//g;s/ //g' "${client_file}/status-client.py") "
  fi
  client_server="$(echo -e "${client_text}" | grep "SERVER=" | awk -F "=" '{print $2}')"
  client_port="$(echo -e "${client_text}" | grep "PORT=" | awk -F "=" '{print $2}')"
  client_user="$(echo -e "${client_text}" | grep "USER=" | awk -F "=" '{print $2}')"
  client_password="$(echo -e "${client_text}" | grep "PASSWORD=" | awk -F "=" '{print $2}')"
  grep -q "NET_IN, NET_OUT = get_traffic_vnstat()" "${client_file}/status-client.py" && client_vnstat="true" || client_vnstat="false"
}
Read_config_server() {
  if [[ ! -e "${server_conf_1}" ]]; then
    server_port_s="35601"
    Write_server_config_conf
    server_port="35601"
  else
    server_port="$(grep "PORT = " ${server_conf_1} | awk '{print $3}')"
  fi
}
Set_server() {
  mode=$1
  [[ -z ${mode} ]] && mode="server"
  if [[ ${mode} == "server" ]]; then
    echo -e "請輸入 ServerStatus 伺服器端網站要設定的 域名[server]
預設本機IP為域名，例如輸入: toyoo.pw ，如果要使用本機IP，請直接按下Enter"
    read -erp "(預設: 本機IP):" server_s
    [[ -z "$server_s" ]] && server_s=""
  else
    echo -e "請輸入 ServerStatus 伺服器端的 IP/域名[server]，請注意，如果你的域名套用了CDN，請直接填寫IP"
    read -erp "(默认: 127.0.0.1):" server_s
    [[ -z "$server_s" ]] && server_s="127.0.0.1"
  fi

  echo && echo "	================================================"
  echo -e "	IP/域名[server]: ${Red_background_prefix} ${server_s} ${Font_color_suffix}"
  echo "	================================================" && echo
}
Set_server_http_port() {
  while true; do
    echo -e "請輸入 ServerStatus 伺服器端網站要設定的 域名/IP的連接埠[1-65535]（如果是域名的話，一般使用 80 連接埠）"
    read -erp "(預設: 8888):" server_http_port_s
    [[ -z "$server_http_port_s" ]] && server_http_port_s="8888"
    if [[ "$server_http_port_s" =~ ^[0-9]*$ ]]; then
      if [[ ${server_http_port_s} -ge 1 ]] && [[ ${server_http_port_s} -le 65535 ]]; then
        echo && echo "	================================================"
        echo -e "	連接埠: ${Red_background_prefix} ${server_http_port_s} ${Font_color_suffix}"
        echo "	================================================" && echo
        break
      else
        echo "輸入錯誤, 請輸入正確的連接埠。"
      fi
    else
      echo "輸入錯誤, 請輸入正確的連接埠。"
    fi
  done
}
Set_server_port() {
  while true; do
    echo -e "請輸入 ServerStatus 伺服器端監聽的連接埠[1-65535]（用於伺服器接收來自客戶端的資料，設定客戶端時也要填寫這連接埠）"
    read -erp "(預設: 35601):" server_port_s
    [[ -z "$server_port_s" ]] && server_port_s="35601"
    if [[ "$server_port_s" =~ ^[0-9]*$ ]]; then
      if [[ ${server_port_s} -ge 1 ]] && [[ ${server_port_s} -le 65535 ]]; then
        echo && echo "	================================================"
        echo -e "	連接埠: ${Red_background_prefix} ${server_port_s} ${Font_color_suffix}"
        echo "	================================================" && echo
        break
      else
        echo "輸入錯誤, 請輸入正確的連接埠。"
      fi
    else
      echo "輸入錯誤, 請輸入正確的連接埠。"
    fi
  done
}
Set_username() {
  mode=$1
  [[ -z ${mode} ]] && mode="server"
  if [[ ${mode} == "server" ]]; then
    echo -e "請輸入 ServerStatus 伺服器端要設定的帳號[username]（字母/數字，不可與其他帳號重複）"
  else
    echo -e "請輸入 ServerStatus 伺服器端對應的帳號[username]（字母/數字，不可與其他帳號重複）"
  fi
  read -erp "(預設: 取消):" username_s
  [[ -z "$username_s" ]] && echo "已取消..." && exit 0
  echo && echo "	================================================"
  echo -e "	帳號[username]: ${Red_background_prefix} ${username_s} ${Font_color_suffix}"
  echo "	================================================" && echo
}
Set_password() {
  mode=$1
  [[ -z ${mode} ]] && mode="server"
  if [[ ${mode} == "server" ]]; then
    echo -e "請輸入 ServerStatus 伺服器端要設定的密碼[password]（字母/數字，可重複）"
  else
    echo -e "請輸入 ServerStatus 伺服器端對應的密碼[password]（字母/數字）"
  fi
  read -erp "(預設: passwd):" password_s
  [[ -z "$password_s" ]] && password_s="passwd"
  echo && echo "	================================================"
  echo -e "	密碼[password]: ${Red_background_prefix} ${password_s} ${Font_color_suffix}"
  echo "	================================================" && echo
}
Set_vnstat() {
  echo -e "計算流量時是否使用Vnstat每月自動歸零？ [y/N]"
  read -erp "(預設: N):" isVnstat
  [[ -z "$isVnstat" ]] && isVnstat="n"
}
Set_name() {
  echo -e "請輸入 ServerStatus 伺服器端要設定的節點名稱[name]（支援中文，前提是你的系統與SSH程式支援中文輸入，會顯示在網頁上）"
  read -erp "(預設: Server 01):" name_s
  [[ -z "$name_s" ]] && name_s="Server 01"
  echo && echo "	================================================"
  echo -e "	節點名稱[name]: ${Red_background_prefix} ${name_s} ${Font_color_suffix}"
  echo "	================================================" && echo
}
Set_type() {
  echo -e "請輸入 ServerStatus 伺服器端要設定的節點虛擬化類型[type]（例如 OpenVZ / KVM）"
  read -erp "(預設: KVM):" type_s
  [[ -z "$type_s" ]] && type_s="KVM"
  echo && echo "	================================================"
  echo -e "	虛擬化類型[type]: ${Red_background_prefix} ${type_s} ${Font_color_suffix}"
  echo "	================================================" && echo
}
Set_location() {
  echo -e "請輸入 ServerStatus 伺服器端要設定的節點位置[location]（支援中文，前提是你的系統與SSH程式支援中文輸入）"
  read -erp "(預設: Hong Kong):" location_s
  [[ -z "$location_s" ]] && location_s="Hong Kong"
  echo && echo "	================================================"
  echo -e "	節點位置[location]: ${Red_background_prefix} ${location_s} ${Font_color_suffix}"
  echo "	================================================" && echo
}
Set_region() {
  echo -e "請輸入 ServerStatus 伺服器端要設定的節點地區[region]（用於國家/地區的圖標顯示）"
  read -erp "(預設: HK):" region_s
  [[ -z "$region_s" ]] && region_s="HK"
  while ! check_region; do
    read -erp "你輸入的節點地區不合法，請重新輸入：" region_s
  done
  echo && echo "	================================================"
  echo -e "	節點地區[region]: ${Red_background_prefix} ${region_s} ${Font_color_suffix}"
  echo "	================================================" && echo
}
Set_config_server() {
  Set_username "server"
  Set_password "server"
  Set_name
  Set_type
  Set_location
  Set_region
}
Set_config_client() {
  Set_server "client"
  Set_server_port
  Set_username "client"
  Set_password "client"
  Set_vnstat
}
Set_ServerStatus_server() {
  check_installed_server_status
  echo && echo -e " 你要做什麼？

 ${Green_font_prefix} 1.${Font_color_suffix} 添加 節點設定
 ${Green_font_prefix} 2.${Font_color_suffix} 刪除 節點設定
————————
 ${Green_font_prefix} 3.${Font_color_suffix} 修改 節點設定 - 節點帳號
 ${Green_font_prefix} 4.${Font_color_suffix} 修改 節點設定 - 節點密碼
 ${Green_font_prefix} 5.${Font_color_suffix} 修改 節點設定 - 節點名稱
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 節點設定 - 節點虛擬化
 ${Green_font_prefix} 7.${Font_color_suffix} 修改 節點設定 - 節點位置
 ${Green_font_prefix} 8.${Font_color_suffix} 修改 節點設定 - 節點區域
 ${Green_font_prefix} 9.${Font_color_suffix} 修改 節點設定 - 全部參數
————————
 ${Green_font_prefix} 10.${Font_color_suffix} 啟用/禁用 節點設定
————————
 ${Green_font_prefix}11.${Font_color_suffix} 修改 伺服器端監聽連接埠" && echo
  read -erp "(預設: 取消):" server_num
  [[ -z "${server_num}" ]] && echo "已取消..." && exit 1
  if [[ ${server_num} == "1" ]]; then
    Add_ServerStatus_server
  elif [[ ${server_num} == "2" ]]; then
    Del_ServerStatus_server
  elif [[ ${server_num} == "3" ]]; then
    Modify_ServerStatus_server_username
  elif [[ ${server_num} == "4" ]]; then
    Modify_ServerStatus_server_password
  elif [[ ${server_num} == "5" ]]; then
    Modify_ServerStatus_server_name
  elif [[ ${server_num} == "6" ]]; then
    Modify_ServerStatus_server_type
  elif [[ ${server_num} == "7" ]]; then
    Modify_ServerStatus_server_location
  elif [[ ${server_num} == "8" ]]; then
    Modify_ServerStatus_server_region
  elif [[ ${server_num} == "9" ]]; then
    Modify_ServerStatus_server_all
  elif [[ ${server_num} == "10" ]]; then
    Modify_ServerStatus_server_disabled
  elif [[ ${server_num} == "11" ]]; then
    Read_config_server
    Del_iptables "${server_port}"
    Set_server_port
    Write_server_config_conf
    Add_iptables "${server_port_s}"
  else
    echo -e "${Error} 請輸入正確的數字[1-11]" && exit 1
  fi
  Restart_ServerStatus_server
}
List_ServerStatus_server() {
  conf_text=$(${jq_file} '.servers' ${server_conf} | ${jq_file} ".[]|.username" | sed 's/\"//g')
  conf_text_total=$(echo -e "${conf_text}" | wc -l)
  [[ ${conf_text_total} == "0" ]] && echo -e "${Error} 沒有找到任何一個節點設定，請重新檢查 !" && exit 1
  conf_text_total_a=$((conf_text_total - 1))
  conf_list_all=""
  for ((integer = 0; integer <= conf_text_total_a; integer++)); do
    now_text=$(${jq_file} '.servers' ${server_conf} | ${jq_file} ".[${integer}]" | sed 's/\"//g;s/,$//g' | sed '$d;1d')
    now_text_username=$(echo -e "${now_text}" | grep "username" | awk -F ": " '{print $2}')
    now_text_password=$(echo -e "${now_text}" | grep "password" | awk -F ": " '{print $2}')
    now_text_name=$(echo -e "${now_text}" | grep "name" | grep -v "username" | awk -F ": " '{print $2}')
    now_text_type=$(echo -e "${now_text}" | grep "type" | awk -F ": " '{print $2}')
    now_text_location=$(echo -e "${now_text}" | grep "location" | awk -F ": " '{print $2}')
    now_text_region=$(echo -e "${now_text}" | grep "region" | awk -F ": " '{print $2}')
    now_text_disabled=$(echo -e "${now_text}" | grep "disabled" | awk -F ": " '{print $2}')
    if [[ ${now_text_disabled} == "false" ]]; then
      now_text_disabled_status="${Green_font_prefix}啟用${Font_color_suffix}"
    else
      now_text_disabled_status="${Red_font_prefix}禁用${Font_color_suffix}"
    fi
    conf_list_all=${conf_list_all}"帳號: ${Green_font_prefix}${now_text_username}${Font_color_suffix} 密碼: ${Green_font_prefix}${now_text_password}${Font_color_suffix} 節點名: ${Green_font_prefix}${now_text_name}${Font_color_suffix} 類型: ${Green_font_prefix}${now_text_type}${Font_color_suffix} 位置: ${Green_font_prefix}${now_text_location}${Font_color_suffix} 區域: ${Green_font_prefix}${now_text_region}${Font_color_suffix} 狀態: ${Green_font_prefix}${now_text_disabled_status}${Font_color_suffix}\n"
  done
  echo && echo -e "節點總數 ${Green_font_prefix}${conf_text_total}${Font_color_suffix}"
  echo -e "${conf_list_all}"
}
Add_ServerStatus_server() {
  Set_config_server
  Set_username_ch=$(grep '"username": "'"${username_s}"'"' ${server_conf})
  [[ -n "${Set_username_ch}" ]] && echo -e "${Error} 帳號已被使用 !" && exit 1
  sed -i '3i\  },' ${server_conf}
  sed -i '3i\   "region": "'"${region_s}"'"' ${server_conf}
  sed -i '3i\   "disabled": false ,' ${server_conf}
  sed -i '3i\   "location": "'"${location_s}"'",' ${server_conf}
  sed -i '3i\   "host": "'"None"'",' ${server_conf}
  sed -i '3i\   "type": "'"${type_s}"'",' ${server_conf}
  sed -i '3i\   "name": "'"${name_s}"'",' ${server_conf}
  sed -i '3i\   "password": "'"${password_s}"'",' ${server_conf}
  sed -i '3i\   "username": "'"${username_s}"'",' ${server_conf}
  sed -i '3i\  {' ${server_conf}
  echo -e "${Info} 添加節點成功 ${Green_font_prefix}[ 節點名稱: ${name_s}, 節點帳號: ${username_s}, 節點密碼: ${password_s} ]${Font_color_suffix} !"
}
Del_ServerStatus_server() {
  List_ServerStatus_server
  [[ "${conf_text_total}" == "1" ]] && echo -e "${Error} 節點設定只剩 1個，不能刪除 !" && exit 1
  echo -e "請輸入要刪除的節點帳號"
  read -erp "(預設: 取消):" del_server_username
  [[ -z "${del_server_username}" ]] && echo -e "已取消..." && exit 1
  del_username=$(cat -n ${server_conf} | grep '"username": "'"${del_server_username}"'"' | awk '{print $1}')
  if [[ -n ${del_username} ]]; then
    del_username_min=$((del_username - 1))
    del_username_max=$((del_username + 8))
    del_username_max_text=$(sed -n "${del_username_max}p" ${server_conf})
    del_username_max_text_last=${del_username_max_text:((${#del_username_max_text} - 1))}
    if [[ ${del_username_max_text_last} != "," ]]; then
      del_list_num=$((del_username_min - 1))
      sed -i "${del_list_num}s/,$//g" ${server_conf}
    fi
    sed -i "${del_username_min},${del_username_max}d" ${server_conf}
    echo -e "${Info} 節點刪除成功 ${Green_font_prefix}[ 節點帳號: ${del_server_username} ]${Font_color_suffix} "
  else
    echo -e "${Error} 請輸入正確的節點帳號 !" && exit 1
  fi
}
Modify_ServerStatus_server_username() {
  List_ServerStatus_server
  echo -e "請輸入要修改的節點帳號"
  read -erp "(預設: 取消):" manually_username
  [[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
  Set_username_num=$(cat -n ${server_conf} | grep '"username": "'"${manually_username}"'"' | awk '{print $1}')
  if [[ -n ${Set_username_num} ]]; then
    Set_username
    Set_username_ch=$(grep '"username": "'"${username_s}"'"' ${server_conf})
    [[ -n "${Set_username_ch}" ]] && echo -e "${Error} 帳號已被使用 !" && exit 1
    sed -i "${Set_username_num}"'s/"username": "'"${manually_username}"'"/"username": "'"${username_s}"'"/g' ${server_conf}
    echo -e "${Info} 修改成功 [ 原節點帳號: ${manually_username}, 新節點帳號: ${username_s} ]"
  else
    echo -e "${Error} 請輸入正確的節點帳號 !" && exit 1
  fi
}
Modify_ServerStatus_server_password() {
  List_ServerStatus_server
  echo -e "請輸入要修改的節點帳號"
  read -erp "(預設: 取消):" manually_username
  [[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
  Set_username_num=$(cat -n ${server_conf} | grep '"username": "'"${manually_username}"'"' | awk '{print $1}')
  if [[ -n ${Set_username_num} ]]; then
    Set_password
    Set_password_num_a=$((Set_username_num + 1))
    Set_password_num_text=$(sed -n "${Set_password_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_password_num_a}"'s/"password": "'"${Set_password_num_text}"'"/"password": "'"${password_s}"'"/g' ${server_conf}
    echo -e "${Info} 修改成功 [ 原節點密碼: ${Set_password_num_text}, 新節點密碼: ${password_s} ]"
  else
    echo -e "${Error} 請輸入正確的節點帳號 !" && exit 1
  fi
}
Modify_ServerStatus_server_name() {
  List_ServerStatus_server
  echo -e "請輸入要修改的節點帳號"
  read -erp "(預設: 取消):" manually_username
  [[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
  Set_username_num=$(cat -n ${server_conf} | grep '"username": "'"${manually_username}"'"' | awk '{print $1}')
  if [[ -n ${Set_username_num} ]]; then
    Set_name
    Set_name_num_a=$((Set_username_num + 2))
    Set_name_num_a_text=$(sed -n "${Set_name_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_name_num_a}"'s/"name": "'"${Set_name_num_a_text}"'"/"name": "'"${name_s}"'"/g' ${server_conf}
    echo -e "${Info} 修改成功 [ 原節點名稱: ${Set_name_num_a_text}, 新節點名稱: ${name_s} ]"
  else
    echo -e "${Error} 請輸入正確的節點帳號 !" && exit 1
  fi
}
Modify_ServerStatus_server_type() {
  List_ServerStatus_server
  echo -e "請輸入要修改的節點帳號"
  read -erp "(預設: 取消):" manually_username
  [[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
  Set_username_num=$(cat -n ${server_conf} | grep '"username": "'"${manually_username}"'"' | awk '{print $1}')
  if [[ -n ${Set_username_num} ]]; then
    Set_type
    Set_type_num_a=$((Set_username_num + 3))
    Set_type_num_a_text=$(sed -n "${Set_type_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_type_num_a}"'s/"type": "'"${Set_type_num_a_text}"'"/"type": "'"${type_s}"'"/g' ${server_conf}
    echo -e "${Info} 修改成功 [ 原節點虛擬化: ${Set_type_num_a_text}, 新節點虛擬化: ${type_s} ]"
  else
    echo -e "${Error} 請輸入正確的節點帳號 !" && exit 1
  fi
}
Modify_ServerStatus_server_location() {
  List_ServerStatus_server
  echo -e "請輸入要修改的節點帳號"
  read -erp "(預設: 取消):" manually_username
  [[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
  Set_username_num=$(cat -n ${server_conf} | grep '"username": "'"${manually_username}"'"' | awk '{print $1}')
  if [[ -n ${Set_username_num} ]]; then
    Set_location
    Set_location_num_a=$((Set_username_num + 5))
    Set_location_num_a_text=$(sed -n "${Set_location_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_location_num_a}"'s/"location": "'"${Set_location_num_a_text}"'"/"location": "'"${location_s}"'"/g' ${server_conf}
    echo -e "${Info} 修改成功 [ 原節點位置: ${Set_location_num_a_text}, 新節點位置: ${location_s} ]"
  else
    echo -e "${Error} 請輸入正確的節點帳號 !" && exit 1
  fi
}
Modify_ServerStatus_server_region() {
  List_ServerStatus_server
  echo -e "請輸入要修改的節點帳號"
  read -erp "(預設: 取消):" manually_username
  [[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
  Set_username_num=$(cat -n ${server_conf} | grep '"username": "'"${manually_username}"'"' | awk '{print $1}')
  if [[ -n ${Set_username_num} ]]; then
    Set_region
    Set_region_num_a=$((Set_username_num + 7))
    Set_region_num_a_text=$(sed -n "${Set_region_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_region_num_a}"'s/"region": "'"${Set_region_num_a_text}"'"/"region": "'"${region_s}"'"/g' ${server_conf}
    echo -e "${Info} 修改成功 [ 原節點地區: ${Set_region_num_a_text}, 新節點地區: ${region_s} ]"
  else
    echo -e "${Error} 請輸入正確的節點帳號 !" && exit 1
  fi
}
Modify_ServerStatus_server_all() {
  List_ServerStatus_server
  echo -e "請輸入要修改的節點帳號"
  read -erp "(預設: 取消):" manually_username
  [[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
  Set_username_num=$(cat -n ${server_conf} | grep '"username": "'"${manually_username}"'"' | awk '{print $1}')
  if [[ -n ${Set_username_num} ]]; then
    Set_username
    Set_password
    Set_name
    Set_type
    Set_location
    Set_region
    sed -i "${Set_username_num}"'s/"username": "'"${manually_username}"'"/"username": "'"${username_s}"'"/g' ${server_conf}
    Set_password_num_a=$((Set_username_num + 1))
    Set_password_num_text=$(sed -n "${Set_password_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_password_num_a}"'s/"password": "'"${Set_password_num_text}"'"/"password": "'"${password_s}"'"/g' ${server_conf}
    Set_name_num_a=$((Set_username_num + 2))
    Set_name_num_a_text=$(sed -n "${Set_name_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_name_num_a}"'s/"name": "'"${Set_name_num_a_text}"'"/"name": "'"${name_s}"'"/g' ${server_conf}
    Set_type_num_a=$((Set_username_num + 3))
    Set_type_num_a_text=$(sed -n "${Set_type_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_type_num_a}"'s/"type": "'"${Set_type_num_a_text}"'"/"type": "'"${type_s}"'"/g' ${server_conf}
    Set_location_num_a=$((Set_username_num + 5))
    Set_location_num_a_text=$(sed -n "${Set_location_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_location_num_a}"'s/"location": "'"${Set_location_num_a_text}"'"/"location": "'"${location_s}"'"/g' ${server_conf}
    Set_region_num_a=$((Set_username_num + 7))
    Set_region_num_a_text=$(sed -n "${Set_region_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    sed -i "${Set_region_num_a}"'s/"region": "'"${Set_region_num_a_text}"'"/"region": "'"${region_s}"'"/g' ${server_conf}
    echo -e "${Info} 修改成功。"
  else
    echo -e "${Error} 請輸入正確的節點帳號 !" && exit 1
  fi
}
Modify_ServerStatus_server_disabled() {
  List_ServerStatus_server
  echo -e "請輸入要修改的節點帳號"
  read -erp "(預設: 取消):" manually_username
  [[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
  Set_username_num=$(cat -n ${server_conf} | grep '"username": "'"${manually_username}"'"' | awk '{print $1}')
  if [[ -n ${Set_username_num} ]]; then
    Set_disabled_num_a=$((Set_username_num + 6))
    Set_disabled_num_a_text=$(sed -n "${Set_disabled_num_a}p" ${server_conf} | sed 's/\"//g;s/,$//g' | awk -F ": " '{print $2}')
    if [[ ${Set_disabled_num_a_text} == "false" ]]; then
      disabled_s="true"
    else
      disabled_s="false"
    fi
    sed -i "${Set_disabled_num_a}"'s/"disabled": '"${Set_disabled_num_a_text}"'/"disabled": '"${disabled_s}"'/g' ${server_conf}
    echo -e "${Info} 修改成功 [ 原禁用狀態: ${Set_disabled_num_a_text}, 新禁用狀態: ${disabled_s} ]"
  else
    echo -e "${Error} 請輸入正確的節點帳號 !" && exit 1
  fi
}
Set_ServerStatus_client() {
  check_installed_client_status
  Set_config_client
  Read_config_client
  Del_iptables_OUT "${client_port}"
  Modify_config_client
  Add_iptables_OUT "${server_port_s}"
  Restart_ServerStatus_client
}
Install_vnStat() {
  if [[ ${release} == "archlinux" ]]; then
    pacman -Sy vnstat --noconfirm
    systemctl enable vnstat
    systemctl start vnstat
    return 0
  elif [[ ${release} == "centos" ]]; then
    yum -y update
    yum -y install sqlite sqlite-devel
    yum -y groupinstall "Development Tools"
  elif [[ ${release} == "debian" ]]; then
    apt-get -y update
    apt-get -y install sqlite3 libsqlite3-dev build-essential
  fi
  cd "/tmp" || return 1
  wget --no-check-certificate https://humdi.net/vnstat/vnstat-latest.tar.gz
  tar zxvf vnstat-latest.tar.gz
  cd vnstat-*/ || return 1
  ./configure --prefix=/usr --sysconfdir=/etc && make && make install
  if ! vnstat -v >/dev/null 2>&1; then
    echo "編譯安裝vnStat失敗，請手動安裝vnStat"
    exit 1
  fi
  vnstatd -d
  if [[ ${release} == "centos" ]]; then
    if grep "6\..*" /etc/redhat-release | grep -i "centos" | grep -v "{^6}\.6" >/dev/null; then
      [ ! -e /etc/init.d/vnstat ] && cp examples/init.d/redhat/vnstat /etc/init.d/
      chkconfig vnstat on
      service vnstat restart
    fi
  else
    if grep -i "debian" /etc/issue | grep -q "7" || grep -i "ubuntu" /etc/issue | grep -q "14"; then
      [ ! -e /etc/init.d/vnstat ] && cp examples/init.d/debian/vnstat /etc/init.d/
      update-rc.d vnstat defaults
      service vnstat restart
    fi
  fi
  if [ ! -e /etc/init.d/vnstat ]; then
    cp -v examples/systemd/simple/vnstat.service /etc/systemd/system/
    systemctl enable vnstat
    systemctl start vnstat
  fi
  rm -rf vnstat*
  cd ~ || exit
}
Modify_config_client_traffic() {
  [ -z ${isVnstat} ] && [[ ${client_vnstat_s} == "false" ]] && return
  if [[ ${isVnstat="y"} == [Yy] ]]; then
    vnstat -v >/dev/null 2>&1 || Install_vnStat
    netName=$(awk '{i++; if( i>2 && ($2 != 0 && $10 != 0) ){print $1}}' /proc/net/dev | sed 's/^lo:$//g' | sed 's/^tun:$//g' | sed '/^$/d' | sed 's/^[\t]*//g' | sed 's/[:]*$//g')
    if [ -z "$netName" ]; then
      echo -e "取得網卡名稱失敗，請在Github反應"
      exit 1
    fi
    if [[ $netName =~ [[:space:]] ]]; then
      read -erp "偵測到多個網卡: ${netName}，請手動輸入網卡名稱" netName
    fi
    read -erp "請輸入每月流量歸零的日期(1~28)，預設為1(每月1日): " time_N
    [[ -z "$time_N" ]] && time_N="1"
    while ! [[ $time_N =~ ^[0-9]*$ ]] || ((time_N < 1 || time_N > 28)); do
      read -erp "你輸入的日期不合法，請重新輸入: " time_N
    done
    sed -i "s/$(grep -w "MonthRotate" /etc/vnstat.conf)/MonthRotate $time_N/" /etc/vnstat.conf
    sed -i "s/$(grep -w "Interface" /etc/vnstat.conf)/Interface \"$netName\"/" /etc/vnstat.conf
    chmod -R 777 /var/lib/vnstat/
    systemctl restart vnstat
    if ! grep -q "NET_IN, NET_OUT = get_traffic_vnstat()" ${client_file}/status-client.py; then
      sed -i 's/\t/    /g' ${client_file}/status-client.py
      sed -i 's/NET_IN, NET_OUT = traffic.get_traffic()/NET_IN, NET_OUT = get_traffic_vnstat()/' ${client_file}/status-client.py
    fi
  elif grep -q "NET_IN, NET_OUT = get_traffic_vnstat()" ${client_file}/status-client.py; then
    sed -i 's/\t/    /g' ${client_file}/status-client.py
    sed -i 's/NET_IN, NET_OUT = get_traffic_vnstat()/NET_IN, NET_OUT = traffic.get_traffic()/' ${client_file}/status-client.py
  fi
}
Modify_config_client() {
  sed -i 's/SERVER = "'"${client_server}"'"/SERVER = "'"${server_s}"'"/g' "${client_file}/status-client.py"
  sed -i "s/PORT = ${client_port}/PORT = ${server_port_s}/g" "${client_file}/status-client.py"
  sed -i 's/USER = "'"${client_user}"'"/USER = "'"${username_s}"'"/g' "${client_file}/status-client.py"
  sed -i 's/PASSWORD = "'"${client_password}"'"/PASSWORD = "'"${password_s}"'"/g' "${client_file}/status-client.py"
  Modify_config_client_traffic
}
Install_jq() {
  if [[ ! -e ${jq_file} ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" -O ${jq_file}
    else
      wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux32" -O ${jq_file}
    fi
    [[ ! -e ${jq_file} ]] && echo -e "${Error} JQ解析器 下載失敗，請檢查 !" && exit 1
    chmod +x ${jq_file}
    echo -e "${Info} JQ解析器 安裝完成，繼續..."
  else
    echo -e "${Info} JQ解析器 已安裝，繼續..."
  fi
  if [[ ! -e ${region_json} ]]; then
    wget --no-check-certificate "https://raw.githubusercontent.com/michaelwittig/node-i18n-iso-countries/master/langs/zh.json" -O ${region_json}
    [[ ! -e ${region_json} ]] && echo -e "${Error} ISO 3166-1 json文件下載失敗，請檢查！" && exit 1
  fi
}
Install_caddy() {
  echo
  echo -e "${Info} 是否由腳本自動部署HTTP服務(伺服器端的線上監控網站)，如果選擇 N，則請在其他HTTP服務中設定網站根目錄為：${Green_font_prefix}${web_file}${Font_color_suffix} [Y/n]"
  read -erp "(預設: Y 自動部署):" caddy_yn
  [[ -z "$caddy_yn" ]] && caddy_yn="y"
  if [[ "${caddy_yn}" == [Yy] ]]; then
    if [[ ${release} == "archlinux" ]]; then
      pacman -Sy caddy --noconfirm
      systemctl enable caddy
      Set_server "server"
      Set_server_http_port
      cat >>"/etc/caddy/conf.d/Caddyfile" <<-EOF
http://${server_s}:${server_http_port_s} {
  root * ${web_file}
  encode gzip
  file_server
}
EOF
      systemctl restart caddy
      return 0
    fi
    Set_server "server"
    Set_server_http_port
    if [[ ! -e "/usr/local/caddy/caddy" ]]; then
      wget -N --no-check-certificate "${link_prefix}/caddy/caddy_install.sh"
      chmod +x caddy_install.sh
      bash caddy_install.sh install
      rm -rf caddy_install.sh
      [[ ! -e "/usr/local/caddy/caddy" ]] && echo -e "${Error} Caddy安裝失敗，請手動部署，Web網頁文件位置：${web_file}" && exit 1
    else
      echo -e "${Info} 發現Caddy已安裝，開始設定..."
    fi
    if [[ ! -s "/usr/local/caddy/Caddyfile" ]]; then
      cat >"/usr/local/caddy/Caddyfile" <<-EOF
http://${server_s}:${server_http_port_s} {
 root * ${web_file}
 encode gzip
 file_server
}
EOF
      /etc/init.d/caddy restart
    else
      echo -e "${Info} 發現 Caddy 設定文件非空，開始追加 ServerStatus 網站設定內容到文件最後..."
      cat >>"/usr/local/caddy/Caddyfile" <<-EOF
http://${server_s}:${server_http_port_s} {
 root * ${web_file}
 encode gzip
 file_server
}
EOF
      /etc/init.d/caddy restart
    fi
  else
    echo -e "${Info} 跳過 HTTP服務部署，請手動部署，Web網頁文件位置：${web_file} ，如果位置改變，請注意修改服務腳本文件 /etc/init.d/status-server 中的 WEB_BIN 變數 !"
  fi
}
Install_ServerStatus_server() {
  Set_Mirror
  [[ -e "${server_file}/sergate" ]] && echo -e "${Error} 偵測到 ServerStatus 伺服器端已安裝 !" && exit 1
  Set_server_port
  echo -e "${Info} 開始安裝/設定 前置..."
  Installation_dependency "server"
  Install_caddy
  echo -e "${Info} 開始下載/安裝..."
  Download_Server_Status_server
  Install_jq
  echo -e "${Info} 開始下載/安裝 服務腳本(init)..."
  Service_Server_Status_server
  echo -e "${Info} 開始寫入 設定文件..."
  Write_server_config
  Write_server_config_conf
  echo -e "${Info} 開始設定 iptables防火牆..."
  Set_iptables
  echo -e "${Info} 開始添加 iptables防火牆規則..."
  Add_iptables "${server_port_s}"
  [[ -n "${server_http_port_s}" ]] && Add_iptables "${server_http_port_s}"
  echo -e "${Info} 開始保存 iptables防火牆規則..."
  Save_iptables
  echo -e "${Info} 所有步驟 執行完畢，開始啟動..."
  Start_ServerStatus_server
}
Install_ServerStatus_client() {
  Set_Mirror
  [[ -e "${client_file}/status-client.py" ]] && echo -e "${Error} 檢測到 ServerStatus 客戶端已安裝 !" && exit 1
  check_sys
  if [[ ${release} == "centos" ]]; then
    if grep "6\..*" /etc/redhat-release | grep -i "centos" | grep -v "{^6}\.6" >/dev/null; then
      echo -e "${Info} 檢測到你的系統為 CentOS6，該系統內建的 Python2.6 版本過低，會導致無法執行客戶端，如果你有能力升級到 Python2.或以上版本，那麼請繼續(否則建議更換系統)：[y/N]"
      read -erp "(預設: N 繼續安裝):" sys_centos6
      [[ -z "$sys_centos6" ]] && sys_centos6="n"
      if [[ "${sys_centos6}" == [Nn] ]]; then
        echo -e "\n${Info} 已取消...\n"
        exit 1
      fi
    fi
  fi
  echo -e "${Info} 開始設定 用戶設定..."
  Set_config_client
  echo -e "${Info} 開始安裝/設定 前置..."
  Installation_dependency "client"
  echo -e "${Info} 開始下載/安裝..."
  Download_Server_Status_client
  echo -e "${Info} 開始下載/安裝 服務腳本(init)..."
  Service_Server_Status_client
  echo -e "${Info} 開始寫入 設定..."
  Read_config_client
  Modify_config_client
  echo -e "${Info} 開始設定 iptables防火牆..."
  Set_iptables
  echo -e "${Info} 開始添加 iptables防火牆規則..."
  Add_iptables_OUT "${server_port_s}"
  echo -e "${Info} 開始保存 iptables防火牆規則..."
  Save_iptables
  echo -e "${Info} 所有步驟 執行完畢，開始啟動..."
  Start_ServerStatus_client
}
Update_ServerStatus_server() {
  Set_Mirror
  check_installed_server_status
  check_pid_server
  if [[ -n ${PID} ]]; then
    if [[ ${release} == "archlinux" ]]; then
      systemctl stop status-server
    else
      /etc/init.d/status-server stop
    fi
  fi
  Download_Server_Status_server
  rm -rf /etc/init.d/status-server
  Service_Server_Status_server
  Start_ServerStatus_server
}
Update_ServerStatus_client() {
  Set_Mirror
  check_installed_client_status
  check_pid_client
  if [[ -n ${PID} ]]; then
    if [[ ${release} == "archlinux" ]]; then
      systemctl stop status-client
    else
      /etc/init.d/status-client stop
    fi
  fi
  if [[ ! -e "${client_file}/status-client.py" ]]; then
    if [[ ! -e "${file}/status-client.py" ]]; then
      echo -e "${Error} ServerStatus 客戶端文件不存在 !" && exit 1
    else
      client_text="$(sed 's/\"//g;s/,//g;s/ //g' "${file}/status-client.py")"
      rm -rf "${file}/status-client.py"
    fi
  else
    client_text="$(sed 's/\"//g;s/,//g;s/ //g' "${client_file}/status-client.py")"
  fi
  server_s="$(echo -e "${client_text}" | grep "SERVER=" | awk -F "=" '{print $2}')"
  server_port_s="$(echo -e "${client_text}" | grep "PORT=" | awk -F "=" '{print $2}')"
  username_s="$(echo -e "${client_text}" | grep "USER=" | awk -F "=" '{print $2}')"
  password_s="$(echo -e "${client_text}" | grep "PASSWORD=" | awk -F "=" '{print $2}')"
  grep -q "NET_IN, NET_OUT = get_traffic_vnstat()" "${client_file}/status-client.py" && client_vnstat_s="true" || client_vnstat_s="false"
  Download_Server_Status_client
  Read_config_client
  Modify_config_client
  rm -rf /etc/init.d/status-client
  Service_Server_Status_client
  Start_ServerStatus_client
}
Start_ServerStatus_server() {
  check_installed_server_status
  check_pid_server
  [[ -n ${PID} ]] && echo -e "${Error} ServerStatus 正在執行，請檢查 !" && exit 1
  if [[ ${release} == "archlinux" ]]; then
    systemctl start status-server.service
  else
    /etc/init.d/status-server start
  fi
}
Stop_ServerStatus_server() {
  check_installed_server_status
  check_pid_server
  [[ -z ${PID} ]] && echo -e "${Error} ServerStatus 沒有執行，請檢查 !" && exit 1
  if [[ ${release} == "archlinux" ]]; then
    systemctl stop status-server.service
  else
    /etc/init.d/status-server stop
  fi
}
Restart_ServerStatus_server() {
  check_installed_server_status
  check_pid_server
  if [[ -z ${PID} ]]; then
    if [[ ${release} == "archlinux" ]]; then
      systemctl stop status-server.service
    else
      /etc/init.d/status-server stop
    fi
  fi
  if [[ ${release} == "archlinux" ]]; then
    systemctl start status-server.service
  else
    /etc/init.d/status-server start
  fi
}
Uninstall_ServerStatus_server() {
  check_installed_server_status
  echo "確定要移除 ServerStatus 伺服器端(如果同時安裝了客戶端，則只會刪除伺服器端) ? [y/N]"
  echo
  read -erp "(預設: n):" unyn
  [[ -z ${unyn} ]] && unyn="n"
  if [[ ${unyn} == [Yy] ]]; then
    check_pid_server
    [[ -n $PID ]] && kill -9 "${PID}"
    Read_config_server
    Del_iptables "${server_port}"
    Save_iptables
    if [[ -e "${client_file}/status-client.py" ]]; then
      rm -rf "${server_file}"
      rm -rf "${web_file}"
    else
      rm -rf "${file}"
    fi
    rm -rf "/etc/init.d/status-server"
    if [[ -e "/etc/init.d/caddy" ]]; then
      if [[ ${release} == "archlinux" ]]; then
        systemctl stop caddy
        systemctl disable caddy
        pacman -R caddy --noconfirm
      else
        /etc/init.d/caddy stop
        wget -N --no-check-certificate "${link_prefix}/caddy/caddy_install.sh"
        chmod +x caddy_install.sh
        bash caddy_install.sh uninstall
        rm -rf caddy_install.sh
      fi
    fi
    if [[ ${release} == "centos" ]]; then
      chkconfig --del status-server
    elif [[ ${release} == "debian" ]]; then
      update-rc.d -f status-server remove
    elif [[ ${release} == "archlinux" ]]; then
      systemctl stop status-server
      systemctl disable status-server
      rm /usr/lib/systemd/system/status-server.service
    fi
    echo && echo "ServerStatus 移除完成 !" && echo
  else
    echo && echo "移除已取消..." && echo
  fi
}
Start_ServerStatus_client() {
  check_installed_client_status
  check_pid_client
  [[ -n ${PID} ]] && echo -e "${Error} ServerStatus 正在執行，請檢查 !" && exit 1
  if [[ ${release} == "archlinux" ]]; then
    systemctl start status-client.service
  else
    /etc/init.d/status-client start
  fi
}
Stop_ServerStatus_client() {
  check_installed_client_status
  check_pid_client
  [[ -z ${PID} ]] && echo -e "${Error} ServerStatus 沒有執行，請檢查 !" && exit 1
  if [[ ${release} == "archlinux" ]]; then
    systemctl stop status-client.service
  else
    /etc/init.d/status-client stop
  fi
}
Restart_ServerStatus_client() {
  check_installed_client_status
  check_pid_client
  if [[ -n ${PID} ]]; then
    if [[ ${release} == "archlinux" ]]; then
      systemctl restart status-client.service
    else
      /etc/init.d/status-client restart
    fi
  fi
}
Uninstall_ServerStatus_client() {
  check_installed_client_status
  echo "確定要移除 ServerStatus 客戶端(伺服器端，則只會刪除客戶端) ? [y/N]"
  echo
  read -erp "(預設: n):" unyn
  [[ -z ${unyn} ]] && unyn="n"
  if [[ ${unyn} == [Yy] ]]; then
    check_pid_client
    [[ -n $PID ]] && kill -9 "${PID}"
    Read_config_client
    Del_iptables_OUT "${client_port}"
    Save_iptables
    if [[ -e "${server_file}/sergate" ]]; then
      rm -rf "${client_file}"
    else
      rm -rf "${file}"
    fi
    rm -rf /etc/init.d/status-client
    if [[ ${release} == "centos" ]]; then
      chkconfig --del status-client
    elif [[ ${release} == "debian" ]]; then
      update-rc.d -f status-client remove
    elif [[ ${release} == "archlinux" ]]; then
      systemctl stop status-client
      systemctl disable status-client
      rm /usr/lib/systemd/system/status-client.service
    fi
    echo && echo "ServerStatus 移除完成 !" && echo
  else
    echo && echo "移除已取消..." && echo
  fi
}
View_ServerStatus_client() {
  check_installed_client_status
  Read_config_client
  clear && echo "————————————————————" && echo
  echo -e "  ServerStatus 客戶端設定內容：

  IP \t: ${Green_font_prefix}${client_server}${Font_color_suffix}
  連接埠 \t: ${Green_font_prefix}${client_port}${Font_color_suffix}
  帳號 \t: ${Green_font_prefix}${client_user}${Font_color_suffix}
  密碼 \t: ${Green_font_prefix}${client_password}${Font_color_suffix}
  vnStat : ${Green_font_prefix}${client_vnstat}${Font_color_suffix}

————————————————————"
}
View_client_Log() {
  [[ ! -e ${client_log_file} ]] && echo -e "${Error} 沒有找到紀錄文件 !" && exit 1
  echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 終止查看紀錄" && echo -e "如果需要查看完整記錄內容，請用 ${Red_font_prefix}cat ${client_log_file}${Font_color_suffix} 命令。" && echo
  tail -f ${client_log_file}
}
View_server_Log() {
  [[ ! -e ${server_log_file} ]] && echo -e "${Error} 沒有找到紀錄文件 !" && exit 1
  echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 終止查看紀錄" && echo -e "如果需要查看完整記錄內容，請用 ${Red_font_prefix}cat ${server_log_file}${Font_color_suffix} 命令。" && echo
  tail -f ${server_log_file}
}
Add_iptables_OUT() {
  iptables_ADD_OUT_port=$1
  iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport "${iptables_ADD_OUT_port}" -j ACCEPT
  iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport "${iptables_ADD_OUT_port}" -j ACCEPT
}
Del_iptables_OUT() {
  iptables_DEL_OUT_port=$1
  iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport "${iptables_DEL_OUT_port}" -j ACCEPT
  iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport "${iptables_DEL_OUT_port}" -j ACCEPT
}
Add_iptables() {
  iptables_ADD_IN_port=$1
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${iptables_ADD_IN_port}" -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport "${iptables_ADD_IN_port}" -j ACCEPT
}
Del_iptables() {
  iptables_DEL_IN_port=$1
  iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport "${iptables_DEL_IN_port}" -j ACCEPT
  iptables -D INPUT -m state --state NEW -m udp -p udp --dport "${iptables_DEL_IN_port}" -j ACCEPT
}
Save_iptables() {
  if [[ ${release} == "centos" ]]; then
    service iptables save
  else
    iptables-save >/etc/iptables.up.rules
  fi
}
Set_iptables() {
  if [[ ${release} == "centos" ]]; then
    service iptables save
    chkconfig --level 2345 iptables on
  else
    iptables-save >/etc/iptables.up.rules
    echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' >/etc/network/if-pre-up.d/iptables
    chmod +x /etc/network/if-pre-up.d/iptables
  fi
}
Update_Shell() {
  Set_Mirror
  sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "${link_prefix}/status.sh" | grep 'sh_ver="' | awk -F "=" '{print $NF}' | sed 's/\"//g' | head -1)
  [[ -z ${sh_new_ver} ]] && echo -e "${Error} 無法連接到 Github !" && exit 0
  if [[ -e "/etc/init.d/status-client" ]]; then
    rm -rf /etc/init.d/status-client
    Service_Server_Status_client
  fi
  if [[ -e "/etc/init.d/status-server" ]]; then
    rm -rf /etc/init.d/status-server
    Service_Server_Status_server
  fi
  wget -N --no-check-certificate "${link_prefix}/status.sh" && chmod +x status.sh
  echo -e "腳本已更新到[ ${sh_new_ver} ] !(注意：應為更新腳本的方式為直接覆蓋執行中的檔案，所以可能下面會報錯，無視即可)" && exit 0
}
menu_client() {
  echo && echo -e "  ServerStatus 一鍵安裝管理腳本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc3 --
  --    Modified by APTX    --
 ${Green_font_prefix} 0.${Font_color_suffix} 升級腳本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安裝 客戶端
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 客戶端
 ${Green_font_prefix} 3.${Font_color_suffix} 移除 客戶端
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 啟動 客戶端
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 客戶端
 ${Green_font_prefix} 6.${Font_color_suffix} 重啟 客戶端
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 設定 客戶端設定
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 客戶端訊息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 客戶端紀錄
————————————
 ${Green_font_prefix}10.${Font_color_suffix} 切換為 伺服器端目錄" && echo
  if [[ -e "${client_file}/status-client.py" ]]; then
    check_pid_client
    if [[ -n "${PID}" ]]; then
      echo -e " 當前狀態: 客戶端 ${Green_font_prefix}已安裝${Font_color_suffix} 並 ${Green_font_prefix}已啟動${Font_color_suffix}"
    else
      echo -e " 當前狀態: 客戶端 ${Green_font_prefix}已安裝${Font_color_suffix} 但 ${Red_font_prefix}未啟動${Font_color_suffix}"
    fi
  else
    if [[ -e "${file}/status-client.py" ]]; then
      check_pid_client
      if [[ -n "${PID}" ]]; then
        echo -e " 當前狀態: 客戶端 ${Green_font_prefix}已安裝${Font_color_suffix} 並 ${Green_font_prefix}已啟動${Font_color_suffix}"
      else
        echo -e " 當前狀態: 客戶端 ${Green_font_prefix}已安裝${Font_color_suffix} 但 ${Red_font_prefix}未啟動${Font_color_suffix}"
      fi
    else
      echo -e " 當前狀態: 客戶端 ${Red_font_prefix}未安裝${Font_color_suffix}"
    fi
  fi
  echo
  read -erp " 請輸入數字 [0-10]:" num
  case "$num" in
  0)
    Update_Shell
    ;;
  1)
    Install_ServerStatus_client
    ;;
  2)
    Update_ServerStatus_client
    ;;
  3)
    Uninstall_ServerStatus_client
    ;;
  4)
    Start_ServerStatus_client
    ;;
  5)
    Stop_ServerStatus_client
    ;;
  6)
    Restart_ServerStatus_client
    ;;
  7)
    Set_ServerStatus_client
    ;;
  8)
    View_ServerStatus_client
    ;;
  9)
    View_client_Log
    ;;
  10)
    menu_server
    ;;
  *)
    echo "請輸入正確的數字 [0-10]"
    ;;
  esac
}
menu_server() {
  echo && echo -e "  ServerStatus 一鍵安裝管理腳本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc3 --
  --    Modified by APTX    --
 ${Green_font_prefix} 0.${Font_color_suffix} 升級腳本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安裝 伺服器端
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 伺服器端
 ${Green_font_prefix} 3.${Font_color_suffix} 移除 伺服器端
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 啟動 伺服器端
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 伺服器端
 ${Green_font_prefix} 6.${Font_color_suffix} 重啟 伺服器端
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 設定 伺服器端設定
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 伺服器端訊息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 伺服器端設定
————————————
 ${Green_font_prefix}10.${Font_color_suffix} 切換為 客戶端目錄" && echo
  if [[ -e "${server_file}/sergate" ]]; then
    check_pid_server
    if [[ -n "${PID}" ]]; then
      echo -e " 當前狀態: 伺服器端 ${Green_font_prefix}已安裝${Font_color_suffix} 並 ${Green_font_prefix}已啟動${Font_color_suffix}"
    else
      echo -e " 當前狀態: 伺服器端 ${Green_font_prefix}已安裝${Font_color_suffix} 但 ${Red_font_prefix}未啟動${Font_color_suffix}"
    fi
  else
    echo -e " 當前狀態: 伺服器端 ${Red_font_prefix}未安裝${Font_color_suffix}"
  fi
  echo
  read -erp " 請輸入數字 [0-10]:" num
  case "$num" in
  0)
    Update_Shell
    ;;
  1)
    Install_ServerStatus_server
    ;;
  2)
    Update_ServerStatus_server
    ;;
  3)
    Uninstall_ServerStatus_server
    ;;
  4)
    Start_ServerStatus_server
    ;;
  5)
    Stop_ServerStatus_server
    ;;
  6)
    Restart_ServerStatus_server
    ;;
  7)
    Set_ServerStatus_server
    ;;
  8)
    List_ServerStatus_server
    ;;
  9)
    View_server_Log
    ;;
  10)
    menu_client
    ;;
  *)
    echo "請輸入正確的數字 [0-10]"
    ;;
  esac
}
Set_Mirror() {
  echo -e "${Info} 請輸入要選擇的下載源，預設使用Github，中國大陸建議選擇Coding.net，但是不建議將伺服器端部署在中國大陸主機上
  ${Green_font_prefix} 1.${Font_color_suffix} GitHub
  ${Green_font_prefix} 2.${Font_color_suffix} Coding.net (伺服器端安裝並非全部使用Coding.net倉庫)"
  read -erp "請輸入數字 [1-2], 預設為 1:" mirror_num
  [[ -z "${mirror_num}" ]] && mirror_num=1
  [[ ${mirror_num} == 2 ]] && link_prefix=${coding_prefix} || link_prefix=${github_prefix}
}
check_sys
action=$1
if [[ -n $action ]]; then
  if [[ $action == "s" ]]; then
    menu_server
  elif [[ $action == "c" ]]; then
    menu_client
  fi
else
  menu_client
fi
