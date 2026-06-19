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
├── environments/
│   └── base-network/           # 核心地基網路層（大管家）
│       ├── main.tf             # 定義 VNet, Subnet, NAT Gateway, Bastion, Key Vault
│       ├── providers.tf
│       └── variables.tf
└── modules/
    ├── vm-app/                 # 單機版應用基礎設施模組 (對齊核心 Key Vault 託管)
    └── vm-app-scale/           # 水平擴展集 (VMSS) 基礎設施模組 (自帶拓撲與自動化腳本)