WITH
sales_union AS (
  SELECT
    cs_bill_customer_sk AS customer_sk,
    'catalog' AS channel,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    SUM(cs_quantity) AS total_quantity,
    MAX(cs_sold_date_sk) AS last_sale_date_sk
  FROM catalog_sales
  GROUP BY cs_bill_customer_sk
  UNION ALL
  SELECT
    ss_customer_sk AS customer_sk,
    'store' AS channel,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    SUM(ss_quantity) AS total_quantity,
    MAX(ss_sold_date_sk) AS last_sale_date_sk
  FROM store_sales
  GROUP BY ss_customer_sk
  UNION ALL
  SELECT
    ws_bill_customer_sk AS customer_sk,
    'web' AS channel,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    SUM(ws_quantity) AS total_quantity,
    MAX(ws_sold_date_sk) AS last_sale_date_sk
  FROM web_sales
  GROUP BY ws_bill_customer_sk
),
sales_agg AS (
  SELECT
    customer_sk,
    SUM(total_sales) AS total_sales_all,
    SUM(total_profit) AS total_profit_all,
    SUM(total_quantity) AS total_quantity_all,
    MAX(last_sale_date_sk) AS most_recent_sale_sk
  FROM sales_union
  GROUP BY customer_sk
),
returns_union AS (
  SELECT
    cr_returning_customer_sk AS customer_sk,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_return_loss
  FROM catalog_returns
  GROUP BY cr_returning_customer_sk
  UNION ALL
  SELECT
    sr_customer_sk AS customer_sk,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_net_loss) AS total_return_loss
  FROM store_returns
  GROUP BY sr_customer_sk
  UNION ALL
  SELECT
    wr_returning_customer_sk AS customer_sk,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_net_loss) AS total_return_loss
  FROM web_returns
  GROUP BY wr_returning_customer_sk
),
returns_agg AS (
  SELECT
    customer_sk,
    SUM(total_return_amount) AS total_return_amount_all,
    SUM(total_return_loss) AS total_return_loss_all
  FROM returns_union
  GROUP BY customer_sk
),
customer_detail AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(c.c_preferred_cust_flag, 'N') AS preferred_cust_flag
  FROM customer c
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_sales AS (
  SELECT
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.preferred_cust_flag,
    COALESCE(sa.total_sales_all, 0) AS total_sales,
    COALESCE(sa.total_profit_all, 0) AS total_profit,
    COALESCE(sa.total_quantity_all, 0) AS total_quantity,
    COALESCE(ra.total_return_amount_all, 0) AS total_returns,
    COALESCE(ra.total_return_loss_all, 0) AS total_return_loss,
    (COALESCE(sa.total_sales_all, 0) - COALESCE(ra.total_return_amount_all, 0)) AS net_sales,
    (COALESCE(sa.total_profit_all, 0) - COALESCE(ra.total_return_loss_all, 0)) AS net_profit,
    CASE
      WHEN COALESCE(sa.total_sales_all, 0) = 0 THEN 0
      ELSE COALESCE(sa.total_profit_all, 0) / COALESCE(sa.total_sales_all, 0)
    END AS profit_margin,
    DATE_ADD(
      'day',
      CAST(ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(sa.total_profit_all, 0) DESC) - 1 AS integer),
      DATE '2000-01-01'
    ) AS gender_rank_date
  FROM customer_detail cd
  LEFT JOIN sales_agg sa ON cd.c_customer_sk = sa.customer_sk
  LEFT JOIN returns_agg ra ON cd.c_customer_sk = ra.customer_sk
),
demographic_stats AS (
  SELECT
    cd_gender,
    AVG(net_profit) AS avg_net_profit_by_gender,
    approx_percentile(net_profit, 0.5) AS median_net_profit_by_gender
  FROM customer_sales
  GROUP BY cd_gender
),
final_set AS (
  SELECT
    cs.c_customer_sk,
    CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
    cs.cd_gender,
    cs.total_sales,
    cs.total_profit,
    cs.net_profit,
    cs.profit_margin,
    ds.avg_net_profit_by_gender,
    CASE
      WHEN cs.net_profit > ds.avg_net_profit_by_gender THEN 'ABOVE_AVG'
      WHEN cs.net_profit < ds.avg_net_profit_by_gender THEN 'BELOW_AVG'
      ELSE 'EQUAL_AVG'
    END AS profit_vs_gender_avg,
    ROW_NUMBER() OVER (ORDER BY cs.net_profit DESC) AS overall_profit_rank,
    (
      SELECT AVG(c2.net_profit)
      FROM customer_sales c2
      WHERE c2.preferred_cust_flag = cs.preferred_cust_flag
    ) AS avg_profit_same_pref_flag,
    COALESCE(NULLIF(cs.preferred_cust_flag, 'N'), 'UNKNOWN') AS pref_flag_clean
  FROM customer_sales cs
  JOIN demographic_stats ds ON cs.cd_gender = ds.cd_gender
),
no_sales_with_returns AS (
  SELECT
    ra.customer_sk AS c_customer_sk,
    'No Sales' AS full_name,
    NULL AS cd_gender,
    0 AS total_sales,
    0 AS total_profit,
    0 AS net_profit,
    0 AS profit_margin,
    NULL AS avg_net_profit_by_gender,
    'RETURN_ONLY' AS profit_vs_gender_avg,
    NULL AS overall_profit_rank,
    NULL AS avg_profit_same_pref_flag,
    NULL AS pref_flag_clean
  FROM returns_agg ra
  LEFT JOIN sales_agg sa ON ra.customer_sk = sa.customer_sk
  WHERE sa.customer_sk IS NULL
)
SELECT *
FROM final_set
UNION ALL
SELECT *
FROM no_sales_with_returns
ORDER BY net_profit DESC NULLS LAST
LIMIT 100
