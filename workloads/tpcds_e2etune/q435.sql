WITH filtered_sales AS (
  SELECT
    ss.ss_net_profit,
    ss.ss_ext_discount_amt,
    ss.ss_quantity,
    ss.ss_sales_price,
    i.i_category,
    i.i_color,
    i.i_current_price,
    i.i_manufact_id,
    i.i_manager_id,
    p.p_channel_tv,
    p.p_discount_active,
    p.p_response_target,
    ss.ss_sold_date_sk,
    p.p_start_date_sk,
    p.p_end_date_sk
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
   AND p.p_item_sk = i.i_item_sk
  WHERE i.i_color IN ('red', 'pink')
    AND i.i_current_price > 5
    AND i.i_manufact_id IN (212, 479)
    AND i.i_manager_id = 6
    AND p.p_channel_tv = 'Y'
    AND p.p_discount_active = 'Y'
    AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    AND p.p_response_target > 500
),
agg_sales AS (
  SELECT
    i_category,
    i_color,
    SUM(ss_net_profit) AS total_profit,
    SUM(ss_ext_discount_amt) AS total_discount,
    SUM(ss_quantity) AS total_quantity,
    AVG(ss_sales_price) AS avg_sales_price,
    COUNT(*) AS sales_transactions
  FROM filtered_sales
  GROUP BY i_category, i_color
  HAVING SUM(ss_net_profit) > 1000
)
SELECT
  i_category,
  i_color,
  total_profit,
  total_discount,
  total_quantity,
  avg_sales_price,
  sales_transactions,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY total_profit DESC
LIMIT 10
