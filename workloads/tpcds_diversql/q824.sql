WITH cs AS (
   SELECT c.c_customer_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2020
),
ws AS (
   SELECT c.c_customer_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2020
),
intersect_customers AS (
   SELECT c_customer_sk FROM cs
   INTERSECT
   SELECT c_customer_sk FROM ws
),
return_customers AS (
   SELECT sr.sr_customer_sk AS c_customer_sk
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2020
),
union_set AS (
   SELECT c_customer_sk FROM intersect_customers
   UNION
   SELECT c_customer_sk FROM return_customers
),
ranked AS (
   SELECT u.c_customer_sk,
          c.c_first_name,
          c.c_last_name,
          d.d_date,
          row_number() OVER (PARTITION BY u.c_customer_sk ORDER BY d.d_date DESC) AS rn
   FROM union_set u
   JOIN customer c ON u.c_customer_sk = c.c_customer_sk
   JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
   WHERE EXISTS (
       SELECT 1
       FROM catalog_sales cs2
       WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
         AND cs2.cs_quantity > 5
   )
)
SELECT r.c_customer_sk,
       r.c_first_name,
       r.c_last_name,
       promo.p_promo_name
FROM ranked r
LEFT JOIN LATERAL (
   SELECT p.p_promo_name
   FROM catalog_sales cs3
   JOIN promotion p ON cs3.cs_promo_sk = p.p_promo_sk
   WHERE cs3.cs_bill_customer_sk = r.c_customer_sk
   ORDER BY cs3.cs_net_paid DESC
   LIMIT 1
) promo ON true
WHERE r.rn <= 3
ORDER BY r.c_last_name, r.c_first_name
LIMIT 100
