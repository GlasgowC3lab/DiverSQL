WITH cust_total AS (
  SELECT
    cr.cr_returning_customer_sk,
    cr.cr_returning_cdemo_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS total_return_cnt
  FROM catalog_returns cr
  GROUP BY cr.cr_returning_customer_sk, cr.cr_returning_cdemo_sk
),
cust_ranked AS (
  SELECT
    ct.*, 
    DENSE_RANK() OVER (ORDER BY total_return_amount DESC) AS amount_rank,
    CASE
      WHEN total_return_amount >= 15000 THEN 'Platinum'
      WHEN total_return_amount >= 8000 THEN 'Gold'
      WHEN total_return_amount >= 3000 THEN 'Silver'
      ELSE 'Bronze'
    END AS tier
  FROM cust_total ct
),
cust_reason AS (
  SELECT
    cr.cr_returning_customer_sk,
    cr.cr_reason_sk,
    SUM(cr.cr_return_amount) AS amount_by_reason,
    COUNT(*) AS cnt_by_reason
  FROM catalog_returns cr
  GROUP BY cr.cr_returning_customer_sk, cr.cr_reason_sk
),
cust_category AS (
  SELECT
    cr.cr_returning_customer_sk,
    i.i_category,
    SUM(cr.cr_return_amount) AS amount_by_category,
    ROW_NUMBER() OVER (PARTITION BY cr.cr_returning_customer_sk ORDER BY SUM(cr.cr_return_amount) DESC) AS category_rank
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY cr.cr_returning_customer_sk, i.i_category
)
SELECT
  cr.cr_returning_customer_sk AS returning_customer_sk,
  cr.total_return_amount,
  cr.total_return_cnt,
  cr.tier,
  cr.amount_rank,
  cd.cd_marital_status,
  cd.cd_gender,
  cr_reason.cr_reason_sk,
  cr_reason.amount_by_reason,
  (cr_reason.amount_by_reason * 100.0) / cr.total_return_amount AS pct_of_total_by_reason,
  cat.i_category,
  cat.amount_by_category,
  (cat.amount_by_category * 100.0) / cr.total_return_amount AS pct_of_total_by_category
FROM cust_ranked cr
JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN cust_reason cr_reason ON cr.cr_returning_customer_sk = cr_reason.cr_returning_customer_sk
JOIN (
  SELECT cr_returning_customer_sk, i_category, amount_by_category
  FROM cust_category
  WHERE category_rank = 1
) cat ON cr.cr_returning_customer_sk = cat.cr_returning_customer_sk
WHERE cr.amount_rank <= 5
ORDER BY cr.total_return_amount DESC
