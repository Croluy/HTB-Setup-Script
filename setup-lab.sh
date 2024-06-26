#!/bin/zsh

# Font Colors
RED='\033[0;31m';
GREEN='\033[0;32m';
BLUE='\033[0;34m';
DC='\033[0m'; # Default Color

#UNICODE SPECIAL CHARS
TICK='\xE2\x9C\x93';
LOAD='\xE2\xA4\xBF';

# Request user password at the beginning of the script
sudo -v

# Check if the entered password is correct
if [ $? -ne 0 ]; then
    echo "${RED}ERROR:${DC} Incorrect password. Exiting the script."
    return 1
fi

# Function to display the manual
print_manual() {
	echo "Usage: ${BLUE}htb-setup [OPTIONS]${DC}"
    echo "\nThis script automates some of the most common steps when starting to hack a machine on HackTheBox."
    echo "The script can:"
    echo "- create a directory with the same name as the box you're hacking in the designed path;"
    echo "- create a backup of your /etc/hosts file in case you want to preserve its content before the script changes it;"
    echo "- add the ip address and host name inside /etc/hosts;"
    echo "- open a Firefox tab with the google search query about a writeup of the box;"
    echo "- do a ping test to verify if the box is reachable;"
    echo "- execute a basic nmap scan on the box and print it;"
    echo "- get some basic infos about the active machine (after you've spawned it from HTB's website);"
    echo "- connect to HTB's virtual private network;"
    echo "When executing the script you will be asked for admin password because some commands require sudo permission.\n"
    echo "OPTIONS:"
    echo "  -a, --api                       Do API requests to HTB in order to get more infos about the box. Requires ${BLUE}HTB_API_TOKEN${DC} as environment variable."
    echo "  -b, --box-name <box_name>       Specify the name of the box."
    echo "  -c, --connect                   Connect to HTB's virtual private netowrk using the .ovpn file. Requires ${BLUE}HTB_VPN_PATH${DC} as environment variable."
    echo "  -e, --env                       Print the environment variables that can be used by this script."
    echo "  -h, --help                      Display this help message."
    echo "  -ip, --ip-address <box_ip>      Specify the IP address of the box."
    echo "  -n, --nmap                      Start an nmap scan (${BLUE}nmap -nC -sV -p- host${DC})."
    echo "  -s, --setup                     Setup your environment variables and alias."
    echo "  -v, --verbose                   Enable verbose mode (show all messages)."
    echo "  -w, --writeup                   Open Firefox and search for a writeup of the box."
    echo "  -y,                             Accept all requests automatically."
    echo "\nExamples:\n${BLUE}htb-setup -b Box1 -ip 10.10.129.23 -a"
    echo "htb-setup -b Box2 -v -y     "
    echo "htb-setup -b Box3 -ip 10.10.10.45 -n" 
    echo "htb-setup -c"
    echo "htb-setup -b Box4 -w${DC}"
    echo "\nSource code available on Github at: https://github.com/Croluy/HTB-Setup-Script"
}

# Initialize variables
box_name=""
box_ip=""
lowercase_box_name=""
verbose=false
nmap=false
api=false
writeup=false
shell_name="${SHELL##*/}"
vpn=false
auto_yes=false
show_env=false
setup=false
has_to_end=false

# Parsing command-line arguments with flags
while [ "$#" -gt 0 ]; do
    case $1 in
    -a || --api)
        api=true
        ;;
    -b || --box-name)
        box_name=$2
        lowercase_box_name=$(echo "$box_name" | tr '[:upper:]' '[:lower:]')
        shift
        ;;
    -c || --connect)
        vpn=true
        ;;
    -e || --env)
        show_env=true
        ;;
    -h || --help)
        print_manual
        return 0
        ;;
    -ip || --ip-address)
        box_ip=$2
        shift
        ;;
    -n || --nmap)
        nmap=true
        ;;
    -s || --setup)
        setup=true
        ;;
    -v || --verbose)
        verbose=true
        ;;
    -w || --writeup)
        writeup=true
        ;;
    -y)
        auto_yes=true
        ;;
    *)
        echo "${RED}ERROR:${DC} Unknown option: $1"
        echo "-------------------------"
        print_manual
        return 1
        ;;
    esac
    shift
done

if [ ! -d $1 ]; then
    echo "This script needs at least an option, if you don't know which one to choose take a look at ${BLUE}htb-setup -h${DC}"
    return 1
fi

# Function to display messages based on the verbose flag
print_msg() {
    if [ "$verbose" = true ]; then
        echo "$1"
    fi
}

