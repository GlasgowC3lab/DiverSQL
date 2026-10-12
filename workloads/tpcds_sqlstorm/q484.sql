WITH sales_unified AS (
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        d.d_year,
        i.i_item_sk,
        i.i_category,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        NULL AS web_page_sk,
        cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk,
        d.d_year,
        i.i_item_sk,
        i.i_category,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_promo_sk,
        NULL,
        ss.ss_store_sk,
        NULL,
        ss.ss_customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk,
        d.d_year,
        i.i_item_sk,
        i.i_category,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_promo_sk,
        NULL,
        NULL,
        ws.ws_web_page_sk,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
agg_sales AS (
    SELECT
        su.channel,
        su.i_category,
        su.d_year,
        cd.cd_gender AS gender,
        ca.ca_country AS country,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        SUM(su.net_paid) AS total_revenue,
        SUM(su.discount_amt) AS total_discount,
        SUM(su.quantity) AS total_quantity,
        COUNT(DISTINCT su.i_item_sk) AS distinct_items
    FROM sales_unified su
    JOIN customer c ON su.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON su.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store s ON su.store_sk = s.s_store_sk
    LEFT JOIN web_page wp ON su.web_page_sk = wp.wp_web_page_sk
    GROUP BY
        su.channel,
        su.i_category,
        su.d_year,
        cd.cd_gender,
        ca.ca_country,
        COALESCE(p.p_promo_name, 'No Promo')
    HAVING SUM(su.net_paid) > 50000
)
SELECT
    channel,
    i_category,
    d_year,
    COALESCE(gender, 'UNKNOWN') AS gender,
    COALESCE(country, 'UNKNOWN') AS country,
    promo_name,
    total_revenue,
    total_discount,
    total_quantity,
    distinct_items,
    ROUND(total_revenue / NULLIF(total_quantity, 0), 2) AS avg_price_per_item,
    ROUND(total_discount / NULLIF(total_revenue, 0), 4) AS discount_rate,
    RANK() OVER (PARTITION BY channel, d_year ORDER BY total_revenue DESC) AS revenue_rank,
    LAG(total_revenue) OVER (PARTITION BY channel, i_category ORDER BY d_year) AS prior_year_revenue,
    (total_revenue - LAG(total_revenue) OVER (PARTITION BY channel, i_category ORDER BY d_year)) AS revenue_change,
    CASE
        WHEN LAG(total_revenue) OVER (PARTITION BY channel, i_category ORDER BY d_year) IS NULL
             OR LAG(total_revenue) OVER (PARTITION BY channel, i_category ORDER BY d_year) = 0 THEN NULL
        ELSE (total_revenue - LAG(total_revenue) OVER (PARTITION BY channel, i_category ORDER BY d_year)) /
             LAG(total_revenue) OVER (PARTITION BY channel, i_category ORDER BY d_year)
    END AS revenue_pct_change
FROM agg_sales
ORDER BY channel, d_year, total_revenue DESC
LIMIT 200
