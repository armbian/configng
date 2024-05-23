# Wiptail
## usage
### Ok message box
<img width="639" alt="image" src="https://github.com/armbian/configng/assets/2831630/41f8c16f-dde3-4e7d-8b51-e835f9c7246a">


the following will output the boot up time 
```bash 
 systemd-analyze | show_message
```
<img width="639" alt="image" src="https://github.com/armbian/configng/assets/2831630/84d2a613-8036-4901-af1f-bf4231527285">

### Menu selection box
```bash 
apt-cache search desktop | grep -i -e "\-desktop-full " -e "\-desktop-environment " | awk -F "- " '{print $1, $2}' | show_menu
```
(WIP)