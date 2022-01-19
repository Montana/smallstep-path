#!/bin/bash

CERT_DIR="/etc/mysql/certificates"
SERVICE_NAME="mariadb"
CYCLE_COMMAND="/usr/bin/mysqladmin flush-ssl"
cat > /etc/systemd/system/renew-${SERVICE_NAME}-certificate.service <<EOF

[Unit]

Description=${SERVICE_NAME} certificate renewal
Before=${SERVICE_NAME}.service
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=30
StartLimitBurst=3

[Service]

Type=simple
User=root
Group=root
ExecStartPre=/usr/bin/step certificate verify ${CERT_DIR}/%H.crt
ExecStart=/usr/bin/step ca renew ${CERT_DIR}/%H.crt ${CERT_DIR}/%H.key --daemon --exec="${CYCLE_COMMAND}"
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=30
StartLimitBurst=3

; Process capabilities & privileges
SecureBits=keep-caps
NoNewPrivileges=yes

; Sandboxing
ProtectSystem=full
ProtectHome=read-only
RestrictNamespaces=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
PrivateTmp=true
PrivateDevices=true
ProtectClock=true
ProtectControlGroups=true
ProtectKernelTunables=true
ProtectKernelLogs=true
ProtectKernelModules=true
LockPersonality=true
RestrictSUIDSGID=true
RemoveIPC=true
RestrictRealtime=true
SystemCallFilter=@system-service
SystemCallArchitectures=native
MemoryDenyWriteExecute=true
ReadWriteDirectories=${CERT_DIR}

[Install]

WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now /etc/systemd/system/renew-${SERVICE_NAME}-certificate.service
