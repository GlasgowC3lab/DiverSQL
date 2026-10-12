WITH promo_sales AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        p.p_cost AS promo_cost,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_bill_customers,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS distinct_ship_customers,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_bill_customers,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_bill_customers,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450920
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_cost
)
SELECT
    ps.promo_id,
    ps.promo_name,
    ps.promo_cost,
    ps.total_net_profit,
    ps.total_sales,
    ps.avg_discount,
    ps.distinct_bill_customers,
    ps.distinct_ship_customers,
    ps.male_bill_customers,
    ps.female_bill_customers,
    ps.avg_income_band,
    RANK() OVER (ORDER BY ps.total_net_profit DESC) AS profit_rank
FROM promo_sales ps
ORDER BY ps.total_net_profit DESC
LIMIT 10
