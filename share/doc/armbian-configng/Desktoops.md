You can install different desktop environments on a standard Armbian image. Here are the steps to do it:

1. **Setting up Display Manager**: First, you need a Display Manager. NODM is installed by default. [If you have problems with NODM, you can try LXDM](https://forum.armbian.com/topic/10526-using-different-desktop-environments-on-armbian/)¹.
    ```
    sudo apt install lxdm
    sudo apt remove nodm
    sudo dpkg-reconfigure lxdm
    ```
2. **Install LXDE Desktop**: Next, install the desktop environment you want. It's easiest to install LXDM first to be able to configure the others well¹.
    ```
    sudo apt install lxde
    sudo reboot
    ```
3. **Fixing Login Issues**: If you're having trouble logging in to some Desktop Environments with LXDM, you can fix this by modifying the file `/usr/share/xsessions/xfce.desktop`¹.
    ```
    sudo geany /usr/share/xsessions/xfce.desktop
    ```
   Replace `Name=Xfce Session` with `Name=Xfce-Session` and save the file¹.

4. **Installing Different Desktop Environments**: You can install different desktop environments like Mate, KDE-Plasma, and Gnome¹. For example, to install Mate:
    ```
    sudo apt install mate-desktop-environment mate-applets
    ```

5. **Removing a Desktop Environment**: If you want to remove a desktop environment, you can do so by using the `remove` command¹.
    ```
    sudo apt remove mate-desktop-environment
    ```

Source: 
- https://forum.armbian.com/topic/10526-using-different-desktop-environments-on-armbian/ 
- https://raspberrytips.com/armbian-on-raspberry-pi/.
- https://docs.armbian.com/User-Guide_Getting-Started/
