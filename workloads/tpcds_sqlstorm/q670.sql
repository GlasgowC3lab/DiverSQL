WITH
store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
        ss.ss_store_sk,
        d.d_year,
        d.d_quarter_seq,
        i.i_category
),
web_sales_agg AS (
    SELECT
        ws.ws_web_page_sk,
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        ws.ws_web_page_sk,
        d.d_year,
        d.d_quarter_seq,
        i.i_category
),
combined_sales AS (
    SELECT
        'store' AS sales_channel,
        sssa.ss_store_sk AS store_sk,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        sssa.d_year,
        sssa.d_quarter_seq,
        sssa.i_category,
        sssa.total_net_paid,
        sssa.total_net_profit,
        sssa.total_quantity,
        sssa.avg_sales_price,
        sssa.total_orders
    FROM store_sales_agg sssa
    JOIN store s ON sssa.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT
        'web' AS sales_channel,
        wsa.ws_web_page_sk AS store_sk,
        CONCAT(wp.wp_type, ' Page') AS store_name,
        CAST(NULL AS VARCHAR) AS store_city,
        wsa.d_year,
        wsa.d_quarter_seq,
        wsa.i_category,
        wsa.total_net_paid,
        wsa.total_net_profit,
        wsa.total_quantity,
        wsa.avg_sales_price,
        wsa.total_orders
    FROM web_sales_agg wsa
    JOIN web_page wp ON wsa.ws_web_page_sk = wp.wp_web_page_sk
),
ranked_items AS (
    SELECT
        cs.sales_channel,
        cs.store_sk,
        cs.store_name,
        cs.store_city,
        cs.d_year,
        cs.i_category,
        cs.total_net_profit,
        cs.total_net_paid,
        cs.total_quantity,
        cs.avg_sales_price,
        cs.total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs.d_year, cs.i_category ORDER BY cs.total_net_profit DESC) AS category_profit_rank,
        RANK() OVER (PARTITION BY cs.sales_channel, cs.d_year ORDER BY cs.total_net_paid DESC) AS channel_paid_rank
    FROM combined_sales cs
),
stores_without_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM store s
    LEFT JOIN store_sales_agg ssa ON s.s_store_sk = ssa.ss_store_sk
    WHERE ssa.ss_store_sk IS NULL
),
customer_latest_sale AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        d.d_year,
        d.d_month_seq,
        MAX(ss.ss_sold_date_sk) AS last_sale_date_sk
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        d.d_year,
        d.d_month_seq
),
promo_effectiveness AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        SUM(COALESCE(ss.ss_net_paid, ws.ws_net_paid, 0)) AS total_sales,
        SUM(COALESCE(ss.ss_ext_discount_amt, ws.ws_ext_discount_amt, 0)) AS total_discount,
        CASE WHEN SUM(COALESCE(ss.ss_net_paid, ws.ws_net_paid, 0)) > 0 THEN
            (SUM(COALESCE(ss.ss_ext_discount_amt, ws.ws_ext_discount_amt, 0)) / SUM(COALESCE(ss.ss_net_paid, ws.ws_net_paid, 0))) * 100
        ELSE NULL END AS discount_rate_percent
    FROM promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    LEFT JOIN store_sales ss ON p.p_promo_sk = ss.ss_promo_sk
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id, p.p_promo_name
),
final_result AS (
    SELECT
        ri.sales_channel,
        ri.store_name,
        ri.store_city,
        ri.d_year,
        ri.total_net_profit,
        ri.total_net_paid,
        ri.total_quantity,
        ri.avg_sales_price,
        ri.total_orders,
        ri.category_profit_rank,
        ri.channel_paid_rank,
        COALESCE(pe.discount_rate_percent, 0) AS discount_rate_percent,
        CASE
            WHEN ri.total_net_profit > 0 THEN 'Profitable'
            WHEN ri.total_net_profit = 0 THEN 'BreakEven'
            ELSE 'Loss'
        END AS profit_status,
        CONCAT(ri.store_name, ' (Rank ', CAST(ri.channel_paid_rank AS VARCHAR), ')') AS store_rank_label,
        CASE WHEN sws.s_store_sk IS NOT NULL THEN 'NoSales' ELSE 'HasSales' END AS sales_availability_flag,
        COALESCE(cls.last_sale_date_sk, -1) AS sample_customer_last_sale_sk
    FROM ranked_items ri
    LEFT JOIN promo_effectiveness pe ON pe.p_promo_id = (
        SELECT p_promo_id FROM promotion ORDER BY p_promo_sk LIMIT 1
    )
    LEFT JOIN stores_without_sales sws ON sws.s_store_sk = ri.store_sk
    LEFT JOIN customer_latest_sale cls ON cls.c_customer_sk = (
        SELECT MAX(c_customer_sk) FROM customer
    )
)

SELECT *
FROM final_result
WHERE profit_status = 'Profitable'
  AND (discount_rate_percent IS NULL OR discount_rate_percent < 20)
ORDER BY d_year DESC, total_net_profit DESC
LIMIT 100
