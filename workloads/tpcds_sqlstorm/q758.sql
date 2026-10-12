WITH sales_union AS (
   SELECT
      ss.ss_sold_date_sk AS sold_date_sk,
      ss.ss_sold_time_sk AS sold_time_sk,
      ss.ss_item_sk AS item_sk,
      ss.ss_customer_sk AS customer_sk,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid AS net_paid,
      ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
      ss.ss_net_profit AS net_profit,
      'store' AS channel,
      ss.ss_store_sk AS store_sk,
      CAST(NULL AS integer) AS catalog_page_sk,
      CAST(NULL AS integer) AS web_page_sk
   FROM store_sales ss
   UNION ALL
   SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_bill_customer_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_paid_inc_tax,
      cs.cs_net_profit,
      'catalog',
      CAST(NULL AS integer),
      cs.cs_catalog_page_sk,
      CAST(NULL AS integer)
   FROM catalog_sales cs
   UNION ALL
   SELECT
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_bill_customer_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_paid_inc_tax,
      ws.ws_net_profit,
      'web',
      CAST(NULL AS integer),
      CAST(NULL AS integer),
      ws.ws_web_page_sk
   FROM web_sales ws
),
returns_union AS (
   SELECT
      sr.sr_returned_date_sk AS ret_date_sk,
      sr.sr_return_quantity AS return_quantity,
      sr.sr_return_amt AS return_amount,
      sr.sr_net_loss AS net_loss,
      sr.sr_customer_sk AS customer_sk,
      'store' AS channel,
      sr.sr_store_sk AS store_sk,
      CAST(NULL AS integer) AS catalog_page_sk,
      CAST(NULL AS integer) AS web_page_sk
   FROM store_returns sr
   UNION ALL
   SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cr.cr_returning_customer_sk,
      'catalog',
      CAST(NULL AS integer),
      cr.cr_catalog_page_sk,
      CAST(NULL AS integer)
   FROM catalog_returns cr
   UNION ALL
   SELECT
      wr.wr_returned_date_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_net_loss,
      wr.wr_refunded_customer_sk,
      'web',
      CAST(NULL AS integer),
      CAST(NULL AS integer),
      wr.wr_web_page_sk
   FROM web_returns wr
),
customer_dim AS (
   SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_preferred_cust_flag,
      COALESCE(ca.ca_city, 'UNKNOWN') AS city,
      COALESCE(ca.ca_state, 'UNKNOWN') AS state,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
   FROM customer c
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_agg AS (
   SELECT
      s.customer_sk,
      SUM(s.net_profit) AS total_profit,
      SUM(s.net_paid) AS total_paid,
      COUNT(*) AS sales_cnt,
      MAX(s.sold_date_sk) AS last_sale_date_sk,
      MIN(s.sold_date_sk) AS first_sale_date_sk
   FROM sales_union s
   GROUP BY s.customer_sk
),
returns_agg AS (
   SELECT
      r.customer_sk,
      SUM(r.net_loss) AS total_loss,
      SUM(r.return_amount) AS total_return_amount,
      COUNT(*) AS returns_cnt,
      MAX(r.ret_date_sk) AS last_return_date_sk
   FROM returns_union r
   GROUP BY r.customer_sk
),
customer_summary AS (
   SELECT
      cd.c_customer_sk,
      cd.full_name,
      cd.city,
      cd.state,
      COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0) AS net_profit,
      COALESCE(sa.total_paid, 0) - COALESCE(ra.total_return_amount, 0) AS net_paid,
      COALESCE(sa.sales_cnt, 0) AS sales_cnt,
      COALESCE(ra.returns_cnt, 0) AS returns_cnt,
      CASE
         WHEN cd.c_preferred_cust_flag = 'Y' THEN 'Preferred'
         ELSE 'Standard'
      END AS customer_type,
      CASE
         WHEN (COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0)) > 10000 THEN 'HIGH'
         WHEN (COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0)) BETWEEN 0 AND 10000 THEN 'MEDIUM'
         ELSE 'LOW'
      END AS profit_category,
      CAST(date_add('day', cd.c_customer_sk % 30, DATE '2000-01-01') AS varchar) AS dummy_date_str
   FROM customer_dim cd
   LEFT JOIN sales_agg sa ON cd.c_customer_sk = sa.customer_sk
   LEFT JOIN returns_agg ra ON cd.c_customer_sk = ra.customer_sk
),
ranked_customers AS (
   SELECT
      cs.*,
      ROW_NUMBER() OVER (ORDER BY cs.net_profit DESC) AS profit_rank,
      SUM(cs.net_profit) OVER (ORDER BY cs.net_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
   FROM customer_summary cs
)
SELECT
   rc.c_customer_sk,
   rc.full_name,
   rc.city,
   rc.state,
   rc.customer_type,
   rc.profit_category,
   rc.net_profit,
   rc.net_paid,
   rc.sales_cnt,
   rc.returns_cnt,
   rc.profit_rank,
   rc.cumulative_profit,
   (SELECT i.i_product_name
    FROM sales_union su
    JOIN item i ON su.item_sk = i.i_item_sk
    WHERE su.customer_sk = rc.c_customer_sk
    GROUP BY i.i_product_name
    ORDER BY SUM(su.quantity) DESC
    LIMIT 1) AS top_product,
   CASE WHEN REGEXP_LIKE(rc.city, '^[A-Z]{3,}$') THEN 'ALLCAPS_CITY' ELSE 'NORMAL_CITY' END AS city_name_flag
FROM ranked_customers rc
WHERE rc.profit_rank <= 10
ORDER BY rc.profit_rank
