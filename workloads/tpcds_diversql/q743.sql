WITH sales AS (
  SELECT ws.ws_order_number,
         ws.ws_item_sk,
         ws.ws_sold_date_sk,
         ws.ws_quantity,
         ws.ws_ext_sales_price,
         ws.ws_promo_sk,
         i.i_brand,
         i.i_manufact,
         p.p_promo_name,
         p.p_discount_active
  FROM tpcds.web_sales ws
  JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
  JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    AND ws.ws_quantity > 0
    AND p.p_discount_active = 'Y'
),

returns AS (
  SELECT wr.wr_order_number,
         wr.wr_item_sk,
         wr.wr_return_quantity,
         wr.wr_return_amt,
         wr.wr_net_loss,
         i.i_brand,
         i.i_manufact
  FROM tpcds.web_returns wr
  JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
  WHERE wr.wr_return_quantity > 0
    AND wr.wr_return_amt > 10
    AND wr.wr_account_credit < 500
),

sales_with_rank AS (
  SELECT s.*, 
         RANK() OVER (PARTITION BY s.i_brand ORDER BY s.ws_ext_sales_price DESC) AS brand_sales_rank
  FROM sales s
),

returns_with_rank AS (
  SELECT r.*, 
         ROW_NUMBER() OVER (PARTITION BY r.i_brand ORDER BY r.wr_return_amt DESC) AS brand_return_rownum
  FROM returns r
),

sales_enriched AS (
  SELECT s.*, 
         lr.total_return_amt
  FROM sales_with_rank s
  LEFT JOIN LATERAL (
        SELECT SUM(wr_return_amt) AS total_return_amt
        FROM tpcds.web_returns wr
        WHERE wr.wr_order_number = s.ws_order_number
      ) lr ON TRUE
),

brand_dim AS (
  SELECT DISTINCT i_brand
  FROM tpcds.item
  LIMIT 5
),

discount_flags AS (
  SELECT 'Y' AS discount_flag UNION ALL SELECT 'N' UNION ALL SELECT 'U'
),

brand_discount_cross AS (
  SELECT bd.i_brand, df.discount_flag
  FROM brand_dim bd
  CROSS JOIN discount_flags df
),

select1 AS (
  SELECT s.ws_order_number AS order_number,
         s.ws_item_sk      AS item_sk,
         s.i_brand,
         s.i_manufact,
         s.ws_ext_sales_price AS sales_price,
         s.total_return_amt,
         bd.discount_flag,
         s.brand_sales_rank
  FROM sales_enriched s
  JOIN brand_discount_cross bd ON s.i_brand = bd.i_brand
  WHERE bd.discount_flag = 'Y'
),

select2 AS (
  SELECT r.wr_order_number AS order_number,
         r.wr_item_sk      AS item_sk,
         r.i_brand,
         r.i_manufact,
         NULL               AS sales_price,
         r.wr_return_amt    AS total_return_amt,
         bd.discount_flag,
         r.brand_return_rownum AS brand_sales_rank
  FROM returns_with_rank r
  JOIN brand_discount_cross bd ON r.i_brand = bd.i_brand
  WHERE bd.discount_flag = 'Y'
),

unioned AS (
  SELECT DISTINCT * FROM select1
  UNION
  SELECT DISTINCT * FROM select2
),

sales_orders AS (
  SELECT ws_order_number AS order_number
  FROM tpcds.web_sales
  WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451910
),

returns_orders AS (
  SELECT wr_order_number AS order_number
  FROM tpcds.web_returns
  WHERE wr_return_quantity > 0
),

common_orders AS (
  SELECT order_number FROM sales_orders
  INTERSECT
  SELECT order_number FROM returns_orders
)

SELECT u.order_number,
       u.item_sk,
       u.i_brand,
       u.i_manufact,
       u.sales_price,
       u.total_return_amt,
       u.discount_flag,
       u.brand_sales_rank
FROM unioned u
JOIN common_orders co ON u.order_number = co.order_number
ORDER BY u.brand_sales_rank ASC, u.order_number DESC
LIMIT 100