# If user used -c flag connect to vpn
if [ "$vpn" = true ]; then
    # Check if openvpn is installed
    print_msg "Checking if openvpn is installed."
    if ! command -v openvpn &>/dev/null; then
        echo "${RED}ERROR: ${DC}OpenVPN is not installed."
        echo "Please install it with ${BLUE}sudo apt install openvpn${DC} and retry."
        return 1
    fi

    # Check if wmctrl is installed
    print_msg "Checking if wmctrl is installed."
    if ! command -v wmctrl &>/dev/null; then
        echo "${RED}ERROR: ${DC}wmctrl is not installed."
        echo "Please install it with ${BLUE}sudo apt install wmctrl${DC} and retry."
        return 1
    fi

    # Check if gnome-terminal is installed
    print_msg "Checking if gnome-terminal is installed."
    if ! command -v gnome-terminal &>/dev/null; then
        echo "${RED}ERROR: ${DC}gnome-terminal is not installed."
        echo "Please install it with ${BLUE}sudo apt install gnome-terminal${DC} and retry."
        return 1
    fi

    # Check if variabile HTB_VPN_PATH is defined
    print_msg "Checking if environment variable HTB_VPN_PATH is set."
    if [[ ! -v HTB_VPN_PATH ]]; then
        echo "${RED}ERROR: ${DC} HTB_VPN_PATH is not defined."
        echo "Please set the variabile HTB_VPN_PATH with the path to the .ovpn file downloaded from HackTheBox.\nYou can find out how to do it below."
        if [ "$shell_name" = "bash" ]; then
            echo "Execute ${BLUE}echo \"export HTB_VPN_PATH=${GREEN}/...EDIT THE PATH.../lab_user.ovpn${BLUE}\" >> ~/.bashrc && source ~/.bashrc${DC} and retry."
        elif [ "$shell_name" = "zsh" ]; then
            echo "Execute ${BLUE}echo \"export HTB_VPN_PATH=${GREEN}/...EDIT THE PATH.../lab_user.ovpn${BLUE}\" >> ~/.zshrc && source ~/.zshrc${DC} and retry."
        else
            # User has a different shell
            echo "Execute the command ${BLUE}export HTB_VPN_PATH=\"${GREEN}/...EDIT THE PATH.../lab_user.ovpn${BLUE}\"${DC} and retry."
        fi
        return 1
    fi

    # Check if .ovpn file exists
    print_msg "Checking if path to .ovpn file is correct."
    if [[ -f "$HTB_VPN_PATH" ]]; then
        # Start a new terminal and run openvpn
        print_msg "Starting a new terminal window to connect to HTB's VPN."
        gnome-terminal -- sudo openvpn "$HTB_VPN_PATH" &>/dev/null
        sleep 1

        # Get back to the original terminal window
        print_msg "Going back to the main terminal window."
        wmctrl -a "Terminal"
    else
        echo "${RED}ERROR: ${DC}Path to file .ovpn is wrong.\nYour path is $HTB_VPN_PATH"
        echo "Make sure the path to the file is correct, remember that the path assigned to HTB_VPN_PATH has to end with the file name."
    fi

    # Wait 8 sec, so user has time to input the password in the new terminal
    # Otherwise the ping will result in packet loss
    print_msg "Waiting 8 seconds for you to insert your password in the new terminal in order to connect to HTB's VPN."
    sleep 8
fi

# If user used -e flag print the env variables
if [ "$show_env" = true ]; then
    echo "${BLUE}HTB_API_TOKEN${DC} =\t" $HTB_API_TOKEN
    echo "${BLUE}HTB_VPN_PATH${DC} =\t" $HTB_VPN_PATH
    echo "${BLUE}HTB_LAB_PATH${DC} =\t" $HTB_LAB_PATH
fi

