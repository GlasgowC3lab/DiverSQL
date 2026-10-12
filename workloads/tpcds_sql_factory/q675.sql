WITH promo_stats AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_start_date_sk,
    p.p_end_date_sk,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN ws.ws_net_profit ELSE 0 END) AS male_profit,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN ws.ws_net_profit ELSE 0 END) AS female_profit,
    COUNT(DISTINCT CASE WHEN p.p_discount_active = 'Y' THEN p.p_promo_id END) AS active_promo_cnt,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS discount_status
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  GROUP BY p.p_promo_id, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk, p.p_discount_active
)
SELECT
  p.*,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM promo_stats p
WHERE total_net_profit > 0
ORDER BY profit_rank
LIMIT 10
