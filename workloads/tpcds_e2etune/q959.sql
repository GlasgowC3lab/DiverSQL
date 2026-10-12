WITH store_sales_agg AS (
   SELECT
       ca.ca_state AS state,
       SUM(ss.ss_net_profit) AS total_net_profit,
       SUM(ss.ss_ext_sales_price) AS total_sales_amount,
       SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
       SUM(p.p_cost) AS total_promotion_cost,
       COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions
   FROM store_sales ss
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450906 AND 2451088
     AND p.p_discount_active = 'Y'
   GROUP BY ca.ca_state
),
store_returns_agg AS (
   SELECT
       ca.ca_state AS state,
       SUM(sr.sr_net_loss) AS total_store_return_loss,
       COUNT(DISTINCT sr.sr_ticket_number) AS num_store_return_transactions
   FROM store_returns sr
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2450906 AND 2451088
   GROUP BY ca.ca_state
),
web_returns_agg AS (
   SELECT
       ca.ca_state AS state,
       SUM(wr.wr_net_loss) AS total_web_return_loss,
       COUNT(DISTINCT wr.wr_order_number) AS num_web_return_transactions
   FROM web_returns wr
   JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   WHERE wr.wr_returned_date_sk BETWEEN 2450906 AND 2451088
   GROUP BY ca.ca_state
)
SELECT
   ss.state,
   ss.total_net_profit,
   ss.total_sales_amount,
   ss.total_discount_amount,
   ss.total_promotion_cost,
   COALESCE(sr.total_store_return_loss, 0) AS total_store_return_loss,
   COALESCE(wr.total_web_return_loss, 0) AS total_web_return_loss,
   (ss.total_net_profit - COALESCE(sr.total_store_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0) - ss.total_promotion_cost) AS net_profit_after_costs,
   RANK() OVER (ORDER BY (ss.total_net_profit - COALESCE(sr.total_store_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0) - ss.total_promotion_cost) DESC) AS profit_rank
FROM store_sales_agg ss
LEFT JOIN store_returns_agg sr ON ss.state = sr.state
LEFT JOIN web_returns_agg wr ON ss.state = wr.state
WHERE ss.total_sales_amount > 20000
ORDER BY net_profit_after_costs DESC
LIMIT 100
