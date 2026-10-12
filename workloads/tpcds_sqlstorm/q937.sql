WITH unified_sales AS (
   SELECT cs.cs_bill_customer_sk AS customer_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_order_number AS order_number,
          cs.cs_quantity AS quantity,
          cs.cs_net_profit AS net_profit,
          cs.cs_sold_date_sk AS date_sk,
          'catalog' AS sales_channel,
          cs.cs_promo_sk AS promo_sk,
          cs.cs_ext_discount_amt AS discount_amt
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_customer_sk,
          ss.ss_item_sk,
          ss.ss_ticket_number,
          ss.ss_quantity,
          ss.ss_net_profit,
          ss.ss_sold_date_sk,
          'store',
          ss.ss_promo_sk,
          ss.ss_ext_discount_amt
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_bill_customer_sk,
          ws.ws_item_sk,
          ws.ws_order_number,
          ws.ws_quantity,
          ws.ws_net_profit,
          ws.ws_sold_date_sk,
          'web',
          ws.ws_promo_sk,
          ws.ws_ext_discount_amt
   FROM web_sales ws
),
unified_returns AS (
   SELECT cr.cr_returning_customer_sk AS customer_sk,
          cr.cr_item_sk AS item_sk,
          cr.cr_return_quantity AS return_quantity,
          cr.cr_returned_date_sk AS date_sk,
          'catalog' AS return_channel
   FROM catalog_returns cr
   UNION ALL
   SELECT sr.sr_customer_sk,
          sr.sr_item_sk,
          sr.sr_return_quantity,
          sr.sr_returned_date_sk,
          'store'
   FROM store_returns sr
   UNION ALL
   SELECT wr.wr_refunded_customer_sk,
          wr.wr_item_sk,
          wr.wr_return_quantity,
          wr.wr_returned_date_sk,
          'web'
   FROM web_returns wr
),
sales_agg AS (
   SELECT customer_sk,
          item_sk,
          SUM(quantity) AS total_quantity,
          SUM(net_profit) AS total_net_profit,
          COUNT(DISTINCT order_number) AS distinct_orders,
          MIN(date_sk) AS first_purchase_date_sk,
          MAX(date_sk) AS last_purchase_date_sk,
          COUNT(DISTINCT sales_channel) AS sales_channels_used
   FROM unified_sales
   GROUP BY customer_sk, item_sk
),
returns_agg AS (
   SELECT customer_sk,
          item_sk,
          SUM(return_quantity) AS total_return_quantity,
          COUNT(*) AS return_events
   FROM unified_returns
   GROUP BY customer_sk, item_sk
),
dim_customer AS (
   SELECT c.c_customer_sk,
          c.c_first_name,
          c.c_last_name,
          c.c_preferred_cust_flag,
          cd.cd_gender,
          cd.cd_education_status,
          hd.hd_income_band_sk,
          ib.ib_lower_bound,
          ib.ib_upper_bound,
          ca.ca_address_id,
          ca.ca_city,
          ca.ca_state,
          ca.ca_country
   FROM customer c
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT *
FROM (
   SELECT
      c.c_customer_sk,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
      CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
      COALESCE(c.cd_gender, 'Unknown') AS gender,
      COALESCE(concat_ws(', ', c.ca_address_id, c.ca_city, c.ca_state, c.ca_country), 'No Address') AS full_address,
      sa.item_sk,
      i.i_product_name,
      sa.total_quantity,
      sa.total_net_profit,
      sa.distinct_orders,
      COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
      CASE WHEN COALESCE(ra.total_return_quantity, 0) > sa.total_quantity THEN 'Over-Returned' ELSE 'OK' END AS return_status,
      sa.sales_channels_used,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY sa.total_net_profit DESC) AS profit_rank,
      (SELECT COUNT(DISTINCT us.promo_sk) FROM unified_sales us WHERE us.customer_sk = c.c_customer_sk) AS total_promo_used,
      (SELECT MAX(p.p_promo_id)
         FROM promotion p
         JOIN unified_sales us2 ON us2.promo_sk = p.p_promo_sk
         WHERE us2.customer_sk = c.c_customer_sk
           AND us2.item_sk = sa.item_sk
           AND us2.date_sk = sa.last_purchase_date_sk) AS last_promo_id,
      CASE WHEN sa.total_quantity = 0 THEN 0
           ELSE ROUND(
               (SELECT SUM(us.discount_amt)
                FROM unified_sales us
                WHERE us.customer_sk = c.c_customer_sk
                  AND us.item_sk = sa.item_sk) / sa.total_quantity, 4)
       END AS avg_discount_ratio,
      CASE
         WHEN c.ib_upper_bound >= 100000 THEN 'High Income'
         WHEN c.ib_upper_bound >= 50000 THEN 'Middle Income'
         ELSE 'Low Income'
      END AS income_bracket
   FROM sales_agg sa
   JOIN dim_customer c ON sa.customer_sk = c.c_customer_sk
   LEFT JOIN returns_agg ra ON sa.customer_sk = ra.customer_sk AND sa.item_sk = ra.item_sk
   JOIN item i ON sa.item_sk = i.i_item_sk
   WHERE sa.total_net_profit > 0
     AND sa.sales_channels_used >= 2
     AND EXISTS (
        SELECT 1 FROM date_dim d
        WHERE d.d_date_sk = sa.last_purchase_date_sk
          AND d.d_year BETWEEN 2000 AND 2002
          AND d.d_day_name = 'Monday'
     )
) t
WHERE t.profit_rank <= 5
ORDER BY t.c_customer_sk, t.profit_rank
