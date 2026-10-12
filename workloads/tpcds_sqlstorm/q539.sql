WITH date_dim_filtered AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 2000
),
sales_union AS (
    SELECT 
        ss.ss_store_sk AS store_sk,
        ss.ss_sold_date_sk AS sold_date_sk,
        CAST(NULL AS integer) AS catalog_page_sk,
        CAST(NULL AS integer) AS web_page_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        ss.ss_ticket_number AS order_number,
        ss.ss_promo_sk AS promo_sk,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        CAST(NULL AS integer) AS store_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_catalog_page_sk AS catalog_page_sk,
        CAST(NULL AS integer) AS web_page_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        cs.cs_order_number AS order_number,
        cs.cs_promo_sk AS promo_sk,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        CAST(NULL AS integer) AS store_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        CAST(NULL AS integer) AS catalog_page_sk,
        ws.ws_web_page_sk AS web_page_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        ws.ws_order_number AS order_number,
        ws.ws_promo_sk AS promo_sk,
        'web' AS channel
    FROM web_sales ws
),
aggregated AS (
    SELECT 
        COALESCE(s.s_store_name, cp.cp_description, wp.wp_url) AS channel_name,
        d.d_year,
        d.d_month_seq,
        su.channel,
        SUM(su.net_paid) AS total_net_paid,
        SUM(su.net_profit) AS total_net_profit,
        COUNT(DISTINCT su.order_number) AS distinct_orders,
        AVG(su.quantity) AS avg_quantity,
        SUM(CASE WHEN su.promo_sk IS NOT NULL THEN su.net_profit ELSE 0 END) AS promo_net_profit,
        SUM(CASE WHEN su.promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS promo_sales_cnt,
        CASE 
            WHEN SUM(su.net_profit) > 1000000 THEN 'HIGH'
            WHEN SUM(su.net_profit) > 500000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM sales_union su
    JOIN date_dim_filtered d ON su.sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON su.store_sk = s.s_store_sk
    LEFT JOIN catalog_page cp ON su.catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_page wp ON su.web_page_sk = wp.wp_web_page_sk
    GROUP BY COALESCE(s.s_store_name, cp.cp_description, wp.wp_url), d.d_year, d.d_month_seq, su.channel
)
SELECT *
FROM (
    SELECT 
        channel_name,
        d_year,
        d_month_seq,
        channel,
        total_net_paid,
        total_net_profit,
        distinct_orders,
        avg_quantity,
        promo_net_profit,
        promo_sales_cnt,
        profit_category,
        ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY total_net_profit DESC) AS profit_rank
    FROM aggregated
) ranked
WHERE profit_rank <= 5
ORDER BY d_year, channel, profit_rank
