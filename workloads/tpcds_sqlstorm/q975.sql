WITH ss_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_market_id AS market_id,
        d.d_year,
        format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM') AS month_key,
        sum(ss.ss_net_profit) AS store_net_profit,
        sum(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, s.s_store_name, s.s_market_id, d.d_year, format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM')
),
sr_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM') AS month_key,
        sum(sr.sr_net_loss) AS store_return_loss,
        sum(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, d.d_year, format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM')
),
top_items AS (
    SELECT
        s.s_store_id,
        format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM') AS month_key,
        i.i_item_id,
        i.i_product_name,
        sum(ss.ss_net_profit) AS item_profit,
        row_number() OVER (PARTITION BY s.s_store_id, format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM') ORDER BY sum(ss.ss_net_profit) DESC) AS rn
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY s.s_store_id, format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM'), i.i_item_id, i.i_product_name
),
market_agg AS (
    SELECT
        s.s_market_id AS market_id,
        d.d_year,
        format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM') AS month_key,
        avg(ss.ss_net_profit) AS avg_market_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_market_id, d.d_year, format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM')
)
SELECT
    ss.s_store_id,
    ss.s_store_name,
    ss.market_id,
    ss.month_key,
    ss.store_net_profit,
    sr.store_return_loss,
    (ss.store_net_profit - coalesce(sr.store_return_loss, 0)) AS net_profit_adj,
    lag(ss.store_net_profit) OVER (PARTITION BY ss.s_store_id ORDER BY ss.month_key) AS prev_month_profit,
    (ss.store_net_profit - lag(ss.store_net_profit) OVER (PARTITION BY ss.s_store_id ORDER BY ss.month_key)) AS month_over_month_change,
    ma.avg_market_net_profit,
    CASE WHEN ma.avg_market_net_profit > 0 THEN ss.store_net_profit / ma.avg_market_net_profit ELSE NULL END AS store_market_share,
    ti.i_item_id,
    ti.i_product_name,
    ti.item_profit
FROM ss_agg ss
LEFT JOIN sr_agg sr
    ON ss.s_store_id = sr.s_store_id
    AND ss.month_key = sr.month_key
    AND ss.d_year = sr.d_year
LEFT JOIN market_agg ma
    ON ss.market_id = ma.market_id
    AND ss.month_key = ma.month_key
    AND ss.d_year = ma.d_year
LEFT JOIN (
    SELECT s_store_id, month_key, i_item_id, i_product_name, item_profit
    FROM top_items
    WHERE rn <= 5
) ti
    ON ss.s_store_id = ti.s_store_id
    AND ss.month_key = ti.month_key
WHERE ss.d_year = 2002
ORDER BY ss.s_store_id, ss.month_key, ti.item_profit DESC
