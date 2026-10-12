WITH returns_not_in_sales AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT cs_order_number
    FROM catalog_sales
),
base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cs.cs_net_paid,
        d.d_year,
        p.p_promo_name,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        ws.ws_net_paid,
        ss.ss_net_paid,
        wp.wp_max_ad_count
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (5)
    ) inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_quantity_on_hand > 0
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_promo_sk = p.p_promo_sk
       AND ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND p.p_promo_name LIKE 'a%'
      AND wp.wp_max_ad_count >= 1
      AND EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_sk = cr.cr_reason_sk
            AND r2.r_reason_desc = r.r_reason_desc
      )
      AND cr.cr_order_number IN (SELECT cr_order_number FROM returns_not_in_sales)
),
agg1 AS (
    SELECT
        d_year,
        p_promo_name,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cs_net_paid) AS total_sales_net,
        COUNT(*) AS cnt
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, p_promo_name),
        (d_year),
        (p_promo_name),
        ()
    )
)
SELECT
    d_year,
    p_promo_name,
    total_return_amount,
    total_sales_net,
    cnt,
    CASE WHEN cnt = 0 THEN NULL ELSE total_return_amount / cnt END AS avg_return_per_row
FROM agg1
WHERE total_return_amount > 1000
   OR total_sales_net > 5000
ORDER BY total_return_amount DESC
LIMIT 100
