#!/bin/bash
#
# Telegram Monitor Agent
#
# @Author       @DyanGalih - dyan.galih@gmail.com
# @version		0.0.2
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
VERSION="0.0.2"

# Chat Id
CHAT_ID=[CHAT_ID]

# Message Id
MESSAGE_ID=[MESSAGE_ID]

# Telegram token
TOKEN=[TELEGRAM_BOT_TOKEN]

# Set Timezone
TZ=[TZ]

# Prepare values
function PREP ()
{
	echo "$1" | sed -e 's/^ *//g' -e 's/ *$//g' | sed -n '1 p'
}

# Integer values
function INT ()
{
	echo ${1/\.*}
}

# Filter numeric
function NUM ()
{
	case $1 in
	    ''|*[!0-9\.]*) echo 0 ;;
	    *) echo $1 ;;
	esac
}

# OS details
OS_KERNEL=$(PREP "$(uname -r)")

if ls /etc/*release > /dev/null 2>&1
then
	OS_NAME=$(PREP "$(cat /etc/*release | grep '^PRETTY_NAME=\|^NAME=\|^DISTRIB_ID=' | awk -F\= '{ print $2 }' | tr -d '"' | tac)")
fi

if [ -z "$OS_NAME" ]
then
	if [ -e /etc/redhat-release ]
	then
		OS_NAME=$(PREP "$(cat /etc/redhat-release)")
	elif [ -e /etc/debian_version ]
	then
		OS_NAME=$(PREP "Debian $(cat /etc/debian_version)")
	fi
	
	if [ -z "$OS_NAME" ]
	then
		OS_NAME=$(PREP "$(uname -s)")
	fi
fi

HOSTNAME=$(PREP "$(hostname)")

# System uptime
UPTIME=$(PREP "$(uptime -p)")

# Login session count
SESSIONS=$(PREP "$(who | wc -l)")

# Process count
PROCESSES=$(PREP "$(ps axc | wc -l)")

# File descriptors
FILE_HANDLES=$(PREP "$(NUM "$(cat /proc/sys/fs/file-nr | awk '{ print $1 }')")")
FILE_HANDLES_LIMIT=$(PREP $(NUM "$(cat /proc/sys/fs/file-nr | awk '{ print $3 }')"))

# CPU details
CPU_NAME=$(PREP "$(cat /proc/cpuinfo | grep 'model name' | awk -F\: '{ print $2 }')")
CPU_CORES=$(PREP "$(($(cat /proc/cpuinfo | grep 'model name' | awk -F\: '{ print $2 }' | sed -e :a -e '$!N;s/\n/\|/;ta' | tr -cd \| | wc -c)+1))")

if [ -z "$CPU_NAME" ]
then
    CPU_NAME=$(PREP "$(cat /proc/cpuinfo | grep 'vendor_id' | awk -F\: '{ print $2 } END { if (!NR) print "N/A" }')")
    CPU_CORES=$(PREP "$(($(cat /proc/cpuinfo | grep 'vendor_id' | awk -F\: '{ print $2 }' | sed -e :a -e '$!N;s/\n/\|/;ta' | tr -cd \| | wc -c)+1))")
fi

CPU_FREQ=$(PREP "$(cat /proc/cpuinfo | grep 'cpu MHz' | awk -F\: '{ print $2 }')")

if [ -z "$CPU_FREQ" ]
then
    CPU_FREQ=$(PREP $(NUM "$(lscpu | grep 'CPU MHz' | awk -F\: '{ print $2 }' | sed -e 's/^ *//g' -e 's/ *$//g')"))
fi

# RAM usage
RAM_TOTAL=$(PREP "$(free -h | grep ^Mem: | awk '{ print $2 }')")
RAM_FREE=$(PREP "$(free -h | grep ^Mem: | awk '{ print $4 }')")
RAM_AVAILABLE=$(PREP "$(free -h | grep ^Mem: | awk '{ print $7 }')")
RAM_USAGE=$(PREP "$(free -h | grep ^Mem: | awk '{ print $3 }')")

# Swap usage
SWAP_TOTAL=$(PREP "$(free -h | grep ^Swap: | awk '{ print $2 }')")
SWAP_FREE=$(PREP "$(free -h | grep ^Swap: | awk '{ print $4 }')")
SWAP_USAGE=$(PREP "$(free -h | grep ^Swap: | awk '{ print $3 }')")

# Disk usage
DISK_TOTAL=$(PREP "$(df -P -B 1 -h | grep '^/' | awk '{ print $2 }')")
DISK_USAGE=$(PREP "$(df -P -B 1 -h | grep '^/' | awk '{ print $3 }')")
DISK_AVAILABLE=$(PREP "$(df -P -B 1 -h | grep '^/' | awk '{ print $4 }')")

# Active connections
if [ -n "$(command -v ss)" ]
then
    CONNECTIONS=$(PREP $(NUM "$(ss -tun | tail -n +2 | wc -l)"))
else
    CONNECTIONS=$(PREP $(NUM "$(netstat -tun | tail -n +3 | wc -l)"))
fi

CPU_LOAD=$(PREP "$((100 - $(vmstat 1 2 | tail -1 | awk '{print $15}')))")

CONVERT_TIMEZONE=$(TZ="$TZ" date)

LAST_UPDATE=$(PREP "$CONVERT_TIMEZONE")

# Build data for post
DATA="Last Update = $LAST_UPDATE %0AHostname = $HOSTNAME %0AUptime Server = $UPTIME %0ARam Free = $RAM_FREE %0ADisk Available = $DISK_AVAILABLE %0AConnections = $CONNECTIONS %0ACPU Load = $CPU_LOAD"

curl --max-time 10 -d chat_id=$CHAT_ID -d message_id=$MESSAGE_ID -d text="$DATA" "https://api.telegram.org/bot$TOKEN/editMessageText"
