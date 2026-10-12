WITH promo_agg AS (
    SELECT
        w.web_site_id,
        i.i_category,
        d_start.d_year AS promo_year,
        COUNT(DISTINCT p.p_promo_sk) AS promo_cnt,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(i.i_current_price) AS avg_item_price,
        AVG(c.c_birth_year) AS avg_customer_birth_year
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d_start.d_date_sk
    JOIN customer c ON c.c_first_sales_date_sk = d_start.d_date_sk
    WHERE d_start.d_year = 2020
      AND p.p_discount_active = 'Y'
      AND w.web_country = 'United States'
    GROUP BY w.web_site_id, i.i_category, d_start.d_year
    HAVING COUNT(DISTINCT p.p_promo_sk) >= 2
)
SELECT
    web_site_id,
    i_category,
    promo_year,
    promo_cnt,
    total_promo_cost,
    avg_item_price,
    avg_customer_birth_year,
    RANK() OVER (PARTITION BY promo_year ORDER BY total_promo_cost DESC) AS site_category_rank
FROM promo_agg
ORDER BY total_promo_cost DESC, site_category_rank
LIMIT 50
