# Azure Infrastructure Core (IaC)

本專案是雲端環境的 **管理核心 (Management Hub)**，採用 **Terraform** 實作基礎設施即代碼 (IaC)。透過「地基與應用分離」的架構，定義並維護全域身分驗證（WIF）、行政專案權限與各應用專案的基礎架構。

---

## 🏛️ 架構設計原則 (Architecture)

本核心網路遵循大廠生產環境（Prod）的 **Hub-Spoke 拓撲安全防線**：
* **出網（Outbound）安全**：私網虛擬機集群（VMSS/VM）100% 不配置公網 IP，出網流量強制統一經由全託管 **NAT 閘道 (NAT Gateway)** 以固定公網 IP 出去。
* **入網（Inbound）安全**：完全關閉對外網（Internet）暴露的 22 Port（SSH）。100% 依賴 **Azure Bastion（全託管網頁版堡壘機）** 作為唯一入網穿透地基。
* **密鑰安全 (SecOps)**：拋棄式實體 SSH 私鑰**絕不外流至明文 Output**，由應用層在部署時透過 Data Source 自動咬合、動態塞入本核心層的 **Azure Key Vault** 保險箱中加密託管。

---

## 📂 目錄結構說明 (Directory Structure)

```text
.
├── environments/               # 【環境與部署層】負責綁定具體參數並執行實體部署
│   ├── base-network/           # 核心地基網路層（全環境共用大管家）
│   │   ├── main.tf             # 定義資源群組、核心 VNet 與實體 Subnet 地基
│   │   ├── appgw.tf            # 負載均衡專用（Application Gateway 流量分流與入網 PIP）
│   │   ├── natgw.tf            # 出網網關專用（NAT Gateway 與固定公網 PIP 生效綁定）
│   │   ├── bastion.tf          # 維運跳板專用（Azure Bastion 託管主機與專屬子網）
│   │   ├── keyvault.tf         # 保險箱專用（Azure Key Vault 與對應資安權限策略）
│   │   ├── providers.tf        # 宣告 Azure 供應商與 Backend 狀態鎖設定
│   │   └── variables.tf        # 網路層全域變數與網段定義
│   │
│   └── test-vm-app/            # 專案應用部署入口
│       ├── main.tf             # 呼叫下游 Module，將應用實體注入核心網路
│       ├── providers.tf
│       └── variables.tf
│
└── modules/                    # 【可複用模組層】定義標準化架構藍圖，不保存任何環境狀態
    ├── vm-app/                 # 單個 VM 應用基礎設施模組 (對齊核心 Key Vault 託管金鑰)
    └── vm-app-scale/           # 水平擴展集 (VMSS) 基礎設施模組 (自帶網路拓撲、AAD 穿透與自動化擴展)
```