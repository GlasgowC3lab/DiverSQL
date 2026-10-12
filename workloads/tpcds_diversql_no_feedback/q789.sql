WITH sales_by_store AS (
    SELECT
        s.s_store_name,
        d.d_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        (
            SELECT AVG(ss_inner.ss_ext_discount_amt)
            FROM store_sales ss_inner
            WHERE ss_inner.ss_store_sk = s.s_store_sk
        ) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
      AND p.p_channel_email = 'N'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY s.s_store_name, d.d_date, s.s_store_sk
),
sales_by_store_county AS (
    SELECT
        s.s_store_name,
        d.d_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        (
            SELECT AVG(ss_inner.ss_ext_discount_amt)
            FROM store_sales ss_inner
            WHERE ss_inner.ss_store_sk = s.s_store_sk
        ) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
      AND s.s_county = 'Jackson County'
      AND p.p_channel_demo = 'N'
    GROUP BY s.s_store_name, d.d_date, s.s_store_sk
)
SELECT *
FROM sales_by_store
UNION ALL
SELECT *
FROM sales_by_store_county
LIMIT 100
