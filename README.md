# Telegram Monitor Agent

This script monitors system metrics such as uptime, CPU load, RAM usage, disk availability, and active connections on a Linux server. It then sends the data to a specified Telegram chat through a bot.

## Features
- Reports system uptime, CPU load, RAM usage, disk availability, and active network connections.
- Sends the data to a Telegram chat via a bot.
- Can be run periodically using `crontab`.

## Prerequisites

Before using this script, ensure you have:
1. **curl** installed on your server:
   ```bash
   sudo apt-get install curl  # On Debian/Ubuntu
   sudo yum install curl      # On CentOS/RedHat
   ```
2. A **Telegram Bot**:
    - Create a Telegram bot using [BotFather](https://core.telegram.org/bots#botfather) and get your bot token.
    - Obtain your `chat_id` where the bot will send messages. You can use a service like [IDBot](https://telegram.me/myidbot) to get the `chat_id`.

## Installation

1. **Clone the repository**:
   ```bash
   git clone git@github.com:DyanGalih/telegram-bot-server-monitoring.git
   cd telegram-bot-server-monitoring
   ```

2. **Edit the script**:
   Open `tg_server_monitoring.sh` and replace the placeholders in the script:
    - `[CHAT_ID]`: Replace this with your Telegram `chat_id`.
    - `[TELEGRAM_BOT_TOKEN]`: Replace this with your Telegram bot token.
    - `[MESSAGE_ID]`: Replace this with your Telegram message_id.
    - `[TZ]`: Replace this with your Timezone.

3. **Make the script executable**:
   ```bash
   chmod +x tg_server_monitoring.sh
   ```

## Usage

### Run via `crontab`
You can schedule this script to run at regular intervals using `crontab`. This setup will run the script every minute, sending system metrics to your Telegram chat.

### Steps to Set up `crontab`:

1. **Open the crontab editor**:
   ```bash
   crontab -e
   ```

2. **Add the following line to run the script every minute**:
   ```bash
   * * * * * /path/to/your/tg_server_monitoring.sh
   ```

   Replace `/path/to/your/tg_server_monitoring.sh` with the actual path to your script.

3. **Save and exit**. The script will now run every minute and send system information to the specified Telegram chat.

## Customizing the Script

- **Intervals**: To change the frequency of the monitoring, adjust the time in the `crontab` entry:
    - Every 5 minutes: `*/5 * * * *`
    - Every hour: `0 * * * *`

Since `crontab` doesn't natively support intervals less than 1 minute, to run a script every 30 seconds, you can achieve it by adding two `crontab` entries.

## Run script each 30 seconds

`crontab` does not natively support intervals shorter than 1 minute, but you can work around this by running the script twice within each minute (at the 0-second and 30-second marks).

### Steps to Set up `crontab` to Run Every 30 Seconds:

1. **Open the crontab editor**:
   ```bash
   crontab -e
   ```

2. **Add the following lines to run the script every 30 seconds**:
   ```bash
   * * * * * /path/to/your/tg_server_monitoring.sh
   * * * * * sleep 30 && /path/to/your/tg_server_monitoring.sh
   ```

   Replace `/path/to/your/tg_server_monitoring.sh` with the actual path to your script.

3. **Save and exit**. This setup will run the script at the start of every minute and then again 30 seconds later.

## Example Output

The bot will send a message to the Telegram chat with system information like this:
```
Hostname = your-server [12:34] 
Uptime Server = up 2 days, 4 hours 
Ram Free = 1.2G 
Disk Available = 50G 
Connections = 10 
CPU Load = 23%
```

## How to initialized in the first time

### 1. Chat Directly with the Bot or Create a Group

#### Chat Directly with the Bot:
1. Find your bot in Telegram by searching for its username.
2. Click **Start** or send `/start` to initiate a conversation with your bot.
3. You can now send messages directly to the bot.

#### Create a Group with the Bot:
1. In Telegram, create a new group.
2. Add the bot to the group by searching for its username.
3. Start interacting with the group and the bot.

---

### 2. Get the `chat_id` Using `getUpdates`

After starting the conversation (either direct chat or in a group), you can retrieve the `chat_id` by using the `getUpdates` method.

#### Steps to Retrieve the `chat_id`:

1. Open a terminal and run the following `curl` command to retrieve updates from your bot:

   ```bash
   curl -X GET "https://api.telegram.org/bot[telegram_bot_token]/getUpdates"
   ```

   Replace `[telegram_bot_token]` with your actual bot token.

2. You’ll receive a JSON response. Look for the `chat` object inside the `message` section, which contains the `chat_id`.

   Example of a response snippet:

   ```json
   {
     "update_id": 123456789,
     "message": {
       "message_id": 1,
       "from": {
         "id": 987654321,
         "is_bot": false,
         "first_name": "John",
         "username": "john_doe",
         "language_code": "en"
       },
       "chat": {
         "id": 987654321,
         "first_name": "John",
         "username": "john_doe",
         "type": "private"
       },
       "date": 1629985262,
       "text": "/start"
     }
   }
   ```

   The `id` inside the `chat` object is your `chat_id`. In this case, the `chat_id` is `987654321`.

---

### 3. Send a Message to the Chat

Once you have the `chat_id`, you can send a message to your chat using the `sendMessage` method of the Telegram Bot API.

#### Example `curl` Command to Send a Message:

1. Use the following `curl` command to send a message to your chat:

   ```bash
   curl -X POST "https://api.telegram.org/bot[telegram_bot_token]/sendMessage" \
        -d chat_id=[chat_id] \
        -d text="Initialized"
   ```

   Replace:
   - `[telegram_bot_token]` with your actual bot token.
   - `[chat_id]` with the `chat_id` you retrieved.
   - `"Initialized"` with your desired message.

2. After running the command, your bot will send the message to the specified chat.

---

### 4. Example for Group Chats

If the bot is added to a group, the steps are the same. You’ll get the `chat_id` from the `getUpdates` response, and it will represent the group where the bot was added. You can use the same `sendMessage` command with the group `chat_id` to send a message to the group.

---

With these instructions, you should be able to set up your bot, retrieve the `chat_id`, and send messages from your server to Telegram chats using `curl`.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.