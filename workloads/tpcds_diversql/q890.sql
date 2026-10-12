WITH sales_data AS (
   SELECT
       ss.ss_customer_sk,
       ss.ss_item_sk,
       ss.ss_net_profit,
       i.i_category,
       p.p_promo_name,
       s.s_store_name,
       ca.ca_state
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE i.i_category = 'Books'                     -- filter 1
     AND p.p_start_date_sk BETWEEN 2450164 AND 2450596   -- filter 2
     AND s.s_state = 'CA'                               -- filter 3
),

catalog_ret_data AS (
   SELECT
       cr.cr_refunded_customer_sk,
       cr.cr_item_sk,
       cr.cr_net_loss,
       i.i_category,
       sm.sm_type,
       ca_ret.ca_state
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_address ca_ret ON cr.cr_refunded_addr_sk = ca_ret.ca_address_sk
   WHERE cr.cr_net_loss > 100.00                     -- filter 4
),

web_ret_data AS (
   SELECT
       wr.wr_refunded_customer_sk,
       wr.wr_item_sk,
       wr.wr_return_amt,
       i.i_category,
       ca_web.ca_state
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN customer_address ca_web ON wr.wr_refunded_addr_sk = ca_web.ca_address_sk
   WHERE wr.wr_return_amt > 50.00                     -- filter 5
),

customer_intersect AS (
   SELECT DISTINCT ss.ss_customer_sk AS cust_sk
   FROM sales_data ss
   INTERSECT
   SELECT DISTINCT cr.cr_refunded_customer_sk
   FROM catalog_ret_data cr
),

combined AS (
   SELECT
       COALESCE(ss.ss_customer_sk, wr.wr_refunded_customer_sk) AS customer_sk,
       ss.ss_net_profit,
       wr.wr_return_amt,
       ss.ss_item_sk,
       ss.s_store_name,
       ss.p_promo_name,
       ss.ca_state,
       ROW_NUMBER() OVER (
           PARTITION BY COALESCE(ss.ss_customer_sk, wr.wr_refunded_customer_sk)
           ORDER BY ss.ss_net_profit DESC NULLS LAST
       ) AS rn
   FROM sales_data ss
   FULL OUTER JOIN web_ret_data wr
       ON ss.ss_item_sk = wr.wr_item_sk
      AND ss.ss_customer_sk = wr.wr_refunded_customer_sk
   WHERE EXISTS (
         SELECT 1
         FROM catalog_ret_data cr
         WHERE cr.cr_item_sk = COALESCE(ss.ss_item_sk, wr.wr_item_sk)
           AND cr.cr_refunded_customer_sk = COALESCE(ss.ss_customer_sk, wr.wr_refunded_customer_sk)
   )
   AND COALESCE(ss.ss_customer_sk, wr.wr_refunded_customer_sk) IN (SELECT cust_sk FROM customer_intersect)
)

SELECT DISTINCT
    customer_sk,
    ss_net_profit,
    wr_return_amt,
    ss_item_sk,
    s_store_name,
    p_promo_name,
    ca_state,
    rn
FROM combined
WHERE rn <= 10
ORDER BY ss_net_profit DESC
LIMIT 100
