#!/bin/bash

# Function to run the script with root privileges using sudo
run_as_root() {
    # Update package lists and upgrade existing packages
    apt-get update && apt-get upgrade -y

    # Install Python3, pip, and virtualenv
    apt-get install -y python3 python3-pip python3-venv

    # Create project directory
    PROJECT_DIR="/opt/newstengxun"
    mkdir -p $PROJECT_DIR

    # Create a virtual environment in the project directory
    VENV_DIR="$PROJECT_DIR/venv"
    python3 -m venv $VENV_DIR

    # Activate the virtual environment and install dependencies
    source $VENV_DIR/bin/activate
    pip install --upgrade pip
    pip install requests beautifulsoup4 schedule

    # Deactivate the virtual environment after installing dependencies
    deactivate

    # Copy Python script to project directory
    cat <<EOF > $PROJECT_DIR/newstengxun.py
#!/usr/bin/env bash
# Activate the virtual environment and run the Python script
source /opt/newstengxun/venv/bin/activate
exec python3 /opt/newstengxun/newstengxun_main.py
EOF

    # Make the wrapper script executable
    chmod +x $PROJECT_DIR/newstengxun.py

    # Create the main Python script
    cat <<EOF > $PROJECT_DIR/newstengxun_main.py
#!/usr/bin/env python3
import subprocess
import sys
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import requests
from bs4 import BeautifulSoup
import schedule
import time
import hmac
import hashlib
import base64
import json
from datetime import datetime

# 定义要抓取的网站URL
url = 'https://live.nbd.com.cn/'

# 邮件配置
smtp_server = 'smtp.163.com'  # SMTP服务器地址
smtp_port = 465  # SMTP端口（SSL/TLS）
smtp_username = 'XXXX'  # 发件人邮箱地址
smtp_password = 'XXXX'  # 使用授权码
recipient_email = 'XXXX'  # 收件人邮箱地址

# 翻译API配置
translation_url = 'https://tmt.tencentcloudapi.com/'
secret_id = 'XXXX'
secret_key = 'XXXX'

def get_tencent_cloud_signature(params, secret_key):
    sorted_params = '&'.join(sorted(['='.join([str(k), str(v)]) for k, v in params.items()]))
    string_to_sign = f"POSTtmt.tencentcloudapi.com/?{sorted_params}"
    signature = hmac.new(secret_key.encode(), string_to_sign.encode(), hashlib.sha1).digest()
    encoded_signature = base64.b64encode(signature).decode()
    return encoded_signature

def translate_text(text):
    timestamp = int(datetime.now().timestamp())
    nonce = 123456789
    action = 'TextTranslate'
    version = '2018-03-21'
    region = 'ap-guangzhou'
    
    params = {
        'Action': action,
        'Version': version,
        'Region': region,
        'Nonce': nonce,
        'Timestamp': timestamp,
        'SecretId': secret_id,
        'SourceText': text,
        'Source': 'zh',
        'Target': 'en',
        'ProjectId': 0
    }
    
    signature = get_tencent_cloud_signature(params, secret_key)
    params['Signature'] = signature
    
    try:
        response = requests.post(translation_url, data=params)
        response.raise_for_status()  # 检查请求是否成功
        result = response.json()
        translated_text = result['Response']['TargetText']
        print(f"Translated text: {translated_text[:100]}...")  # 打印前100个字符
        return translated_text
    except Exception as e:
        print(f"Error translating text. Error: {e}")
        return text

def send_email(subject, body, recipient):
    msg = MIMEMultipart()
    msg['From'] = smtp_username
    msg['To'] = recipient
    msg['Subject'] = subject
    
    msg.attach(MIMEText(body, 'plain'))
    
    try:
        server = smtplib.SMTP_SSL(smtp_server, smtp_port)  # 使用SSL/TLS连接
        server.set_debuglevel(1)  # 启用调试模式
        server.login(smtp_username, smtp_password)
        text = msg.as_string()
        server.sendmail(smtp_username, recipient, text)
        server.quit()
        print(f"Email sent successfully: {subject}")
    except Exception as e:
        print(f"Failed to send email. Error: {e}")

def fetch_news_titles():
    try:
        response = requests.get(url)
        response.raise_for_status()  # 检查请求是否成功
        soup = BeautifulSoup(response.content, 'html.parser')
        
        titles = []
        contents = []
        
        # 根据提供的HTML结构解析新闻标题和内容
        for item in soup.find_all('li'):
            li_text_div = item.find('div', class_='li-text')
            if li_text_div:
                h1_tag = li_text_div.find('h1')
                p_tag = li_text_div.find('p')
                
                if h1_tag and p_tag:
                    title = h1_tag.get_text(strip=True)
                    content = p_tag.get_text(strip=True)
                    titles.append(title)
                    contents.append(content)
        
        return titles, contents
    except Exception as e:
        print(f"Error fetching news: {e}")
        return [], []

def compare_and_save_new_news(first_run, old_titles, old_contents):
    new_titles, new_contents = fetch_news_titles()

    # 打印抓取到的新标题和内容
    print(f"New Titles: {new_titles}")
    print(f"New Contents: {[content[:100] + '...' for content in new_contents]}")  # 打印每个内容的前100个字符

    # 找出新的新闻条目
    new_entries = []
    for i, title in enumerate(new_titles):
        if title not in old_titles:
            new_entries.append({
                'title': title,
                'content': new_contents[i] if i < len(new_contents) else ''
            })
            print(f"New entry found: {title}")

    # 如果有新的条目，则保存它们
    if new_entries:
        print(f"Found {len(new_entries)} new entries.")
        all_titles = old_titles + [entry['title'] for entry in new_entries]
        all_contents = old_contents + [entry['content'] for entry in new_entries]
        
        # 只保留最新的50条新闻条目
        all_titles = all_titles[-50:]
        all_contents = all_contents[-50:]
        
        # 如果不是第一次运行，则发送每篇新的新闻作为单独的邮件
        if not first_run:
            for entry in new_entries:
                translated_title = translate_text(entry['title'])
                translated_content = translate_text(entry['content']) if entry['content'] else ''
                send_email(translated_title, translated_content, recipient_email)
        return all_titles, all_contents
    else:
        print("No new entries found.")
        return old_titles, old_contents

def job(old_titles, old_contents, first_run_flag):
    print("Checking for new news...")
    global first_run
    old_titles, old_contents = compare_and_save_new_news(first_run_flag, old_titles, old_contents)
    first_run = False  # 设置为False以确保后续运行会发送邮件
    return old_titles, old_contents

# 设置定时任务
interval_minutes = 1  # 自定义间隔时间，单位为分钟

# 初始化首次运行标志
first_run = True

# 初始新闻标题和内容
old_titles = []
old_contents = []

while True:
    old_titles, old_contents = job(old_titles, old_contents, first_run)
    print(f"Scheduled to check every {interval_minutes} minutes.")
    time.sleep(interval_minutes * 60)
EOF

    # 赋予主Python脚本执行权限
    chmod +x $PROJECT_DIR/newstengxun_main.py

    # 创建systemd服务文件以管理脚本
    SERVICE_FILE="/etc/systemd/system/newstengxun.service"
    cat <<EOF > $SERVICE_FILE
[Unit]
Description=News Translation Script
After=network.target

[Service]
ExecStart=$PROJECT_DIR/newstengxun.py
Restart=always
User=root
Group=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    systemctl daemon-reload

    # 启动并启用服务
    systemctl start newstengxun
    systemctl enable newstengxun

    echo "Script setup complete."
}

# Run the function with sudo privileges
sudo bash -c "$(declare -f run_as_root); run_as_root"



