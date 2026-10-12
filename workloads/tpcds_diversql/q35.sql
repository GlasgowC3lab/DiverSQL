WITH
sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
returns_agg AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        sr.sr_returned_date_sk AS returned_date_sk,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        MAX(sr.sr_reason_sk) AS reason_sk
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk AS item_sk,
        inv.inv_date_sk AS inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_date,
    d.d_year,
    sm.sm_type AS ship_type,
    ca.ca_state,
    ws.web_name,
    sa.total_sales,
    sa.total_profit,
    CASE WHEN sa.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ia.total_on_hand,
    ra.return_cnt,
    ra.total_return_amt,
    r.r_reason_desc,
    RANK() OVER (PARTITION BY d.d_year ORDER BY sa.total_sales DESC) AS sales_rank_year
FROM sales_agg sa
JOIN date_dim d
    ON sa.sold_date_sk = d.d_date_sk
JOIN item i
    ON sa.item_sk = i.i_item_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN inventory_agg ia
    ON ia.item_sk = i.i_item_sk
    AND ia.inv_date_sk = d.d_date_sk
LEFT JOIN returns_agg ra
    ON ra.item_sk = i.i_item_sk
    AND ra.returned_date_sk = d.d_date_sk
LEFT JOIN reason r
    ON ra.reason_sk = r.r_reason_sk
WHERE
    d.d_year = 2001
    AND cs.cs_quantity > 1
    AND ss.ss_quantity >= 2
    AND sa.total_sales > 5000
    AND ca.ca_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND ws.web_gmt_offset BETWEEN -5 AND 0
ORDER BY sales_rank_year, profit_flag DESC
LIMIT 100