if [ "$setup" = true ]; then
    something_to_set=false

    # Check if variabile HTB_VPN_PATH is defined
    print_msg "Checking if environment variable HTB_VPN_PATH is set."
    if [[ ! -v HTB_VPN_PATH ]]; then
        something_to_set=true
        echo "\n${GREEN}WARNING: ${DC} HTB_VPN_PATH is not defined."
        echo "Please set the variabile HTB_VPN_PATH with the path to the .ovpn file downloaded from HackTheBox."
        if [ "$shell_name" = "zsh" ]; then
            echo "Suggested command: ${BLUE}echo \"export HTB_VPN_PATH=${GREEN}/...EDIT THE PATH.../lab_user.ovpn${BLUE}\" >> ~/.zshrc && source ~/.zshrc${DC}"
        else
            # User has a different shell
            echo "Suggested command: ${BLUE}export HTB_VPN_PATH=\"${GREEN}/...EDIT THE PATH.../lab_user.ovpn${BLUE}\"${DC}"
        fi
    fi

    # Check if variabile HTB_LAB_PATH is defined
    print_msg "Checking if environment variable HTB_LAB_PATH is set."
    if [[ ! -v HTB_LAB_PATH ]]; then
        something_to_set=true
        echo "\n${GREEN}WARNING: ${DC} HTB_LAB_PATH is not defined."
        echo "Please set the variabile HTB_LAB_PATH with the path to the directory where the script will create all the box folders."
        if [ "$shell_name" = "zsh" ]; then
            echo "Suggested command: ${BLUE}echo \"export HTB_LAB_PATH=${GREEN}/...EDIT THE PATH.../${BLUE}\" >> ~/.zshrc && source ~/.zshrc${DC}"
        else
            # User has a different shell
            echo "Suggested command: ${BLUE}export HTB_LAB_PATH=\"${GREEN}/...EDIT THE PATH.../lab_user.ovpn${BLUE}\"${DC}"
        fi
    fi

    # Check if variabile HTB_API_TOKEN is defined
    print_msg "Checking if environment variable HTB_API_TOKEN is set."
    if [[ ! -v HTB_API_TOKEN ]]; then
        something_to_set=true
        echo "\n${GREEN}WARNING: ${DC}Your HTB token is not set, you have to set it as an ENV variable in order to get infos from HTB APIs."
        echo "Follow these steps to set your HTB token:"
        echo "1. Go to https://app.hackthebox.com/ and log in"
        echo "2. Click on your user profile (top right of the website)"
        echo "3. Select 'Account Settings’"
        echo "4. Find the 'App Tokens' menu (right side)"
        echo "5. Click on 'Create App Token’"
        echo "6. Give that token a name and set the expiration time"
        echo "7. Copy the token to your clipboard"
        if [ "$shell_name" = "zsh" ]; then
            echo "8. Suggested command: ${BLUE}echo \"export HTB_API_TOKEN=${GREEN}token_here${BLUE}\" >> ~/.zshrc && source ~/.zshrc${DC}"
        else
            # User has a different shell
            echo "8. Suggested command: ${BLUE}export HTB_API_TOKEN=\"${GREEN}token_here${BLUE}\"${DC}"
        fi
    fi

    # Check if the alias has been set
    if ! alias | grep -q "htb-setup"; then
        something_to_set=true
        echo "\n${GREEN}WARNING: ${DC}You have not set your alias for this script. If you do so it will be easier to run it."
        if [ "$shell_name" = "zsh" ]; then
            echo "Suggested command: ${BLUE}echo \"alias htb-setup=${GREEN}/...EDIT THE PATH.../setup-lab.sh${BLUE}\" >> ~/.zshrc && source ~/.zshrc${DC}"
        else
            # User has a different shell
            echo "Suggested command: ${BLUE}alias htb-setup=\"${GREEN}/...EDIT THE PATH.../setup-lab.sh${BLUE}\"${DC}"
        fi
    fi

    # If everything is set, communicate that to user
    if [ "$something_to_set" = false ]; then
        echo "Alias set.\nAll the environment variables are set. If you want to see them use the -e flag."
    fi
fi

# User has used flags that require box name
if [ -d "$box_ip" ] || [ "$api" = true ] || [ "$nmap" = true ] || [ "$writeup" = true ]; then
    has_to_end=true
fi

# Check if the box name has been specified
if [ -z "$box_name" ] && [ has_to_end = true ]; then
    echo "${RED}ERROR:${DC} In order to proceed, box name has to be specified using the -b or --box-name flag."
    echo "Use ${BLUE}htb-setup -h${DC} to get help and some examples of the script."
    return 1
elif [ -z "$box_name" ]; then
    # User has not used any flag that need box name, end script
    return 0
fi

# Path to the HTB folder
box_path=""
if [ -d "$HTB_LAB_PATH" ]; then
    if [[ ! $HTB_LAB_PATH.endsWith("/") ]]; then
        box_path=${HTB_LAB_PATH}/
    else
        box_path=$HTB_LAB_PATH
    fi
fi

# Check if the directory already exists and ask the user
if [ -d "$box_path$box_name" ]; then
    echo "${GREEN}WARNING:${DC} The directory for '$box_name' already exists."
    if [ "$auto_yes" = false ]; then
        read choice"?Do you want to enter this directory and continue? (y/N): "
        if [ "$choice" != "y" ]; then
            echo "Exiting the script."
            return 1
        fi
    fi
