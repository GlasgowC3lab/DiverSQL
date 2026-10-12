WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        i.i_category,
        d.d_year,
        SUM(ss.ss_net_paid) AS net_sales,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS qty_sold
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY ss.ss_store_sk, i.i_category, d.d_year
),
store_returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        i.i_category,
        d.d_year,
        SUM(sr.sr_return_amt) AS return_amount,
        SUM(sr.sr_return_quantity) AS qty_returned
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY sr.sr_store_sk, i.i_category, d.d_year
),
inventory_avg AS (
    SELECT
        i.i_category,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_category
)
SELECT
    s.store_sk,
    s.i_category,
    s.net_sales,
    s.net_profit,
    COALESCE(r.return_amount, 0) AS total_returns,
    COALESCE(r.qty_returned, 0) AS return_qty,
    (COALESCE(r.return_amount, 0) / NULLIF(s.net_sales, 0)) * 100 AS return_rate_pct,
    i.avg_inventory_qty,
    RANK() OVER (PARTITION BY s.i_category ORDER BY s.net_profit DESC) AS profit_rank_by_category
FROM store_sales_agg s
LEFT JOIN store_returns_agg r
    ON s.store_sk = r.store_sk
    AND s.i_category = r.i_category
    AND s.d_year = r.d_year
JOIN inventory_avg i
    ON s.i_category = i.i_category
WHERE s.net_profit > 0
ORDER BY s.i_category, profit_rank_by_category
LIMIT 20
