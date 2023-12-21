
<p align="center">
    <img src="https://raw.githubusercontent.com/armbian/build/main/.github/armbian-logo.png" alt="Armbian logo" width="144">
    <br>
    Armbian ConfigNG 
    <br>
    <a href="https://www.codefactor.io/repository/github/tearran/configng"><img src="https://www.codefactor.io/repository/github/tearran/configng/badge" alt="CodeFactor" /></a>
</p>

# User guide
## Quick start

### Git dev
~~~
sudo apt install git
cd ~/
git clone https://github.com/armbian/configng.git
cd configng
./bin/armbian-configng --dev
~~~

### Up Comming Apt.
~~~
Run the following commands:

    echo "deb [signed-by=/usr/share/keyrings/armbian.gpg] https://armbian.github.io/configng stable main" \
    | sudo tee /etc/apt/sources.list.d/armbian-development.list > /dev/null
    
    armbian-configng --dev

If all goes well you should see the Text-Based User Inerface (TUI)

### To see a list of all functions and their descriptions, run the following command:
~~~
armbian-configng -h
~~~
## Coding Style
follow the following coding style:
~~~
# @description A short description of the function.
#
# @exitcode 0  If successful.
#
# @options A description if there are options.
function group::string() {s
    echo "hello world"
    return 0
}
~~~
