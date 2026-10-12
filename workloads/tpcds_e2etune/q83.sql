WITH cc_open AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        cc.cc_employees,
        d.d_year,
        d.d_moy
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE cc.cc_state = 'CA' AND cc.cc_employees >= 200
),
promo_item AS (
    SELECT
        p.p_promo_id,
        p.p_cost,
        p.p_discount_active,
        i.i_item_id,
        i.i_current_price,
        d.d_year,
        d.d_moy
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
),
web_pages_month AS (
    SELECT
        d.d_year,
        d.d_moy,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
    GROUP BY d.d_year, d.d_moy
)
SELECT
    co.cc_name,
    co.d_year,
    co.d_moy,
    SUM(pi.p_cost) AS total_promo_cost,
    COUNT(DISTINCT pi.p_promo_id) AS promo_count,
    AVG(pi.i_current_price) AS avg_item_price,
    COUNT(DISTINCT pi.i_item_id) AS distinct_items,
    SUM(CASE WHEN pi.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_cnt,
    wp.web_pages_created,
    RANK() OVER (PARTITION BY co.d_year, co.d_moy ORDER BY SUM(pi.p_cost) DESC) AS month_rank
FROM cc_open co
JOIN promo_item pi
    ON co.d_year = pi.d_year
   AND co.d_moy = pi.d_moy
LEFT JOIN web_pages_month wp
    ON wp.d_year = co.d_year
   AND wp.d_moy = co.d_moy
GROUP BY co.cc_name, co.d_year, co.d_moy, wp.web_pages_created
ORDER BY total_promo_cost DESC
LIMIT 100
