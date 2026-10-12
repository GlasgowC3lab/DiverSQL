WITH sales_expanded AS (
   SELECT
     p.p_promo_id AS promo_id,
     ca.ca_state AS state,
     cs.cs_ext_sales_price AS amount,
     TRIM(channel) AS channel_detail
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel)
   WHERE cs.cs_quantity > 5
     AND p.p_discount_active = 'Y'
),
sales_agg AS (
   SELECT
     promo_id,
     state,
     channel_detail,
     SUM(amount) AS total_amount
   FROM sales_expanded
   GROUP BY CUBE(promo_id, state, channel_detail)
),
returns_expanded AS (
   SELECT
     CAST('RETURN' AS varchar) AS promo_id,
     ca.ca_state AS state,
     wr.wr_return_amt AS amount,
     CAST('N/A' AS varchar) AS channel_detail
   FROM web_returns wr
   JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   WHERE wr.wr_return_quantity > 2
),
returns_agg AS (
   SELECT
     promo_id,
     state,
     channel_detail,
     SUM(amount) AS total_amount
   FROM returns_expanded
   GROUP BY CUBE(promo_id, state, channel_detail)
),
combined AS (
   SELECT promo_id, state, channel_detail, total_amount FROM sales_agg
   UNION ALL
   SELECT promo_id, state, channel_detail, total_amount FROM returns_agg
),
ranked AS (
   SELECT
     promo_id,
     state,
     channel_detail,
     total_amount,
     ROW_NUMBER() OVER (PARTITION BY promo_id ORDER BY total_amount DESC) AS rnk
   FROM combined
)
SELECT
   promo_id,
   state,
   channel_detail,
   total_amount
FROM ranked
WHERE rnk <= 5
ORDER BY total_amount DESC
LIMIT 100
