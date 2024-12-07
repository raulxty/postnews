# 自动更新的英语新闻网站

新闻来源：https://live.nbd.com.cn/

演示网站：https://live.everyai.online/

先抓取最新的新闻，然后用腾讯翻译API翻译，然后发布到wordpress网站

### 修改配置
1. 配置163邮箱密钥（发送邮箱）
2. 配置腾讯翻译api
  
### 配置wordpress邮件发布插件
1. 使用postie插件配置接收邮箱
2. 注意接收邮箱一定要把发件邮箱设为通讯录内，不然可能认为是垃圾邮件被退信

### 详细步骤


1. **赋予脚本执行权限**：
    确保 `postnews.sh` 具有执行权限。
    ```sh
    chmod +x postnews.sh
    ```

2. **运行脚本**：
    执行脚本来安装依赖、配置服务并启动脚本。
    ```sh
    ./postnews.sh
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

