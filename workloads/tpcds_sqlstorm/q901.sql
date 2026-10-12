WITH
sales_union AS (
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_bill_customer_sk AS cust_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid_inc_tax AS net_paid,
    cs.cs_net_profit AS profit,
    cs.cs_order_number AS order_number,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_quantity,
    ss.ss_net_paid_inc_tax,
    ss.ss_net_profit,
    ss.ss_ticket_number,
    'store'
  FROM store_sales ss
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk,
    ws.ws_quantity,
    ws.ws_net_paid_inc_tax,
    ws.ws_net_profit,
    ws.ws_order_number,
    'web'
  FROM web_sales ws
),
sales_returns AS (
  SELECT
    s.*,
    COALESCE(cr.cr_return_quantity, sr.sr_return_quantity, wr.wr_return_quantity, 0) AS returned_quantity,
    COALESCE(cr.cr_net_loss, sr.sr_net_loss, wr.wr_net_loss, 0) AS net_loss
  FROM sales_union s
  LEFT JOIN catalog_returns cr
    ON s.sales_channel = 'catalog'
   AND s.order_number = cr.cr_order_number
   AND s.item_sk = cr.cr_item_sk
  LEFT JOIN store_returns sr
    ON s.sales_channel = 'store'
   AND s.order_number = sr.sr_ticket_number
   AND s.item_sk = sr.sr_item_sk
  LEFT JOIN web_returns wr
    ON s.sales_channel = 'web'
   AND s.order_number = wr.wr_order_number
   AND s.item_sk = wr.wr_item_sk
),
enriched AS (
  SELECT
    sr.*,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    c.c_current_cdemo_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_preferred_cust_flag,
    cd.cd_gender,
    cd.cd_education_status,
    i.i_brand,
    i.i_category,
    i.i_color,
    lower(i.i_product_name) AS product_name_lower,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_type,
    (sr.profit - COALESCE(sr.net_loss, 0)) AS profit_after_returns,
    CASE
      WHEN sr.net_paid = 0 THEN NULL
      ELSE round(((sr.profit - COALESCE(sr.net_loss, 0)) / sr.net_paid) * 100, 2)
    END AS profit_margin_pct,
    row_number() OVER (PARTITION BY sr.cust_sk ORDER BY sr.date_sk) AS sales_seq,
    sum(sr.profit - COALESCE(sr.net_loss, 0)) OVER (PARTITION BY sr.cust_sk ORDER BY sr.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    (SELECT sum(ss_inner.ss_net_paid_inc_tax)
     FROM store_sales ss_inner
     WHERE ss_inner.ss_customer_sk = sr.cust_sk
       AND ss_inner.ss_sold_date_sk = sr.date_sk) AS daily_store_net_paid,
    (SELECT min(cs_inner.cs_sold_date_sk)
     FROM catalog_sales cs_inner
     WHERE cs_inner.cs_bill_customer_sk = sr.cust_sk) AS first_purchase_date_sk
  FROM sales_returns sr
  LEFT JOIN date_dim d ON sr.date_sk = d.d_date_sk
  LEFT JOIN customer c ON sr.cust_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN item i ON sr.item_sk = i.i_item_sk
  WHERE d.d_year = 2000
    AND (c.c_birth_year BETWEEN 1950 AND 1970 OR c.c_preferred_cust_flag = 'Y')
),
avg_profit AS (
  SELECT avg(profit_after_returns) AS avg_profit FROM enriched
),
top_customers AS (
  SELECT
    e.cust_sk,
    e.full_name,
    e.cust_type,
    e.cd_gender AS gender,
    e.cd_education_status AS education,
    e.d_year,
    e.d_month_seq,
    e.sales_channel,
    e.quantity,
    e.returned_quantity,
    e.profit_after_returns,
    e.profit_margin_pct,
    e.cumulative_profit,
    row_number() OVER (ORDER BY e.cumulative_profit DESC) AS overall_rank,
    CASE
      WHEN e.profit_after_returns > (SELECT avg_profit FROM avg_profit) * 2 THEN 'High'
      WHEN e.profit_after_returns > (SELECT avg_profit FROM avg_profit) THEN 'Medium'
      ELSE 'Low'
    END AS profit_category,
    e.first_purchase_date_sk
  FROM enriched e
  WHERE e.profit_after_returns IS NOT NULL
    AND e.profit_after_returns > 0
),
no_sales AS (
  SELECT
    c.c_customer_sk AS cust_sk,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_type,
    cd.cd_gender AS gender,
    cd.cd_education_status AS education,
    NULL AS d_year,
    NULL AS d_month_seq,
    NULL AS sales_channel,
    0 AS quantity,
    0 AS returned_quantity,
    0 AS profit_after_returns,
    NULL AS profit_margin_pct,
    0 AS cumulative_profit,
    NULL AS overall_rank,
    'No Sales' AS profit_category,
    NULL AS first_purchase_date_sk
  FROM customer c
  LEFT JOIN enriched e ON c.c_customer_sk = e.cust_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE e.cust_sk IS NULL
    AND (c.c_birth_year BETWEEN 1950 AND 1970 OR c.c_preferred_cust_flag = 'Y')
),
final_result AS (
  SELECT * FROM top_customers
  UNION ALL
  SELECT * FROM no_sales
)
SELECT *
FROM final_result
WHERE overall_rank IS NULL OR overall_rank <= 100
ORDER BY overall_rank NULLS LAST, profit_after_returns DESC
