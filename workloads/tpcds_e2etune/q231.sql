WITH catalog_agg AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customers
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
      AND cs.cs_ext_discount_amt > 100
    GROUP BY cs.cs_promo_sk
),
web_agg AS (
    SELECT
        ws.ws_promo_sk AS promo_sk,
        wp.wp_type,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers,
        COUNT(*) AS web_orders
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
      AND ws.ws_ext_discount_amt > 100
    GROUP BY ws.ws_promo_sk, wp.wp_type
)
SELECT
    p.p_promo_name,
    p.p_channel_tv,
    wa.wp_type,
    ca.catalog_net_profit,
    wa.web_net_profit,
    ca.catalog_discount + wa.web_discount AS total_discount,
    ca.catalog_customers,
    wa.web_customers,
    wa.web_orders,
    ca.catalog_net_profit + wa.web_net_profit AS total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY (ca.catalog_net_profit + wa.web_net_profit) DESC) AS rank_in_promo
FROM catalog_agg ca
JOIN promotion p ON ca.promo_sk = p.p_promo_sk
JOIN web_agg wa ON ca.promo_sk = wa.promo_sk
WHERE p.p_channel_tv = 'Y'
  AND p.p_start_date_sk <= 2450815
  AND p.p_end_date_sk >= 2450825
ORDER BY total_net_profit DESC
LIMIT 100
