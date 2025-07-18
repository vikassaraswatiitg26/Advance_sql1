#  Retail Inventory Analytics – SQL & Power BI

This project presents a structured and insightful analysis of retail store inventory using SQL and Power BI. The primary objective is to support inventory optimization, reduce stockouts, and enable data-driven restocking strategies using historical inventory, demand, and sales data.

---

##  Project Overview

- **Database Name:** `retail_store`
- **Tables Used:**
  - `store`: Store-wise regional data
  - `product`: Product details per store-region
  - `inventory`: Daily records of stock, sales, demand, etc.
  - `reorder_analysis` (View): Created for dashboard-driven restocking insights
  - `Date` table: Time dimension for Power BI modeling

---

##  Schema Design

###  Primary Keys

| Table     | Primary Key                  |
|-----------|------------------------------|
| store     | Store_Region_ID              |
| product   | Store_Region_Product_ID      |

###  Foreign Keys (in `inventory`)

- `Store_Region_ID` → `store(Store_Region_ID)`
- `Store_Region_Product_ID` → `product(Store_Region_Product_ID)`

---

##  Composite Identifiers

- **Store_Region_ID** – Combines store and region (e.g., `S001_N`)
- **Store_Region_Product_ID** – Links store, region, and product (e.g., `S001_N_P001`)

These identifiers enable granular tracking and accurate joins.

---

##  Key Metrics Computed

| Metric                    | Description |
|--------------------------|-------------|
|  Stock Level           | Aggregated inventory per store and region |
|  Low Inventory Detection | Flags items below reorder threshold |
|  Inventory Turnover     | Ratio of units sold to average inventory |
|  Reorder Lag Days       | Days between consecutive restocks |
|  Stockout Rate          | Frequency and percentage of demand shortfalls |
|  Inventory Age          | Inventory health index (stock-to-demand ratio) |

---

##  Power BI Dashboard Model

- Fully normalized star schema
- Tables used: `store`, `product`, `inventory`, `Date`, and `reorder_analysis` view
- Filtering supported by:
  - Time
  - Region
  - Product category
- Visuals include: Stock levels, reorder alerts, turnover ratio, and stockout trends

---

## ⚙ SQL Highlights

```sql
-- Stock Level by Region
-- Reorder Point & Lag Days
-- Inventory Turnover
-- Stockout Analysis
-- Reorder View Creation (for BI consumption)
```


# Business Outcomes
-  Improved restocking decisions
-  Reduced stockouts
-  Region-based demand insights
-  Identification of slow- or fast-moving items
