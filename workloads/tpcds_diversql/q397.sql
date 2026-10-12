-- Goal: Identify the top 5 loss‑making returns per day and product category across catalog, store, and web channels for 2001,
-- including item price, household income band and source channel, and rank them by net loss.
WITH catalog_part AS (
    SELECT
        d.d_date,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        hd.hd_income_band_sk,
        cp.cp_catalog_number,
        wh.w_warehouse_name,
        cr.cr_return_amount,
        cr.cr_net_loss,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_current_price > 20
      AND hd.hd_income_band_sk IN (2, 16)
),
store_part AS (
    SELECT
        d.d_date,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        hd.hd_income_band_sk,
        NULL AS cp_catalog_number,
        NULL AS w_warehouse_name,
        sr.sr_return_amt AS cr_return_amount,
        sr.sr_net_loss AS cr_net_loss,
        'store' AS source
    FROM store_returns sr
    FULL OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_current_price > 20
      AND hd.hd_income_band_sk IN (2, 16)
),
web_part AS (
    SELECT
        d.d_date,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        hd.hd_income_band_sk,
        NULL AS cp_catalog_number,
        NULL AS w_warehouse_name,
        wr.wr_return_amt AS cr_return_amount,
        wr.wr_net_loss AS cr_net_loss,
        'web' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_current_price > 20
      AND hd.hd_income_band_sk IN (2, 16)
),
union_all AS (
    SELECT * FROM catalog_part
    UNION DISTINCT
    SELECT * FROM store_part
    UNION DISTINCT
    SELECT * FROM web_part
),
ranked AS (
    SELECT
        d_date,
        i_item_sk,
        i_category,
        i_current_price,
        hd_income_band_sk,
        cp_catalog_number,
        w_warehouse_name,
        cr_return_amount,
        cr_net_loss,
        source,
        CASE
            WHEN cr_net_loss > 500 THEN 'HIGH'
            WHEN cr_net_loss > 100 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_severity,
        ROW_NUMBER() OVER (PARTITION BY d_date, i_category ORDER BY cr_net_loss DESC) AS rn
    FROM union_all
)
SELECT
    d_date,
    i_item_sk,
    i_category,
    i_current_price,
    hd_income_band_sk,
    cp_catalog_number,
    w_warehouse_name,
    cr_return_amount,
    cr_net_loss,
    source,
    loss_severity,
    rn
FROM ranked
WHERE rn <= 5
ORDER BY d_date DESC, i_category, rn
LIMIT 100
