WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        ws_site.web_name,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        COUNT(*) AS total_orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450300
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_education_status IN ('College', '4 yr Degree')
      AND p.p_response_target > 0
    GROUP BY ws.ws_web_site_sk, ws_site.web_name, i.i_category
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    web_site_sk,
    web_name,
    i_category,
    total_net_profit,
    avg_discount_amount,
    distinct_customers,
    total_orders,
    RANK() OVER (PARTITION BY web_site_sk ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY web_site_sk, profit_rank
LIMIT 200
