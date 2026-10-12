WITH promo_sales AS (
    SELECT cs.cs_promo_sk AS p_promo_sk, SUM(cs.cs_net_paid) AS sales
    FROM catalog_sales cs
    JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE d.d_year = 1999
      AND cs.cs_promo_sk IS NOT NULL
    GROUP BY cs.cs_promo_sk

    UNION ALL

    SELECT ss.ss_promo_sk AS p_promo_sk, SUM(ss.ss_net_paid) AS sales
    FROM store_sales ss
    JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE d.d_year = 1999
      AND ss.ss_promo_sk IS NOT NULL
    GROUP BY ss.ss_promo_sk

    UNION ALL

    SELECT ws.ws_promo_sk AS p_promo_sk, SUM(ws.ws_net_paid) AS sales
    FROM web_sales ws
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 1999
      AND ws.ws_promo_sk IS NOT NULL
    GROUP BY ws.ws_promo_sk
)
SELECT p.p_promo_id,
       p.p_promo_name,
       t.total_sales,
       ROW_NUMBER() OVER (ORDER BY t.total_sales DESC) AS sales_rank
FROM (
    SELECT p_promo_sk, SUM(sales) AS total_sales
    FROM promo_sales
    GROUP BY p_promo_sk
    HAVING SUM(sales) > 0
) t
JOIN promotion p ON p.p_promo_sk = t.p_promo_sk
ORDER BY total_sales DESC
LIMIT 100
