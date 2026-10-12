WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS avg_discount_pct,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS promo_active_ratio,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cs.cs_item_sk = cr.cr_item_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
store_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_ext_discount_amt) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS avg_discount_pct,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS promo_active_ratio,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
web_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS avg_discount_pct,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS promo_active_ratio,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
)
SELECT
    year,
    month,
    category,
    class,
    brand,
    channel,
    total_sales,
    total_profit,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    total_quantity,
    distinct_orders,
    distinct_customers,
    avg_discount_pct,
    promo_active_ratio,
    total_return_loss,
    ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) t
ORDER BY year, month, channel, profit_rank
LIMIT 200