else
    # Create the directory for the box
    print_msg "Creating box directory at $box_path$box_name"
    mkdir -p "$box_path$box_name"
fi

# Message after entering the box directory
print_msg "Entering the box directory $box_path$box_name"
cd "$box_path$box_name" || return

# If user used -w flag do the writeup search
if [ "$writeup" = true ]; then
    # Check if firefox is installed
    print_msg "Checking if firefox is installed."
    if ! command -v firefox &>/dev/null; then
        echo "${RED}ERROR: ${DC}firefox (CLI) is not installed."
        echo "Please install it with ${BLUE}sudo apt install firefox${DC} and retry."
        return 1
    fi

    # Open Firefox with the writeup of the box
    print_msg "Opening Firefox with the query '$box_name htb writeup'."
    browser_query="$box_name htb writeup"
    firefox --new-tab "https://www.google.com/search?q=$browser_query"
fi

# If user used the -a flag do the api requests
if [ "$api" = true ]; then
    jq=true
    # Make sure jq is installed
    if ! command -v jq &> /dev/null; then
        echo "${RED}ERROR: ${BLUE}jq${DC} is not installed.\nYou can install it with ${BLUE}sudo apt install jq${DC}."
        jq=false
    fi

    if [ -v HTB_API_TOKEN ] && [ "$jq" = true ]; then
        # Set the Token from ENV variable
        print_msg "Setting up your HTB token."
        token=$HTB_API_TOKEN

        # Request to HTB API - infos about the active machine
        res=$(curl -s -H "Authorization: Bearer $token" "https://www.hackthebox.com/api/v4/machine/active")
        print_msg "Checking if you have active machines"

        # Check if request failed
        if [ $? -ne 0 ]; then
            echo "${RED}ERROR: ${DC}Failed request to HTB API.\nYou likely have no active box, go on HTB website and spawn the machine you want to hack."
        else
            box_id=$(echo "$res" | jq -r '.info.id')
            print_msg "Getting the ID of the active machine."

            # Request to HTB API - more infos about the active machine
            res=$(curl -s -H "Authorization: Bearer $token" "https://www.hackthebox.com/api/v4/machine/profile/$box_id")
            print_msg "Requesting more infos about the active machine."

            # Check if request failed
            if [ $? -ne 0 ]; then
                echo "${RED}ERROR: ${DC}Failed request to HTB API."
            else
                active_machine_name=$(echo "$res" | jq -r '.info.name')
                os=$(echo "$res" | jq -r '.info.os')
                difficulty=$(echo "$res" | jq -r '.info.difficultyText')
                rel=$(echo "$res" | jq -r '.info.release')
                release=$(date -d "$rel" "+%d/%m/%Y")
                echo "\nInfos on your spawned machine:"
                echo "${GREEN}Name:${DC} $active_machine_name"
                echo "${GREEN}Operating System:${DC} $os"
                echo "${GREEN}Difficulty:${DC} $difficulty"
                echo "${GREEN}Release Date (dd/mm/yyyy):${DC} $release"

                # Request to HTB API - changelog of the active machine
                res=$(curl -s -H "Authorization: Bearer $token" "https://www.hackthebox.com/api/v4/machine/changelog/$box_id")
                print_msg "Requesting the changelog of the machine"

                # Check if request failed
                if [ $? -ne 0 ]; then
                    echo "${RED}ERROR: ${DC}Failed request to HTB API."
                else
                    echo "${GREEN}Patches:${DC}"
                    if [ "$(echo "$res" | jq 'length')" -eq 0 ]; then
                        echo "\tNo changes to the box since its release date."
                    else
                        data=$(echo "$res" | jq -r '.info[] | "\(.title)\t\(.description)\t\(.updated_at)"')
                        while IFS=$'\t' read -r title description updated_at; do
                            echo -e "\t${GREEN}Title:${DC} $title"
                            echo -e "\t${GREEN}Description:${DC} $description" | fold -s | sed '2,$s/^/\t\\ \ \ \t\ \ \ \ \ /'
                            on=$(date -d "$updated_at" "+%d/%m/%Y")
                            echo -e "\t${GREEN}On (dd/mm/yyyy):${DC} $on\n"
                        done <<< "$data"
                    fi
                fi
            fi
        fi
    elif [ "$jq" = true ]; then
        # HTB Token not set
        echo "${RED}ERROR: ${DC}Your HTB token is not set, you have to set it as an ENV variable in order to get infos from HTB APIs."
        echo "Follow these steps to set your HTB token:"
        echo "1. Go to https://app.hackthebox.com/ and log in"
        echo "2. Click on your user profile (top right of the website)"
        echo "3. Select 'Account Settings’"
        echo "4. Find the 'App Tokens' menu (right side)"
        echo "5. Click on 'Create App Token’"
        echo "6. Give that token a name and set the expiration time"
        echo "7. Copy the token to your clipboard"
        if [ "$shell_name" = "zsh" ]; then
            echo "8. Execute: ${BLUE}echo \"export HTB_API_TOKEN=${GREEN}token_here${BLUE}\" >> ~/.zshrc && source ~/.zshrc${DC}"
        else
            # User has a different shell
            echo "8. Execute: ${BLUE}export HTB_API_TOKEN=\"${GREEN}token_here${BLUE}\"${DC}"
        fi
        echo "9. Run this script again."
    fi
