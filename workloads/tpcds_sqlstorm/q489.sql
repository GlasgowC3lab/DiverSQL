WITH max_year AS (
  SELECT MAX(d_year) AS year
  FROM date_dim
),
store_agg AS (
  SELECT 
    ss.ss_customer_sk AS customer_sk,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    MAX(ss.ss_sold_date_sk) AS max_date_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  CROSS JOIN max_year my
  WHERE d.d_year = my.year
  GROUP BY ss.ss_customer_sk
),
catalog_agg AS (
  SELECT 
    cs.cs_bill_customer_sk AS customer_sk,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    MAX(cs.cs_sold_date_sk) AS max_date_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  CROSS JOIN max_year my
  WHERE d.d_year = my.year
  GROUP BY cs.cs_bill_customer_sk
),
web_agg AS (
  SELECT 
    ws.ws_bill_customer_sk AS customer_sk,
    SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    MAX(ws.ws_sold_date_sk) AS max_date_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  CROSS JOIN max_year my
  WHERE d.d_year = my.year
  GROUP BY ws.ws_bill_customer_sk
),
combined_agg AS (
  SELECT
    COALESCE(s.customer_sk, c.customer_sk, w.customer_sk) AS customer_sk,
    COALESCE(s.total_net_paid, 0) + COALESCE(c.total_net_paid, 0) + COALESCE(w.total_net_paid, 0) AS total_net_paid,
    COALESCE(s.total_net_profit, 0) + COALESCE(c.total_net_profit, 0) + COALESCE(w.total_net_profit, 0) AS total_net_profit,
    COALESCE(s.total_quantity, 0) + COALESCE(c.total_quantity, 0) + COALESCE(w.total_quantity, 0) AS total_quantity,
    GREATEST(COALESCE(s.max_date_sk, -1), COALESCE(c.max_date_sk, -1), COALESCE(w.max_date_sk, -1)) AS max_date_sk,
    (CASE WHEN s.customer_sk IS NOT NULL THEN 1 ELSE 0 END
     + CASE WHEN c.customer_sk IS NOT NULL THEN 1 ELSE 0 END
     + CASE WHEN w.customer_sk IS NOT NULL THEN 1 ELSE 0 END) AS channel_count
  FROM store_agg s
  FULL OUTER JOIN catalog_agg c ON s.customer_sk = c.customer_sk
  FULL OUTER JOIN web_agg w ON COALESCE(s.customer_sk, c.customer_sk) = w.customer_sk
),
sales_all AS (
  SELECT 
    ss.ss_customer_sk AS customer_sk,
    ss.ss_sold_date_sk AS date_sk,
    'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  CROSS JOIN max_year my
  WHERE d.d_year = my.year
  UNION ALL
  SELECT 
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_sold_date_sk AS date_sk,
    'catalog' AS channel
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  CROSS JOIN max_year my
  WHERE d.d_year = my.year
  UNION ALL
  SELECT 
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_sold_date_sk AS date_sk,
    'web' AS channel
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  CROSS JOIN max_year my
  WHERE d.d_year = my.year
),
recent_channel AS (
  SELECT 
    customer_sk,
    channel,
    ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY date_sk DESC) AS rn
  FROM sales_all
),
final_data AS (
  SELECT 
    c.c_customer_sk,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(agg.total_net_paid, 0) AS total_net_paid,
    COALESCE(agg.total_net_profit, 0) AS total_net_profit,
    COALESCE(agg.total_quantity, 0) AS total_quantity,
    agg.channel_count,
    d_last.d_date AS last_purchase_date,
    CONCAT(c.c_customer_id, ' - ', COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS customer_label,
    CONCAT(substring(c.c_first_name, 1, 1), '.', substring(c.c_last_name, 1, 1), '.') AS customer_initials,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    CASE 
      WHEN COALESCE(agg.total_net_profit, 0) > 0 THEN 'Profit'
      WHEN COALESCE(agg.total_net_profit, 0) < 0 THEN 'Loss'
      ELSE 'BreakEven'
    END AS profit_category,
    rc.channel AS recent_channel,
    CASE 
      WHEN rc.channel = 'store' THEN 'S' 
      WHEN rc.channel = 'catalog' THEN 'C' 
      WHEN rc.channel = 'web' THEN 'W' 
      ELSE 'U' 
    END AS recent_channel_code,
    (SELECT COUNT(DISTINCT sa.channel) FROM sales_all sa WHERE sa.customer_sk = c.c_customer_sk) AS distinct_channel_cnt,
    CASE 
      WHEN EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = c.c_customer_sk 
          AND ss.ss_ext_sales_price > 1000
      ) THEN 1 
      ELSE 0 
    END AS has_high_store_sales
  FROM customer c
  LEFT JOIN combined_agg agg ON c.c_customer_sk = agg.customer_sk
  LEFT JOIN date_dim d_last ON agg.max_date_sk = d_last.d_date_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN recent_channel rc ON c.c_customer_sk = rc.customer_sk AND rc.rn = 1
)
SELECT 
  ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
  customer_label,
  customer_initials,
  total_net_paid,
  total_net_profit,
  total_quantity,
  COALESCE(last_purchase_date, DATE '1900-01-01') AS last_purchase_date,
  profit_category,
  channel_count,
  distinct_channel_cnt,
  recent_channel,
  recent_channel_code,
  cd_gender,
  cd_marital_status,
  cd_credit_rating,
  has_high_store_sales,
  CASE 
    WHEN total_quantity > 0 THEN total_net_profit / NULLIF(total_quantity, 0)
    ELSE NULL
  END AS avg_profit_per_qty
FROM final_data
WHERE total_net_profit IS NOT NULL
ORDER BY profit_rank
LIMIT 10
