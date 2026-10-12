WITH
  returns_sales AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_reason_sk,
      cr.cr_refunded_addr_sk,
      cs.cs_sold_date_sk,
      cs.cs_quantity,
      cs.cs_sales_price,
      cs.cs_net_profit,
      ca.ca_state,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 1000.00
      AND cr.cr_return_quantity <= 5
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2455000
      AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL')
  ),
  returns_sales_array AS (
    SELECT
      rs.*, 
      ARRAY[rs.cs_sales_price, rs.cr_return_amount] AS price_array
    FROM returns_sales rs
  ),
  unnested_prices AS (
    SELECT
      rs.cr_order_number,
      rs.cr_return_amount,
      rs.cr_return_quantity,
      rs.cr_reason_sk,
      rs.cs_sold_date_sk,
      rs.cs_quantity,
      rs.cs_sales_price,
      rs.cs_net_profit,
      rs.ca_state,
      rs.r_reason_desc,
      p AS price_value
    FROM returns_sales_array rs
    CROSS JOIN UNNEST(rs.price_array) AS t(p)
  ),
  agg_union AS (
    SELECT
      u.order_number,
      u.state,
      u.reason_desc,
      SUM(u.cr_return_amount)                AS sum_return_amount,
      AVG(u.price_value)                     AS avg_price,
      COUNT(*)                               AS cnt_rows,
      MIN(u.price_value)                     AS min_price,
      MAX(u.price_value)                     AS max_price,
      CASE WHEN SUM(u.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM (
      SELECT
        cr_order_number AS order_number,
        ca_state          AS state,
        r_reason_desc     AS reason_desc,
        cr_return_amount,
        cs_sales_price,
        cs_net_profit,
        cs_quantity,
        price_value
      FROM unnested_prices
      WHERE cs_quantity > 2
      UNION DISTINCT
      SELECT
        cr_order_number,
        ca_state,
        r_reason_desc,
        cr_return_amount,
        cs_sales_price,
        cs_net_profit,
        cs_quantity,
        price_value
      FROM unnested_prices
      WHERE cs_quantity <= 2
    ) u
    GROUP BY u.order_number, u.state, u.reason_desc
  ),
  intersect_keys AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    WHERE cr.cr_refunded_cash > 200.00
    INTERSECT
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 500.00
  ),
  final AS (
    SELECT
      a.*, 
      ROW_NUMBER() OVER (ORDER BY a.sum_return_amount DESC) AS rn
    FROM agg_union a
    JOIN intersect_keys ik ON a.order_number = ik.order_number
  )
SELECT *
FROM final
ORDER BY rn ASC
LIMIT 100
