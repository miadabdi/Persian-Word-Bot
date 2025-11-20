import asyncio
import time
from datetime import datetime

import schedule
from mnk_persian_words.persian_words import get_random_persian_word
from telegram import Bot

# ================= CONFIGURATION =================
# Replace these with your actual details
BOT_TOKEN = "YOUR_BOT_TOKEN_HERE"
CHANNEL_ID = "@YourChannelName"  # Or use the numeric ID like "-100123456789"
SCHEDULE_TIME = "09:00"  # Time in 24h format to send words daily
# =================================================


async def send_daily_words():
    """
    Fetches 5 random words and sends them to the configured channel.
    """
    print(f"[{datetime.now()}] Preparing to fetch words...")

    try:
        # 1. Generate 5 random Persian words
        # The library returns a single string with spaces, so we split it for formatting
        raw_words = get_random_persian_word(words_count=5)
        words_list = raw_words.split(" ")

        # 2. Format the message nicely
        # We use Markdown to make the header bold
        message = "📚 **Word of the Day** 📚\n\n"
        for i, word in enumerate(words_list, 1):
            message += f"{i}. {word}\n"

        message += "\n#Persian #Learning"

        # 3. Initialize the bot and send the message
        bot = Bot(token=BOT_TOKEN)
        await bot.send_message(chat_id=CHANNEL_ID, text=message)

        print(f"[{datetime.now()}] Successfully sent 5 words to {CHANNEL_ID}")

    except Exception as e:
        print(f"[{datetime.now()}] Error occurred: {e}")


def job_wrapper():
    """
    Wrapper to run the async function inside the synchronous scheduler
    """
    asyncio.run(send_daily_words())


def main():
    print("🤖 Persian Word Bot is running...")
    print(f"📅 Scheduled to send messages daily at {SCHEDULE_TIME}")

    # Schedule the job
    schedule.every().day.at(SCHEDULE_TIME).do(job_wrapper)

    # Just for testing: Uncomment the line below to send a message immediately when you start
    # job_wrapper()

    # Keep the script running to check the time
    while True:
        schedule.run_pending()
        time.sleep(60)  # Check every minute


if __name__ == "__main__":
    main()
