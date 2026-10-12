WITH promo_demo AS (
    SELECT DISTINCT p_promo_sk
    FROM promotion
    WHERE p_channel_demo = 'N'
)
SELECT gender, year, total_sales, max_promo_cost
FROM (
    SELECT
        cd.cd_gender AS gender,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_sales,
        (
            SELECT MAX(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_promo_sk = ss.ss_promo_sk
        ) AS max_promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_fy_year = 1914
      AND cd.cd_education_status = 'College'
      AND p.p_channel_press = 'N'
    GROUP BY cd.cd_gender, d.d_year, ss.ss_promo_sk

    UNION ALL

    SELECT
        cd.cd_gender AS gender,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_sales,
        (
            SELECT MAX(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_promo_sk = ss.ss_promo_sk
        ) AS max_promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_fy_year = 1915
      AND cd.cd_marital_status = 'S'
      AND ss.ss_promo_sk IN (SELECT p_promo_sk FROM promo_demo)
    GROUP BY cd.cd_gender, d.d_year, ss.ss_promo_sk
) t
ORDER BY total_sales DESC, year ASC
LIMIT 100