fi

# Script must end if no IP adrress is provided
# None of the steps below are doable without box's IP address
if [ -z "$box_ip" ]; then
    return 0
fi

lowercase_box_entry="${lowercase_box_name}.htb"

# Check if the box has already been added to /etc/hosts previously
if ! grep -qi ".*[[:space:]]${lowercase_box_entry}$" /etc/hosts; then
    # Backup /etc/hosts
    print_msg "Creating a backup of /etc/hosts at $box_pathold_hosts."
    sudo cp /etc/hosts "$box_path/old_hosts"

    # Check if there is a 127.0.0.1 file /etc/hosts
    if grep -q "^\(127\.0\.[0-9]\+\.[0-9]\+\|::1\).*localhost" /etc/hosts; then
        # Write the 2 lines in the file after the localhost entry
        sudo sed -i "/^\(127\.0\.[0-9]\+\.[0-9]\+\|::1\).*localhost$/{n;n;i\\
#${box_name} HTB Machine\\
${box_ip}\t${lowercase_box_name}.htb\n
       		}" /etc/hosts
    else
        # Write the 2 lines in the file at the behinning
        sudo sed -i "1i #${box_name} HTB Machine\n${box_ip}\t${lowercase_box_name}.htb\n" /etc/hosts
    fi
else
    # If the box is already in the /etc/hosts file, check if the IP address is the same
    if ! grep -qi ".*[[:space:]]${box_ip}$" /etc/hosts; then
        echo "${GREEN}WARNING:${DC} The entry for '${lowercase_box_name}.htb' already exists in /etc/hosts, but with a different IP address."
        if [ "$auto_yes" = false ]; then
            read choice"?Do you want to update the entry? (y/N): "
            if [ "$choice" != "y" ]; then
                echo "Entry not updated, exiting the script."
                return 0
            fi
        fi
        # Update the entry in /etc/hosts with the correct IP
        sudo sed -i "s/^#\(.*${lowercase_box_name}.htb\)/\1/" /etc/hosts
        sudo sed -i "s/.*${lowercase_box_name}.htb/${box_ip}\t${lowercase_box_name}.htb/" /etc/hosts
        print_msg "Entry updated successfully."
    else
        print_msg "The entry for '${lowercase_box_name}.htb' already exists in /etc/hosts."
    fi
fi

# Verify the reachability of the box with a ping test
print_msg "Quick ping test..."
ping_result=$(ping -c 3 -l 3 "${box_ip}" | grep packet)
packet_loss=$(echo "$ping_result" | cut -d "," -f 3 | cut -d "%" -f 1 | cut -d " " -f 2)

# If the ping test produces packet loss, communicate that and return
if [ "$packet_loss" != "0" ]; then
    echo "${RED}ERROR:${DC} Packet loss detected in ping test.\nIP address (${BLUE}$box_ip${DC}) might be wrong."
    echo "If the IP address is correct, you should try to run this script with the -c flag in order to connect to HTB's VPN if you are not yet connected."
    return 1
fi

# If the user has set the nmap flag do the scan
if [ "$nmap" = true ]; then
    # Perform the nmap scan and save it to file only if there was no packet loss in the ping test
    echo "Nmap scan in progress...\nThis might take a bit, please be patient."
    sudo nmap -sC -sV -T4 "${lowercase_box_name}.htb" > nmap

    print_msg "The scan has been saved in $box_path$box_name as 'nmap'."
    if [ "$auto_yes" = false ]; then
        read choice"?Do you want to see your nmap scan now? (y/N)"
        if [ "$choice" != "y" ]; then
            # End the script
            return 0
        fi
    fi
    # Display the nmap scan
    print_msg "Showing the nmap scan results.\n"
    cat nmap
fi
