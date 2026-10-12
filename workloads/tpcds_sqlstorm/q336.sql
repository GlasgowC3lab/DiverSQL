WITH combined_sales AS (
   SELECT 
       d.d_year,
       d.d_month_seq,
       i.i_category,
       'store' AS channel,
       ss.ss_ext_sales_price AS gross_sales,
       COALESCE(sr.sr_return_amt_inc_tax, 0) AS return_amt,
       ss.ss_net_profit AS profit,
       COALESCE(sr.sr_net_loss, 0) AS return_loss,
       ss.ss_customer_sk AS customer_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN store_returns sr 
       ON ss.ss_ticket_number = sr.sr_ticket_number 
          AND ss.ss_item_sk = sr.sr_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   UNION ALL
   SELECT 
       d.d_year,
       d.d_month_seq,
       i.i_category,
       'catalog' AS channel,
       cs.cs_ext_sales_price AS gross_sales,
       COALESCE(cr.cr_return_amt_inc_tax, 0) AS return_amt,
       cs.cs_net_profit AS profit,
       COALESCE(cr.cr_net_loss, 0) AS return_loss,
       cs.cs_bill_customer_sk AS customer_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN catalog_returns cr 
       ON cs.cs_order_number = cr.cr_order_number 
          AND cs.cs_item_sk = cr.cr_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   UNION ALL
   SELECT 
       d.d_year,
       d.d_month_seq,
       i.i_category,
       'web' AS channel,
       ws.ws_ext_sales_price AS gross_sales,
       COALESCE(wr.wr_return_amt_inc_tax, 0) AS return_amt,
       ws.ws_net_profit AS profit,
       COALESCE(wr.wr_net_loss, 0) AS return_loss,
       ws.ws_bill_customer_sk AS customer_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr 
       ON ws.ws_order_number = wr.wr_order_number 
          AND ws.ws_item_sk = wr.wr_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
),
agg AS (
   SELECT
       d_year,
       d_month_seq,
       i_category,
       channel,
       sum(gross_sales) AS total_gross_sales,
       sum(return_amt) AS total_returns,
       sum(gross_sales) - sum(return_amt) AS net_sales,
       sum(profit) AS total_gross_profit,
       sum(return_loss) AS total_return_loss,
       sum(profit) - sum(return_loss) AS net_profit,
       approx_distinct(customer_sk) AS approx_unique_customers
   FROM combined_sales
   GROUP BY d_year, d_month_seq, i_category, channel
   HAVING sum(gross_sales) - sum(return_amt) > 10000
)
SELECT
   d_year,
   d_month_seq,
   i_category,
   channel,
   total_gross_sales,
   total_returns,
   net_sales,
   total_gross_profit,
   total_return_loss,
   net_profit,
   approx_unique_customers,
   row_number() OVER (PARTITION BY i_category ORDER BY net_sales DESC) AS category_rank,
   sum(net_sales) OVER (PARTITION BY d_year, d_month_seq) AS total_net_sales_month,
   net_sales - lag(net_sales) OVER (PARTITION BY channel, i_category ORDER BY d_year, d_month_seq) AS net_sales_mom_change,
   CASE 
       WHEN lag(net_sales) OVER (PARTITION BY channel, i_category ORDER BY d_year, d_month_seq) = 0 THEN NULL
       ELSE (net_sales - lag(net_sales) OVER (PARTITION BY channel, i_category ORDER BY d_year, d_month_seq)) / lag(net_sales) OVER (PARTITION BY channel, i_category ORDER BY d_year, d_month_seq) * 100
   END AS net_sales_mom_pct
FROM agg
ORDER BY d_year, d_month_seq, i_category, channel
