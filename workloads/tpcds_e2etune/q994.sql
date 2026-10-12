WITH ws_agg AS (
  SELECT ws_bill_customer_sk AS customer_sk,
         SUM(ws_net_profit) AS total_web_profit
  FROM web_sales
  WHERE ws_sold_date_sk BETWEEN 2452000 AND 2453000
  GROUP BY ws_bill_customer_sk
),
sr_agg AS (
  SELECT sr_customer_sk AS customer_sk,
         SUM(sr_net_loss) AS total_store_loss
  FROM store_returns
  WHERE sr_returned_date_sk BETWEEN 2452000 AND 2453000
  GROUP BY sr_customer_sk
),
base AS (
  SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    COALESCE(SUM(ws_agg.total_web_profit), 0) AS total_web_profit,
    COALESCE(SUM(sr_agg.total_store_loss), 0) AS total_store_loss,
    CASE WHEN SUM(ws_agg.total_web_profit) = 0 THEN NULL
         ELSE SUM(sr_agg.total_store_loss) / SUM(ws_agg.total_web_profit)
    END AS loss_to_profit_ratio
  FROM customer c
  JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN ws_agg ON ws_agg.customer_sk = c.c_customer_sk
  LEFT JOIN sr_agg ON sr_agg.customer_sk = c.c_customer_sk
  WHERE c.c_birth_country IN ('IRELAND', 'CYPRUS')
    AND c.c_birth_year BETWEEN 1950 AND 1970
  GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
  HAVING COUNT(DISTINCT c.c_customer_sk) >= 5
)
SELECT
  *,
  RANK() OVER (ORDER BY loss_to_profit_ratio DESC NULLS LAST) AS loss_profit_rank
FROM base
ORDER BY loss_to_profit_ratio DESC NULLS LAST
LIMIT 100
