WITH catalog AS (
   SELECT 
      'Catalog' AS channel_type,
      cc.cc_name AS channel_name,
      d.d_year,
      d.d_quarter_seq,
      i.i_category,
      i.i_brand,
      SUM(cs.cs_net_profit) AS net_profit,
      SUM(cs.cs_net_paid) AS net_paid,
      COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
      SUM(cs.cs_quantity) AS total_quantity,
      AVG(cs.cs_sales_price) AS avg_sales_price,
      SUM(cs.cs_ext_discount_amt) AS total_discount,
      COUNT(*) AS transaction_count
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY cc.cc_name, d.d_year, d.d_quarter_seq, i.i_category, i.i_brand
),
web AS (
   SELECT 
      'Web' AS channel_type,
      wp.wp_url AS channel_name,
      d.d_year,
      d.d_quarter_seq,
      i.i_category,
      i.i_brand,
      SUM(ws.ws_net_profit) AS net_profit,
      SUM(ws.ws_net_paid) AS net_paid,
      COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
      SUM(ws.ws_quantity) AS total_quantity,
      AVG(ws.ws_sales_price) AS avg_sales_price,
      SUM(ws.ws_ext_discount_amt) AS total_discount,
      COUNT(*) AS transaction_count
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY wp.wp_url, d.d_year, d.d_quarter_seq, i.i_category, i.i_brand
),
store AS (
   SELECT 
      'Store' AS channel_type,
      s.s_store_name AS channel_name,
      d.d_year,
      d.d_quarter_seq,
      i.i_category,
      i.i_brand,
      SUM(ss.ss_net_profit) AS net_profit,
      SUM(ss.ss_net_paid) AS net_paid,
      COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
      SUM(ss.ss_quantity) AS total_quantity,
      AVG(ss.ss_sales_price) AS avg_sales_price,
      SUM(ss.ss_ext_discount_amt) AS total_discount,
      COUNT(*) AS transaction_count
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY s.s_store_name, d.d_year, d.d_quarter_seq, i.i_category, i.i_brand
),
combined AS (
   SELECT * FROM catalog
   UNION ALL
   SELECT * FROM web
   UNION ALL
   SELECT * FROM store
),
quarterly_base AS (
   SELECT
      channel_type,
      channel_name,
      i_category,
      i_brand,
      d_year,
      d_quarter_seq,
      net_profit,
      net_paid,
      unique_customers,
      total_quantity,
      avg_sales_price,
      total_discount,
      transaction_count,
      LAG(net_profit) OVER (PARTITION BY channel_type, channel_name, i_category, i_brand ORDER BY d_year, d_quarter_seq) AS prior_net_profit,
      ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY net_profit DESC) AS profit_rank
   FROM combined
)
SELECT
   d_year,
   d_quarter_seq,
   channel_type,
   channel_name,
   i_category,
   i_brand,
   net_profit,
   prior_net_profit,
   CASE 
      WHEN prior_net_profit IS NULL THEN NULL
      WHEN prior_net_profit = 0 THEN NULL
      ELSE (net_profit - prior_net_profit) / prior_net_profit
   END AS profit_qoq_change,
   net_paid,
   unique_customers,
   total_quantity,
   avg_sales_price,
   total_discount,
   transaction_count,
   profit_rank
FROM quarterly_base
WHERE profit_rank <= 5
ORDER BY d_year, d_quarter_seq, profit_rank
