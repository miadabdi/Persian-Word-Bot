#!/bin/bash

# Configuration
SERVICE_NAME="persianbot"
DESCRIPTION="Persian Word of the Day Bot"
SCRIPT_NAME="persian_word_bot.py"

# Get the real user (if running as sudo, get the original user)
if [ $SUDO_USER ]; then
    REAL_USER=$SUDO_USER
else
    REAL_USER=$(whoami)
fi

# Get the current directory (assumes script is run from the project folder)
PROJECT_DIR=$(pwd)
VENV_PYTHON="$PROJECT_DIR/venv/bin/python"
SCRIPT_PATH="$PROJECT_DIR/$SCRIPT_NAME"

# 1. Validation Checks
echo "🔍 Checking environment..."

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: Could not find $SCRIPT_NAME in $PROJECT_DIR"
    exit 1
fi

if [ ! -f "$VENV_PYTHON" ]; then
    echo "❌ Error: Could not find virtual environment at $VENV_PYTHON"
    echo "   Please run: python3 -m venv venv"
    exit 1
fi

echo "✅ Found script at: $SCRIPT_PATH"
echo "✅ Found python at: $VENV_PYTHON"
echo "👤 Service will run as user: $REAL_USER"

# 2. Create the .service file content
SERVICE_CONTENT="[Unit]
Description=$DESCRIPTION
After=network.target

[Service]
User=$REAL_USER
WorkingDirectory=$PROJECT_DIR
ExecStart=$VENV_PYTHON $SCRIPT_PATH
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target"

# 3. Write the file to /etc/systemd/system/
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
echo "📝 Creating service file at $SERVICE_FILE..."

# We use bash -c to handle the redirection with sudo permissions
bash -c "echo \"$SERVICE_CONTENT\" > $SERVICE_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Service file created successfully."
else
    echo "❌ Error writing service file. Are you running with sudo?"
    exit 1
fi

# 4. Enable and Start the service
echo "⚙️  Configuring Systemd..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

# 5. Show status
echo "📊 Checking status..."
systemctl status $SERVICE_NAME --no-pager

echo ""
echo "🎉 Setup Complete! Your bot is now running in the background."
echo "   To view logs, use: sudo journalctl -u $SERVICE_NAME -f"