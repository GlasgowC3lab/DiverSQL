WITH store_agg AS (
  SELECT
    s.s_store_name AS store_name,
    cd.cd_education_status AS education_status,
    SUM(ss.ss_net_profit) AS store_net_profit
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_purchase_estimate >= 1500
    AND ss.ss_quantity > 1
  GROUP BY s.s_store_name, cd.cd_education_status
),
web_agg AS (
  SELECT
    cd.cd_education_status AS education_status,
    SUM(ws.ws_net_profit) AS web_net_profit
  FROM web_sales ws
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ws.ws_sales_price > 100
  GROUP BY cd.cd_education_status
),
return_agg AS (
  SELECT
    cd.cd_education_status AS education_status,
    SUM(wr.wr_return_amt) AS total_return_amount
  FROM web_returns wr
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE wr.wr_returned_date_sk >= 2450000
  GROUP BY cd.cd_education_status
)
SELECT
  sa.store_name,
  sa.education_status,
  sa.store_net_profit,
  COALESCE(wa.web_net_profit, 0) AS web_net_profit,
  COALESCE(ra.total_return_amount, 0) AS total_return_amount,
  (sa.store_net_profit + COALESCE(wa.web_net_profit, 0) - COALESCE(ra.total_return_amount, 0)) AS net_profit_after_returns,
  RANK() OVER (ORDER BY (sa.store_net_profit + COALESCE(wa.web_net_profit, 0) - COALESCE(ra.total_return_amount, 0)) DESC) AS profit_rank
FROM store_agg sa
LEFT JOIN web_agg wa ON sa.education_status = wa.education_status
LEFT JOIN return_agg ra ON sa.education_status = ra.education_status
WHERE (sa.store_net_profit + COALESCE(wa.web_net_profit, 0) - COALESCE(ra.total_return_amount, 0)) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 20
