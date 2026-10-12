WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_catalog_page_number,
        i.i_brand,
        i.i_category,
        sm.sm_type,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN catalog_page cp                     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d                          ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t                          ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i                              ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm                        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd           ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1000 AND 1012
      AND i.i_brand = 'Brand#12'
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > 5
      AND cs.cs_sales_price > 20.00
),
inventory_info AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        inv.inv_quantity_on_hand,
        i.i_category,
        d.d_year AS inv_year
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE inv.inv_quantity_on_hand > 0
      AND d.d_year = 2001
),
web_returns_info AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_return_quantity AS wr_return_qty,
        wr.wr_return_amt,
        i.i_brand,
        d.d_year
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND wr.wr_return_amt > 10.00
),
site_info AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        d_open.d_year AS open_year,
        d_close.d_year AS close_year
    FROM web_site ws
    LEFT JOIN date_dim d_open  ON ws.web_open_date_sk  = d_open.d_date_sk
    LEFT JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d_open.d_year = 2001 OR d_close.d_year = 2001
)
SELECT
    ws.web_site_id,
    ws.web_name,
    COUNT(DISTINCT fs.cs_order_number)               AS orders_without_returns,
    SUM(fs.cs_quantity)                               AS total_quantity,
    AVG(fs.cs_net_profit)                             AS avg_profit,
    MIN(fs.cs_sales_price)                            AS min_sales_price,
    MAX(fs.cs_sales_price)                            AS max_sales_price,
    SUM(COALESCE(wr.wr_return_amt, 0))                AS total_return_amount,
    COUNT(DISTINCT inv.inv_item_sk)                   AS inventory_items
FROM filtered_sales fs
FULL OUTER JOIN inventory_info inv   ON fs.cs_item_sk = inv.inv_item_sk
FULL OUTER JOIN web_returns_info wr ON fs.cs_order_number = wr.wr_order_number
FULL OUTER JOIN site_info ws          ON 1 = 1
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_order_number = fs.cs_order_number
)
  AND fs.cs_order_number IN (
        SELECT cs_order_number FROM filtered_sales
        INTERSECT
        SELECT wr_order_number FROM web_returns_info
    )
GROUP BY ws.web_site_id, ws.web_name
LIMIT 100
