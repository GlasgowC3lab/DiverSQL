WITH
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        sum(cs.cs_net_paid_inc_tax) AS cat_sales,
        sum(cs.cs_net_profit) AS cat_profit,
        count(DISTINCT cs.cs_order_number) AS cat_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        sum(cr.cr_net_loss) AS cat_return_loss,
        count(DISTINCT cr.cr_order_number) AS cat_return_orders
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq
),
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        sum(ss.ss_net_paid_inc_tax) AS store_sales,
        sum(ss.ss_net_profit) AS store_profit,
        count(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        sum(sr.sr_net_loss) AS store_return_loss,
        count(DISTINCT sr.sr_ticket_number) AS store_return_orders
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        sum(ws.ws_net_paid_inc_tax) AS web_sales,
        sum(ws.ws_net_profit) AS web_profit,
        count(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq
),
web_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        sum(wr.wr_net_loss) AS web_return_loss,
        count(DISTINCT wr.wr_order_number) AS web_return_orders
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq
),
top_items_month_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_item_id,
        i.i_product_name,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_product_name
    HAVING sum(cs.cs_ext_sales_price) > 10000
),
top_items_month AS (
    SELECT
        year,
        month,
        i_item_id,
        i_product_name,
        total_sales,
        total_profit,
        row_number() OVER (PARTITION BY year, month ORDER BY total_profit DESC) AS rn
    FROM top_items_month_agg
)
SELECT
    cs.year,
    cs.month,
    cs.cat_sales,
    cs.cat_profit,
    cs.cat_orders,
    cr.cat_return_loss,
    cr.cat_return_orders,
    ss.store_sales,
    ss.store_profit,
    ss.store_orders,
    sr.store_return_loss,
    sr.store_return_orders,
    ws.web_sales,
    ws.web_profit,
    ws.web_orders,
    wr.web_return_loss,
    wr.web_return_orders,
    (cs.cat_sales + ss.store_sales + ws.web_sales) - (cr.cat_return_loss + sr.store_return_loss + wr.web_return_loss) AS total_net_sales,
    (cs.cat_profit + ss.store_profit + ws.web_profit) AS total_net_profit,
    CASE
        WHEN (cs.cat_orders + ss.store_orders + ws.web_orders) > 0
        THEN ((cr.cat_return_orders + sr.store_return_orders + wr.web_return_orders) * 100.0) / (cs.cat_orders + ss.store_orders + ws.web_orders)
        ELSE NULL
    END AS overall_return_rate_pct,
    ti.i_item_id,
    ti.i_product_name,
    ti.total_sales AS top_item_month_sales,
    ti.total_profit AS top_item_month_profit
FROM catalog_sales_agg cs
LEFT JOIN catalog_returns_agg cr ON cs.year = cr.year AND cs.month = cr.month
LEFT JOIN store_sales_agg ss ON cs.year = ss.year AND cs.month = ss.month
LEFT JOIN store_returns_agg sr ON cs.year = sr.year AND cs.month = sr.month
LEFT JOIN web_sales_agg ws ON cs.year = ws.year AND cs.month = ws.month
LEFT JOIN web_returns_agg wr ON cs.year = wr.year AND cs.month = wr.month
LEFT JOIN (
    SELECT
        year,
        month,
        i_item_id,
        i_product_name,
        total_sales,
        total_profit
    FROM top_items_month
    WHERE rn = 1
) ti ON cs.year = ti.year AND cs.month = ti.month
ORDER BY cs.year, cs.month
