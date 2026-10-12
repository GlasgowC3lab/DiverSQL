WITH avg_promo AS (
    SELECT avg(p_cost) AS avg_cost
    FROM promotion
)
SELECT *
FROM (
    SELECT
        'store' AS source,
        dd.d_year AS period_year,
        SUM(ss.ss_net_paid) AS metric
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_quantity > 5
      AND p.p_cost > (SELECT avg_cost FROM avg_promo)
    GROUP BY dd.d_year
    UNION ALL
    SELECT
        'web' AS source,
        dd.d_year AS period_year,
        SUM(wr.wr_net_loss) AS metric
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_quantity > 2
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY dd.d_year
) combined
ORDER BY source, period_year DESC, metric DESC
LIMIT 100
