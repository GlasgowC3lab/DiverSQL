WITH ws_agg AS (
    SELECT
        i.i_brand AS brand,
        d_ws.d_year AS year,
        d_ws.d_moy AS month,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_country = 'United States'
      AND d_ws.d_year = 2020
    GROUP BY i.i_brand, d_ws.d_year, d_ws.d_moy
),
cr_agg AS (
    SELECT
        i.i_brand AS brand,
        d_cr.d_year AS year,
        d_cr.d_moy AS month,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d_cr.d_year = 2020
    GROUP BY i.i_brand, d_cr.d_year, d_cr.d_moy
),
promo_agg AS (
    SELECT
        i.i_brand AS brand,
        d_p.d_year AS year,
        d_p.d_moy AS month,
        SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    JOIN date_dim d_p ON p.p_start_date_sk = d_p.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE d_p.d_year = 2020
    GROUP BY i.i_brand, d_p.d_year, d_p.d_moy
)
SELECT
    COALESCE(ws.brand, cr.brand, promo.brand) AS brand,
    COALESCE(ws.year, cr.year, promo.year) AS year,
    COALESCE(ws.month, cr.month, promo.month) AS month,
    COALESCE(ws.total_profit, 0) AS total_profit,
    COALESCE(cr.total_loss, 0) AS total_loss,
    COALESCE(promo.total_promo_cost, 0) AS total_promo_cost,
    (COALESCE(ws.total_profit, 0) - COALESCE(cr.total_loss, 0) - COALESCE(promo.total_promo_cost, 0)) AS net_contribution,
    RANK() OVER (
        PARTITION BY COALESCE(ws.year, cr.year, promo.year),
                     COALESCE(ws.month, cr.month, promo.month)
        ORDER BY (COALESCE(ws.total_profit, 0) - COALESCE(cr.total_loss, 0) - COALESCE(promo.total_promo_cost, 0)) DESC
    ) AS brand_rank
FROM ws_agg ws
FULL OUTER JOIN cr_agg cr
    ON ws.brand = cr.brand
   AND ws.year = cr.year
   AND ws.month = cr.month
FULL OUTER JOIN promo_agg promo
    ON COALESCE(ws.brand, cr.brand) = promo.brand
   AND COALESCE(ws.year, cr.year) = promo.year
   AND COALESCE(ws.month, cr.month) = promo.month
WHERE (COALESCE(ws.total_profit, 0) - COALESCE(cr.total_loss, 0) - COALESCE(promo.total_promo_cost, 0)) > 0
ORDER BY net_contribution DESC
LIMIT 50
