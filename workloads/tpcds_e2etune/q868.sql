WITH sales AS (
  SELECT p.p_promo_sk,
         p.p_channel_email,
         cd.cd_demo_sk,
         SUM(cs.cs_ext_sales_price) AS total_sales,
         SUM(cs.cs_ext_discount_amt) AS total_discount
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_ext_list_price > 1000
    AND cd.cd_credit_rating = 'A'
  GROUP BY p.p_promo_sk, p.p_channel_email, cd.cd_demo_sk
),
store_ret AS (
  SELECT cd.cd_demo_sk,
         SUM(sr.sr_return_amt_inc_tax) AS total_store_return
  FROM store_returns sr
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_credit_rating = 'A'
  GROUP BY cd.cd_demo_sk
),
web_ret AS (
  SELECT cd.cd_demo_sk,
         SUM(wr.wr_return_amt_inc_tax) AS total_web_return
  FROM web_returns wr
  JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_credit_rating = 'A'
  GROUP BY cd.cd_demo_sk
)
SELECT
  s.p_promo_sk,
  s.p_channel_email,
  COUNT(DISTINCT s.cd_demo_sk) AS num_customers,
  SUM(s.total_sales) AS total_sales_amount,
  COALESCE(SUM(sr.total_store_return), 0) AS total_store_return_amount,
  COALESCE(SUM(wr.total_web_return), 0) AS total_web_return_amount,
  SUM(s.total_sales) - COALESCE(SUM(sr.total_store_return), 0) - COALESCE(SUM(wr.total_web_return), 0) AS net_impact,
  RANK() OVER (ORDER BY SUM(s.total_sales) - COALESCE(SUM(sr.total_store_return), 0) - COALESCE(SUM(wr.total_web_return), 0) DESC) AS net_impact_rank
FROM sales s
LEFT JOIN store_ret sr ON s.cd_demo_sk = sr.cd_demo_sk
LEFT JOIN web_ret wr ON s.cd_demo_sk = wr.cd_demo_sk
GROUP BY s.p_promo_sk, s.p_channel_email
ORDER BY net_impact DESC
LIMIT 10
