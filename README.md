# 自动抓取最新的财经新闻，翻译成英语，并通过邮箱发布一篇wordpress博客

新闻来源：https://live.nbd.com.cn/
演示网站：https://live.everyai.online/

### 修改配置
1. 配置163邮箱密钥（发送邮箱）
2. 配置腾讯翻译api
  
### 配置wordpress邮件发布插件
1. 使用postie插件配置接收邮箱

### 详细步骤

1. **上传脚本**：
    使用 `scp` 命令将 `setup_script.sh` 上传到Lightsail实例。
    ```sh
    scp -i ~/Downloads/LightsailDefaultKey-us-east-1.pem setup_script.sh bitnami@<instance-ip>:~
    ```
    例如：
    ```sh
    scp -i ~/Downloads/LightsailDefaultKey-us-east-1.pem setup_script.sh bitnami@192.0.2.1:~
    ```

2. **连接到实例**：
    使用SSH连接到Lightsail实例。
    ```sh
    ssh -i ~/Downloads/LightsailDefaultKey-us-east-1.pem bitnami@192.0.2.1
    ```

3. **赋予脚本执行权限**：
    确保 `setup_script.sh` 具有执行权限。
    ```sh
    chmod +x setup_script.sh
    ```

4. **运行脚本**：
    执行脚本来安装依赖、配置服务并启动脚本。
    ```sh
    ./setup_script.sh
    ```

### 验证部署

1. **检查服务状态**：
    使用 `systemctl` 命令检查 `newstengxun` 服务的状态。
    ```sh
    sudo systemctl status newstengxun
    ```
    您应该会看到类似以下的输出，表明服务正在运行：
    ```
    ● newstengxun.service - News Translation Script
       Loaded: loaded (/etc/systemd/system/newstengxun.service; enabled; vendor preset: enabled)
       Active: active (running) since Mon 2023-10-02 12:34:56 UTC; 1min ago
     Main PID: 1234 (bash)
        Tasks: 1 (limit: 1153)
       Memory: 28.3M
       CGroup: /system.slice/newstengxun.service
               └─1234 /bin/bash /opt/newstengxun/newstengxun.py
    ```

2. **查看日志**：
    查看脚本的日志以确保一切正常。
    ```sh
    journalctl -u newstengxun -f
    ```
    您可以看到脚本的输出和调试信息，确认邮件发送是否成功以及是否有其他错误。

