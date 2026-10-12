WITH
sales_union AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_promo_sk AS promo_sk,
          cs.cs_net_profit AS net_profit,
          cs.cs_net_paid AS net_paid,
          cs.cs_ext_discount_amt AS discount_amt,
          ca.ca_state AS state,
          'catalog' AS channel
   FROM catalog_sales cs
   JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
   UNION ALL
   SELECT ss.ss_sold_date_sk AS date_sk,
          ss.ss_item_sk AS item_sk,
          ss.ss_promo_sk AS promo_sk,
          ss.ss_net_profit AS net_profit,
          ss.ss_net_paid AS net_paid,
          ss.ss_ext_discount_amt AS discount_amt,
          s.s_state AS state,
          'store' AS channel
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   UNION ALL
   SELECT ws.ws_sold_date_sk AS date_sk,
          ws.ws_item_sk AS item_sk,
          ws.ws_promo_sk AS promo_sk,
          ws.ws_net_profit AS net_profit,
          ws.ws_net_paid AS net_paid,
          ws.ws_ext_discount_amt AS discount_amt,
          ca2.ca_state AS state,
          'web' AS channel
   FROM web_sales ws
   JOIN customer_address ca2 ON ws.ws_ship_addr_sk = ca2.ca_address_sk
),
returns_union AS (
   SELECT cr.cr_returned_date_sk AS date_sk,
          cr.cr_item_sk AS item_sk,
          cr.cr_refunded_customer_sk AS customer_sk,
          cr.cr_net_loss AS net_loss,
          cr.cr_return_quantity AS quantity,
          ca.ca_state AS state,
          'catalog' AS channel
   FROM catalog_returns cr
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   UNION ALL
   SELECT sr.sr_returned_date_sk AS date_sk,
          sr.sr_item_sk AS item_sk,
          sr.sr_customer_sk AS customer_sk,
          sr.sr_net_loss AS net_loss,
          sr.sr_return_quantity AS quantity,
          s2.s_state AS state,
          'store' AS channel
   FROM store_returns sr
   JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
   UNION ALL
   SELECT wr.wr_returned_date_sk AS date_sk,
          wr.wr_item_sk AS item_sk,
          wr.wr_refunded_customer_sk AS customer_sk,
          wr.wr_net_loss AS net_loss,
          wr.wr_return_quantity AS quantity,
          ca3.ca_state AS state,
          'web' AS channel
   FROM web_returns wr
   JOIN customer_address ca3 ON wr.wr_refunded_addr_sk = ca3.ca_address_sk
),
sales_with_date AS (
   SELECT su.*,
          d.d_year AS year,
          d.d_month_seq AS month
   FROM sales_union su
   JOIN date_dim d ON su.date_sk = d.d_date_sk
),
returns_with_date AS (
   SELECT ru.*,
          d.d_year AS year,
          d.d_month_seq AS month
   FROM returns_union ru
   JOIN date_dim d ON ru.date_sk = d.d_date_sk
),
sales_agg AS (
   SELECT
       state,
       year,
       month,
       SUM(net_paid) AS total_sales,
       SUM(net_profit) AS total_profit,
       SUM(discount_amt) AS total_discount,
       COUNT(*) FILTER (WHERE promo_sk IS NOT NULL) AS promo_sales_count,
       SUM(net_paid) FILTER (WHERE promo_sk IS NOT NULL) AS promo_sales_amount
   FROM sales_with_date
   GROUP BY state, year, month
),
returns_agg AS (
   SELECT
       state,
       year,
       month,
       SUM(net_loss) AS total_return_loss
   FROM returns_with_date
   GROUP BY state, year, month
),
promo_cost_agg AS (
   SELECT
       s.state,
       s.year,
       s.month,
       SUM(p.p_cost) AS total_promo_cost,
       COUNT(DISTINCT s.promo_sk) AS distinct_promos
   FROM sales_with_date s
   JOIN promotion p ON s.promo_sk = p.p_promo_sk
   GROUP BY s.state, s.year, s.month
),
item_profit_agg AS (
   SELECT
       state,
       year,
       month,
       item_sk,
       SUM(net_profit) AS profit
   FROM sales_with_date
   GROUP BY state, year, month, item_sk
),
top_items AS (
   SELECT
       ip.state,
       ip.year,
       ip.month,
       slice(
           array_agg(
               CONCAT(i.i_product_name, ':', CAST(ip.profit AS VARCHAR))
               ORDER BY ip.profit DESC
           ),
           1,
           5
       ) AS top_5_items_by_profit
   FROM item_profit_agg ip
   JOIN item i ON ip.item_sk = i.i_item_sk
   GROUP BY ip.state, ip.year, ip.month
)
SELECT
   a.state,
   a.year,
   a.month,
   a.total_sales,
   a.total_profit,
   a.total_discount,
   a.promo_sales_count,
   a.promo_sales_amount,
   COALESCE(r.total_return_loss, 0) AS total_return_loss,
   a.total_sales - COALESCE(r.total_return_loss, 0) AS net_revenue,
   a.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_adj,
   CASE WHEN a.total_sales > 0 THEN (a.total_discount / a.total_sales) * 100 ELSE NULL END AS discount_pct,
   COALESCE(p.total_promo_cost, 0) AS total_promo_cost,
   COALESCE(p.distinct_promos, 0) AS distinct_promos,
   ti.top_5_items_by_profit
FROM sales_agg a
LEFT JOIN returns_agg r
   ON a.state = r.state AND a.year = r.year AND a.month = r.month
LEFT JOIN promo_cost_agg p
   ON a.state = p.state AND a.year = p.year AND a.month = p.month
LEFT JOIN top_items ti
   ON a.state = ti.state AND a.year = ti.year AND a.month = ti.month
ORDER BY a.state, a.year, a.month
