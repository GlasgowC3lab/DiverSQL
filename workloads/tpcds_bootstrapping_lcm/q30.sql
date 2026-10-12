WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, ss.ss_item_sk
),
returns_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_quantity_returned,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
),
inventory_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_item_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_quarter_name,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_closed_date_sk,
    d_closed.d_date AS store_closed_date,
    sa.ss_item_sk,
    sa.total_quantity_sold,
    sa.total_sales_amount,
    COALESCE(ra.total_quantity_returned, 0) AS total_quantity_returned,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    ia.total_quantity_on_hand,
    (sa.total_quantity_sold - COALESCE(ra.total_quantity_returned, 0)) AS net_quantity_sold,
    (sa.total_sales_amount - COALESCE(ra.total_return_amount, 0)) AS net_sales_amount,
    (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS net_profit
FROM sales_agg sa
INNER JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk
INNER JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg ra
    ON sa.ss_sold_date_sk = ra.wr_returned_date_sk
    AND sa.ss_item_sk = ra.wr_item_sk
LEFT JOIN inventory_agg ia
    ON d.d_date_sk = ia.inv_date_sk
    AND sa.ss_item_sk = ia.inv_item_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year = 2022
ORDER BY d.d_date, s.s_store_id, sa.ss_item_sk
