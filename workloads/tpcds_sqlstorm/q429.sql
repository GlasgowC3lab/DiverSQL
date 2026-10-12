WITH unified_sales AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_item_sk AS item_sk,
        ss_customer_sk AS customer_sk,
        ss_promo_sk AS promo_sk,
        ss_store_sk AS store_sk,
        CAST(NULL AS integer) AS web_site_sk,
        CAST(NULL AS integer) AS catalog_page_sk,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_sold_date_sk AS date_sk,
        ws_item_sk AS item_sk,
        ws_bill_customer_sk AS customer_sk,
        ws_promo_sk AS promo_sk,
        CAST(NULL AS integer) AS store_sk,
        ws_web_site_sk AS web_site_sk,
        CAST(NULL AS integer) AS catalog_page_sk,
        ws_net_paid AS net_paid,
        ws_net_profit AS net_profit,
        ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales
    UNION ALL
    SELECT
        cs_sold_date_sk AS date_sk,
        cs_item_sk AS item_sk,
        cs_bill_customer_sk AS customer_sk,
        cs_promo_sk AS promo_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS web_site_sk,
        cs_catalog_page_sk AS catalog_page_sk,
        cs_net_paid AS net_paid,
        cs_net_profit AS net_profit,
        cs_quantity AS quantity,
        'catalog' AS channel
    FROM catalog_sales
),
aggregated AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_class,
        i.i_brand,
        u.channel,
        sum(u.net_paid) AS total_net_paid,
        sum(u.net_profit) AS total_net_profit,
        sum(u.quantity) AS total_quantity,
        count(DISTINCT u.customer_sk) AS distinct_customers,
        avg(u.net_paid) FILTER (WHERE p.p_discount_active = 'Y') AS avg_paid_active_discount
    FROM unified_sales u
    LEFT JOIN date_dim d ON u.date_sk = d.d_date_sk
    LEFT JOIN item i ON u.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON u.promo_sk = p.p_promo_sk
    LEFT JOIN store s ON u.store_sk = s.s_store_sk
    LEFT JOIN web_site w ON u.web_site_sk = w.web_site_sk
    LEFT JOIN catalog_page cp ON u.catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2002
    GROUP BY
        d.d_year,
        i.i_category,
        i.i_class,
        i.i_brand,
        u.channel
)
SELECT
    a.d_year,
    a.i_category,
    a.i_class,
    a.i_brand,
    a.channel,
    a.total_net_paid,
    a.total_net_profit,
    a.total_quantity,
    a.distinct_customers,
    a.avg_paid_active_discount,
    rank() OVER (PARTITION BY a.d_year ORDER BY a.total_net_paid DESC) AS revenue_rank
FROM aggregated a
ORDER BY a.d_year, revenue_rank
LIMIT 100
