WITH promo_filtered AS (
   SELECT p_promo_sk,
          p_promo_id,
          p_start_date_sk,
          p_end_date_sk,
          p_discount_active,
          p_channel_tv,
          p_promo_name,
          p_purpose
   FROM promotion
   WHERE p_start_date_sk >= 2450100
     AND p_end_date_sk <= 2450400
     AND p_discount_active = 'Y'
     AND p_channel_tv = 'Y'
     AND p_promo_name IS NOT NULL
),
sales_filtered AS (
   SELECT ws_sold_date_sk,
          ws_item_sk,
          ws_promo_sk,
          ws_quantity,
          ws_sales_price,
          ws_ext_sales_price,
          ws_net_profit,
          ws_ship_customer_sk,
          ws_bill_hdemo_sk
   FROM web_sales
   WHERE ws_ext_sales_price > 1000
     AND ws_quantity BETWEEN 1 AND 100
     AND ws_ship_customer_sk IN (7244747, 1084180, 3522505)
     AND ws_bill_hdemo_sk NOT IN (5133, 2889)
     AND ws_net_profit > 0
),
joined_full AS (
   SELECT p.p_promo_sk,
          p.p_promo_id,
          s.ws_sold_date_sk,
          s.ws_item_sk,
          s.ws_quantity,
          s.ws_sales_price,
          s.ws_ext_sales_price,
          s.ws_net_profit,
          p.p_discount_active,
          ROW_NUMBER() OVER (PARTITION BY p.p_promo_sk ORDER BY s.ws_ext_sales_price DESC) AS rn_qty
   FROM promo_filtered p
   FULL OUTER JOIN sales_filtered s
        ON s.ws_promo_sk = p.p_promo_sk
   WHERE EXISTS (
         SELECT 1
         FROM promotion p2
         WHERE p2.p_promo_sk = p.p_promo_sk
           AND p2.p_purpose = 'Discount'
   )
),
lateral_calc AS (
   SELECT jf.*, lr.line_revenue
   FROM joined_full jf
   CROSS JOIN LATERAL (
        SELECT jf.ws_quantity * jf.ws_sales_price AS line_revenue
   ) AS lr
),
unioned AS (
   SELECT p_promo_sk,
          p_promo_id,
          ws_sold_date_sk,
          ws_item_sk,
          line_revenue,
          rn_qty
   FROM lateral_calc
   WHERE rn_qty = 1
   UNION
   SELECT p_promo_sk,
          p_promo_id,
          NULL AS ws_sold_date_sk,
          NULL AS ws_item_sk,
          0.0 AS line_revenue,
          NULL AS rn_qty
   FROM promo_filtered
   WHERE p_promo_sk NOT IN (SELECT ws_promo_sk FROM sales_filtered)
),
promo_only_keys AS (
   SELECT p_promo_sk FROM promotion
),
sales_only_keys AS (
   SELECT ws_promo_sk AS p_promo_sk FROM web_sales
),
unmatched_promos AS (
   SELECT p_promo_sk FROM promo_only_keys
   EXCEPT
   SELECT p_promo_sk FROM sales_only_keys
)
SELECT u.p_promo_sk,
       u.p_promo_id,
       u.ws_sold_date_sk,
       u.ws_item_sk,
       u.line_revenue,
       DENSE_RANK() OVER (ORDER BY u.line_revenue DESC) AS revenue_rank,
       CASE WHEN u.p_promo_sk IN (SELECT p_promo_sk FROM unmatched_promos)
            THEN 'UNMATCHED'
            ELSE 'MATCHED'
       END AS match_status
FROM unioned u
ORDER BY revenue_rank ASC, u.p_promo_id
LIMIT 100
