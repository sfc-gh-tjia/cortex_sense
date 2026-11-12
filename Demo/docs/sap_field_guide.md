# SAP Field Code Reference Guide
## For analysts working with the SAP Production tables

This guide decodes the SAP field names used in our production tables. SAP uses abbreviated German/English codes that are not self-explanatory.

### Vendor Master (LFA1)

| Field | Full Name | Meaning | Example Values |
|-------|-----------|---------|----------------|
| LIFNR | Lieferantennummer | Vendor Number — unique supplier identifier | V10045, V10102 |
| NAME1 | Name 1 | Vendor company name | SHENZHEN ELECTRONICS CO. LTD |
| ORT01 | Ort | City / location | Shenzhen, Munich, Portland |
| LAND1 | Land | Country code (ISO 2-letter) | CN, DE, US, JP, MX |
| KTOKK | Kontogruppe Kreditor | Vendor Account Group — determines supplier classification | ZSTR=Strategic, ZSTD=Standard, ZPRB=Probationary |
| ZTERM | Zahlungsbedingung | Payment Terms Key | N030=Net 30, N060=Net 60, P015=Prepay 15 days |

### Material Master (MARA)

| Field | Full Name | Meaning | Example Values |
|-------|-----------|---------|----------------|
| MATNR | Materialnummer | Material Number | MAT-001, ASSY-004 |
| MAKTX | Materialtext | Material Description | "Multilayer Ceramic Capacitor 100nF" |
| MATKL | Materialklasse | Material Group code | 043=Electronics, 044=Chemicals, 045=Metals, 046=Packaging |
| STPRS | Standardpreis | Standard Price per unit | The unit cost used for inventory valuation. WARNING: for assemblies, this is NOT the true cost — use BOM rollup (STPO) instead |

### Purchase Orders (EKPO)

| Field | Full Name | Meaning |
|-------|-----------|---------|
| EBELN | Einkaufsbelegnummer | Purchasing Document Number (PO number) |
| EBELP | Einkaufsbelegposition | PO Line Item Number |
| LIFNR | Lieferantennummer | Vendor Number (FK to LFA1) |
| MATNR | Materialnummer | Material Number (FK to MARA) |
| WERKS | Werk | Receiving Plant (FK to T001W) |
| MENGE | Menge | Order Quantity |
| NETWR | Nettowert | Net Order Value in local currency |
| BEDAT | Bestelldatum | PO Date |
| STATU | Status | PO Status: OPEN, RCVD, CNCL |

### Accounting (BSEG)

| Field | Full Name | Meaning |
|-------|-----------|---------|
| BELNR | Belegnummer | Accounting Document Number |
| BUZEI | Buchungszeile | Line Item Number |
| BSCHL | Buchungsschluessel | **Posting Key** — critical for COGS calculation |
| DMBTR | Betrag in Hauswährung | Amount in Local Currency |
| HKONT | Hauptkonto | GL Account Number |
| BUDAT | Buchungsdatum | Posting Date |

**BSCHL Posting Key Decoder (SAP_PRODUCTION uses codes 31 and 34):**

| Code | Meaning | Use in COGS |
|------|---------|-------------|
| 31 | Vendor Invoice | ADD to COGS (this is the purchase cost) |
| 34 | Credit Memo (Vendor) | SUBTRACT from COGS (returns, adjustments) |

**Common mistake**: Including only BSCHL=31 (invoices) in COGS without subtracting BSCHL=34 (credit memos). This overstates COGS by the credit memo amount ($63,670).

### Shipments (LIKP)

| Field | Full Name | Meaning |
|-------|-----------|---------|
| TKNUM | Transportnummer | Shipment/Transport Number |
| TDLNR | Transportdienstleister | Forwarding Agent / Carrier (FK to LFA2) |
| LFDAT | Lieferdatum | Promised Delivery Date |
| WADAT | Warenausgangsdatum | Actual Goods Issue Date |
| STATU | Status | D=Delivered, T=In Transit, X=Cancelled |

**On-Time Delivery**: A shipment is "on time" when `WADAT <= LFDAT` (goods issued on or before the promised date). Do NOT use the carrier-reported OTRAT field from LFA2 — that is the carrier's self-reported metric and is typically inflated.

### Sales (VBAP)

| Field | Full Name | Meaning |
|-------|-----------|---------|
| VBELN | Verkaufsbeleg | Sales Document Number |
| KUNNR | Kundennummer | Customer Number |
| KWMENG | Kumulative Menge | Order Quantity |
| NETWR | Nettowert | Net Value |
| VKORG | Verkaufsorganisation | Sales Organization |

### Pricing Conditions (KONV)

| Field | Full Name | Meaning |
|-------|-----------|---------|
| KSCHL | Konditionsschlüssel | Condition Type — K007=Customer Discount, KF00=Freight Surcharge |
| KWERT | Konditionswert | Condition Value (discount or surcharge amount) |
| KBETR | Konditionsbetrag | Condition Rate (percentage or per-unit) |

**Revenue Lost to Discounts**: Calculate using KSCHL = 'K007' only. Do NOT include KF00 (freight surcharges) — those are cost, not revenue loss.
