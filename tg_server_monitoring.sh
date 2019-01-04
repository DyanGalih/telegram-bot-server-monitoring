#!/bin/bash
#
# Telegram Monitor Agent
#
# @Author       @DyanGalih - dyan.galih@gmail.com
# @version		0.0.1
# @date			2019-01-04
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Set environment
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Agent version
version="0.0.1"

# Chat Id
chat_id=[chat_id]

# Message Id
message_id=[message_id]

#Telegram token
token=[telegram_bot_token]

# Prepare values
function prep ()
{
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}

# Integer values
function int ()
{
	echo ${1/\.*}
}

# Filter numeric
function num ()
{
	case $1 in
	    ''|*[!0-9\.]*) echo 0 ;;
	    *) echo $1 ;;
	esac
}

# OS details
os_kernel=$(prep "$(uname -r)")

if ls /etc/*release > /dev/null 2>&1
then
	os_name=$(prep "$(cat /etc/*release | grep '^PRETTY_NAME=\|^NAME=\|^DISTRIB_ID=' | awk -F\= '{ print $2 }' | tr -d '"' | tac)")
fi

if [ -z "$os_name" ]
then
	if [ -e /etc/redhat-release ]
	then
		os_name=$(prep "$(cat /etc/redhat-release)")
	elif [ -e /etc/debian_version ]
	then
		os_name=$(prep "Debian $(cat /etc/debian_version)")
	fi
	
	if [ -z "$os_name" ]
	then
		os_name=$(prep "$(uname -s)")
	fi
fi

hostname=$(prep "$(hostname)")

while [ true ]; do

    # System uptime
    uptime=$(prep "$(uptime -p)")

    # Login session count
    sessions=$(prep "$(who | wc -l)")

    # Process count
    processes=$(prep "$(ps axc | wc -l)")

    # File descriptors
    file_handles=$(prep $(num "$(cat /proc/sys/fs/file-nr | awk '{ print $1 }')"))
    file_handles_limit=$(prep $(num "$(cat /proc/sys/fs/file-nr | awk '{ print $3 }')"))

    # CPU details
    cpu_name=$(prep "$(cat /proc/cpuinfo | grep 'model name' | awk -F\: '{ print $2 }')")
    cpu_cores=$(prep "$(($(cat /proc/cpuinfo | grep 'model name' | awk -F\: '{ print $2 }' | sed -e :a -e '$!N;s/\n/\|/;ta' | tr -cd \| | wc -c)+1))")

    if [ -z "$cpu_name" ]
    then
        cpu_name=$(prep "$(cat /proc/cpuinfo | grep 'vendor_id' | awk -F\: '{ print $2 } END { if (!NR) print "N/A" }')")
        cpu_cores=$(prep "$(($(cat /proc/cpuinfo | grep 'vendor_id' | awk -F\: '{ print $2 }' | sed -e :a -e '$!N;s/\n/\|/;ta' | tr -cd \| | wc -c)+1))")
    fi

    cpu_freq=$(prep "$(cat /proc/cpuinfo | grep 'cpu MHz' | awk -F\: '{ print $2 }')")

    if [ -z "$cpu_freq" ]
    then
        cpu_freq=$(prep $(num "$(lscpu | grep 'CPU MHz' | awk -F\: '{ print $2 }' | sed -e 's/^ *//g' -e 's/ *$//g')"))
    fi

    # RAM usage
    ram_total=$(prep "$(free -h | grep ^Mem: | awk '{ print $2 }')")
    ram_free=$(prep "$(free -h | grep ^Mem: | awk '{ print $4 }')")
    ram_available=$(prep "$(free -h | grep ^Mem: | awk '{ print $7 }')")
    ram_usage=$(prep "$(free -h | grep ^Mem: | awk '{ print $3 }')")

    # Swap usage
    swap_total=$(prep "$(free -h | grep ^Swap: | awk '{ print $2 }')")
    swap_free=$(prep "$(free -h | grep ^Swap: | awk '{ print $4 }')")
    swap_usage=$(prep "$(free -h | grep ^Swap: | awk '{ print $3 }')")

    # Disk usage
    disk_total=$(prep "$(df -P -B 1 -h | grep '^/' | awk '{ print $2 }')")
    disk_usage=$(prep "$(df -P -B 1 -h | grep '^/' | awk '{ print $3 }')")
    disk_available=$(prep "$(df -P -B 1 -h | grep '^/' | awk '{ print $4 }')")

    # Active connections
    if [ -n "$(command -v ss)" ]
    then
        connections=$(prep $(num "$(ss -tun | tail -n +2 | wc -l)"))
    else
        connections=$(prep $(num "$(netstat -tun | tail -n +3 | wc -l)"))
    fi

    cpu_load=$(prep "$[100-$(vmstat 1 2|tail -1|awk '{print $15}')]")

    last_update=$(prep "$(date|awk '{print $4 }')")
    # Build data for post
    data_post="Hostname = $hostname [$last_update] %0AUptime Server = $uptime %0ARam Free = $ram_free %0ADisk Availale = $disk_available %0AConnections = $connections %0ACPU Load = $cpu_load"

    curl -d chat_id=$chat_id -d message_id=$message_id -d text="$data_post" "https://api.telegram.org/$token/editMessageText"
    sleep 10
done