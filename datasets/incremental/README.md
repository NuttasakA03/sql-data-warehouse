# Incremental batches for MERGE practice

Same files and columns as `datasets/source_crm` and `datasets/source_erp`. Load the full dataset first, then `batch_01`, then `batch_02`.

## batch_01 (load date 2026-11-17)
- **cust_info**: 50 new customers (29484–29533), 30 existing customers changed (marital status and/or last name, new `cst_create_date`), and 2 exact duplicate rows. That is 82 rows in total.
- **prd_info**: 5 price changes (new `prd_id`, same `prd_key`, new cost, `prd_start_dt` 2026-11-17) and 3 new products (`...-NW-xxxx`). That is 8 rows.
- **sales_details**: 120 new orders (SO75124 onwards, ordered 2026-11-17) and 5 corrections to old orders (same order number and product, quantity +1). A few rows have a blank or negative sales value, like the original file. That is 250 rows.
- **CUST_AZ12**: 50 new customers and 10 corrections to existing customers.
- **LOC_A101**: 50 new customers and 30 country changes (the same 30 changed customers).
- **PX_CAT_G1V2**: AC_BR maintenance flag changed from Yes to No.

## batch_02 (load date 2026-11-18)
- **cust_info**: 20 new customers, 15 changed customers (5 of them already changed in batch_01, which gives SCD2 a third version), 2 duplicate rows, and 3 rows that repeat batch_01 unchanged. The repeated rows should cause no change at all. That is 40 rows.
- **prd_info**: 2 price changes.
- **sales_details**: 60 new orders (2026-11-18) and 3 corrections to batch_01 orders. That is 119 rows.
- **CUST_AZ12 / LOC_A101**: rows for the new customers, plus corrections and country changes.
- **PX_CAT_G1V2**: header only, so there are no changes.

## What to check after each load
1. New rows are inserted and changed rows are updated (SCD1), or the old version is expired and a new current version is added (SCD2).
2. Duplicate and repeated rows do not create extra rows.
3. A watermark on `sls_order_dt` will **miss** the corrections to old orders. Watch for that and decide how to handle it, for example with a load-date or modified-date watermark.
4. Running the same batch twice changes nothing (idempotent).
