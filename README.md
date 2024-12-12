# Armbian config package repository
Run the following commands in your terminal:

```bash
echo "deb [signed-by=/usr/share/keyrings/armbian.gpg] https://github.armbian.com/configng stable main" | sudo tee /etc/apt/sources.list.d/armbian-development.list > /dev/null
sudo apt update
sudo apt -y install armbian-config
```
