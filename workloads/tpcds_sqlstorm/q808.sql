WITH sales_agg AS (
    SELECT
        d.d_year,
        s.s_store_id,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_sales_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, s.s_store_id, i.i_category
),
returns_agg AS (
    SELECT
        d.d_year,
        s.s_store_id,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, s.s_store_id, i.i_category
)
SELECT
    s.d_year,
    s.s_store_id,
    s.i_category,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
    s.total_sales_qty,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) / NULLIF(s.total_sales_qty, 0) AS profit_per_item
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.s_store_id = r.s_store_id
    AND s.i_category = r.i_category
ORDER BY net_profit DESC
LIMIT 100
