WITH sales_by_channel AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity,
        SUM(ss.ss_ext_sales_price) AS sales_amount
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
),
web_sales_agg AS (
    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity,
        SUM(ws.ws_ext_sales_price) AS sales_amount
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
catalog_sales_agg AS (
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity,
        SUM(cs.cs_ext_sales_price) AS sales_amount
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_sold_date_sk = cr.cr_returned_date_sk
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
),
combined AS (
    SELECT * FROM sales_by_channel
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
),
item_agg_raw AS (
    SELECT
        c.channel,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(c.net_profit) AS total_net_profit,
        SUM(c.quantity) AS total_quantity,
        SUM(c.sales_amount) AS total_sales,
        COUNT(DISTINCT c.date_sk) AS days_sold,
        COALESCE(NULLIF(i.i_color, ''), 'UNKNOWN') AS item_color,
        CONCAT(UPPER(i.i_brand), '-', LOWER(i.i_category)) AS brand_category_key,
        CASE WHEN i.i_units IS NULL OR i.i_units = '' THEN 'UNSPECIFIED' ELSE i.i_units END AS units_normalized
    FROM combined c
    JOIN date_dim d ON c.date_sk = d.d_date_sk
    JOIN item i ON c.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
      AND (c.quantity > 0 OR c.sales_amount IS NOT NULL)
    GROUP BY c.channel,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        d.d_month_seq,
        i.i_color,
        i.i_brand,
        i.i_category,
        i.i_units
),
item_monthly AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (PARTITION BY channel, item_id ORDER BY total_net_profit DESC) AS profit_rank,
        LAG(total_net_profit) OVER (PARTITION BY channel, item_id ORDER BY year, month_seq) AS prev_month_profit,
        CASE
            WHEN LAG(total_net_profit) OVER (PARTITION BY channel, item_id ORDER BY year, month_seq) IS NULL THEN NULL
            ELSE (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY channel, item_id ORDER BY year, month_seq))
                 / NULLIF(LAG(total_net_profit) OVER (PARTITION BY channel, item_id ORDER BY year, month_seq), 0)
        END AS profit_growth_ratio
    FROM item_agg_raw r
),
top_items AS (
    SELECT *
    FROM item_monthly im
    WHERE im.profit_rank <= 10
      AND im.total_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_item_sk = im.item_sk
            AND ss2.ss_net_profit > im.total_net_profit * 0.5
      )
)
SELECT
    ti.channel,
    ti.item_id,
    ti.product_name,
    ti.year,
    ti.month_seq,
    ti.total_net_profit,
    ti.total_quantity,
    ti.total_sales,
    ti.days_sold,
    ti.profit_rank,
    ROUND(ti.profit_growth_ratio, 4) AS profit_growth_ratio,
    ti.item_color,
    ti.brand_category_key,
    ti.units_normalized,
    COALESCE(ti.prev_month_profit, 0) AS prev_month_profit,
    CASE
        WHEN ti.prev_month_profit IS NULL THEN 'N/A'
        WHEN ti.prev_month_profit = 0 THEN 'Infinity'
        ELSE CAST(ROUND(ti.profit_growth_ratio, 4) AS VARCHAR)
    END AS growth_indicator
FROM top_items ti
ORDER BY ti.channel, ti.total_net_profit DESC, ti.profit_rank
