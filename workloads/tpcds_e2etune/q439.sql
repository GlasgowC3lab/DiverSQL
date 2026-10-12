WITH ws_customer_agg AS (
  SELECT
    ws.ws_promo_sk,
    ws.ws_bill_customer_sk AS cust_sk,
    SUM(ws.ws_net_profit) AS profit,
    SUM(ws.ws_net_paid) AS sales,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY ws.ws_promo_sk, ws.ws_bill_customer_sk
),
cr_customer_agg AS (
  SELECT
    cr.cr_refunded_customer_sk AS cust_sk,
    SUM(cr.cr_net_loss) AS loss,
    SUM(cr.cr_return_amount) AS return_amount,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY cr.cr_refunded_customer_sk
),
promo_join AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    SUM(ws.profit) AS total_profit,
    COALESCE(SUM(cr.loss), 0) AS total_loss,
    CASE WHEN COALESCE(SUM(cr.loss), 0) = 0 THEN NULL ELSE SUM(ws.profit) / SUM(cr.loss) END AS profit_to_loss_ratio
  FROM ws_customer_agg ws
  LEFT JOIN customer c
    ON ws.cust_sk = c.c_customer_sk
  LEFT JOIN cr_customer_agg cr
    ON c.c_customer_sk = cr.cust_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY p.p_promo_id, p.p_promo_name
  HAVING SUM(ws.profit) > 0
)
SELECT
  pj.p_promo_id,
  pj.p_promo_name,
  pj.total_profit,
  pj.total_loss,
  pj.profit_to_loss_ratio,
  RANK() OVER (ORDER BY pj.profit_to_loss_ratio DESC NULLS LAST) AS promo_rank
FROM promo_join pj
ORDER BY pj.profit_to_loss_ratio DESC
LIMIT 10
