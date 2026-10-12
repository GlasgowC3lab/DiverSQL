WITH purchased AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
      AND cs.cs_ext_discount_amt > (
          SELECT MAX(p2.p_cost)
          FROM promotion p2
          WHERE p2.p_start_date_sk = (
              SELECT MIN(d2.d_date_sk)
              FROM date_dim d2
              WHERE d2.d_year = 2020
          )
      )
),
returned AS (
    SELECT DISTINCT wr.wr_refunded_customer_sk AS customer_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
),
union_set AS (
    SELECT customer_sk FROM purchased
    UNION
    SELECT customer_sk FROM returned
),
final_set AS (
    SELECT customer_sk FROM union_set
    EXCEPT
    SELECT customer_sk FROM returned
)
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name
FROM final_set f
JOIN customer c ON f.customer_sk = c.c_customer_sk
ORDER BY c.c_customer_id
