# HTB Setup Script
This script automates some common steps when starting to hack a machine on HackTheBox. It has what I consider to be some neat features but some of them require some preparation beforehand in order to work. I'll be diving into all that below.

# ❗️ Requirements
- [Z Shell](https://gist.github.com/derhuerst/12a1558a4b408b3b2b6e#file-intro-md) (zsh)
  - This is a zsh script, not a bash script. Hence the `#!/bin/zsh` as the first line.
- [openvpn](https://www.ovpn.com/en/guides/debian)<sup>*</sup> [^1]
- [wmctrl](https://github.com/saravanabalagi/wmctrl)<sup>*</sup> [^1]
- [gnome-terminal](https://gitlab.gnome.org/GNOME/gnome-terminal)<sup>*</sup> [^1]
- [firefox](https://www.geeksforgeeks.org/how-to-launch-firefox-from-linux-terminal/)<sup>*</sup> [^2]
- [jq](https://jqlang.github.io/jq/download/)<sup>*</sup> [^3]

<sup>*</sup> = optional.
[^1]: Required if you want to use `-c` flag in order to connect to HTB using your .ovpn file.
[^2]: Required if you want to use `-w` flag in order to search for a writeup online.
[^3]: Required if you want to use `-a` flag in order to request data from HTB's APIs.

# ⚙️ Install and Use
## ＃ Installation
```shell
user@host:~$ git clone https://github.com/Croluy/HTB-Setup-Script.git
user@host:~$ cd HTB-Setup-Script
user@host:~$ sudo chmod +x setup-lab.sh
user@host:~$ 
```
> [!TIP]
> After you install the script I suggest you to run it with the `-s` flag in order to set up some ENV variables that will be used by the script.
## 💻 How to run
There are multiple ways to run the script. Here are some:
```shell
user@host:~$ /bin/zsh setup-lab.sh #Option 1
user@host:~$ zsh setup-lab.sh #Option 2
user@host:~$ ./setup-lab.sh #Option 3: Only if your shell is zsh
user@host:~$ htb-setup # Option 4: Only if you added the script as an alias as suggested when executing -s
user@host:~$
```
> [!WARNING]
> At the moment this script can **not** be run as a bash script. This means that it will **not** work when you execute it with `sh` or `bash`.<br>
> I do not plan on making it bash compatible anytime soon. If you want to make it a bash script feel free to fork the repo, tweak the script and open a pull request.
> In which case I will most likely add that as a bash alternative, not a substitute of this one.

## 📚 Manual
```console
Usage: htb-setup [OPTIONS]

This script automates some of the most common steps when starting to hack a machine on HackTheBox.
The script can:
- create a directory with the same name as the box you're hacking in the designed path;
- create a backup of your /etc/hosts file in case you want to preserve its content before the script changes it;
- add the ip address and host name inside /etc/hosts;
- open a Firefox tab with the google search query about a writeup of the box;
- do a ping test to verify if the box is reachable;
- execute a basic nmap scan on the box and print it;
- get some basic infos about the active machine (after you've spawned it from HTB's website);
- connect to HTB's virtual private network;
When executing the script you will be asked for admin password because some commands require sudo permission.

OPTIONS:
  -a, --api                       Do API requests to HTB in order to get more infos about the box. Requires HTB_API_TOKEN as environment variable.
  -b, --box-name <box_name>       Specify the name of the box.
  -c, --connect                   Connect to HTB's virtual private netowrk using the .ovpn file. Requires HTB_VPN_PATH as environment variable.
  -e, --env                       Print the environment variables that can be used by this script.
  -h, --help                      Display this help message.
  -ip, --ip-address <box_ip>      Specify the IP address of the box.
  -n, --nmap                      Start an nmap scan (nmap -nC -sV -p- host).
  -s, --setup                     Setup your environment variables and alias.
  -v, --verbose                   Enable verbose mode (show all messages).
  -w, --writeup                   Open Firefox and search for a writeup of the box.
  -y,                             Accept all requests automatically.

Examples:
htb-setup -b Box1 -ip 10.10.129.23 -a
htb-setup -b Box2 -v -y                                                                                                                             
htb-setup -b Box3 -ip 10.10.10.45 -n
htb-setup -c
htb-setup -b Box4 -w

Source code available on Github at: https://github.com/Croluy/HTB-Initial-Script
```

# 📄 Examples
- htb-setup -b Box1 -ip 10.10.129.23 -a
  - Create Box1 folder, add the entry to /etc/hosts with the ip address 10.10.129.23 and get some infos about the box.
- htb-setup -b Box2 -v -y
  - Create Box2 folder, get verbose output, automatically accept (y) to all prompts where a choice is due.
- htb-setup -b Box3 -ip 10.10.10.45 -n
  - Create Box3 folder, add the entry to /etc/hosts with the ip address 10.10.129.23 and do a quick nmap scan on the box.
- htb-setup -c
  - Connect to HTB vpn using the .ovpn file
- htb-setup -b Box4 -w
  - Create Box4 folder, open a firefox instance with the search query "Box4 htb writeup"

# ✏️ Backstory
I've been using [HackTheBox](https://app.hackthebox.com) for a while now and I've noticed whenever I start working on machines I keep on repeating some stuff over and over again. That's why I've decided to take some time to automate the steps that I find myself doing so often whenever I prepare myself to hack a box. Also it was a great opportunity to challenge myself in creating a zsh script, since it's something quite new to me.<br>
At the beginning it was meant to be a small script just for myself, but one day a friend said something like "_I'll code a script for when I'm starting a HTB machine_". This was my confirmation that what I had might be useful to others too. So I've started to make it more generic since until then it was tailored exactly for myself.<br>
The more I was coding the more ideas were coming to my mind of possible features to add (as it often happens 👀). So what I initially thought would only be a small script, became something larger than I anticipated with API requests directly to HTB and other useful stuff.<br>
Now I've decided to make it publicly available on GitHub and I'll keep working on it whenever I have time and new ideas, aiming to make it as good as possible. If you want, feel free to fork this repo, experiment with the script and maybe even consider opening a pull request whenever you add some cool new feature.

> [!NOTE]
> 🌟 Created and maintained by [Croluy](https://github.com/Croluy)
