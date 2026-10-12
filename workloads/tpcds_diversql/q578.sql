WITH base1 AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        hd.hd_buy_potential,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns,
        CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'LOSS' ELSE 'NO_LOSS' END AS loss_flag
    FROM catalog_returns cr
    RIGHT OUTER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_current_month = 'Y'
      AND cr.cr_refunded_cash > 1000
      AND hd.hd_vehicle_count >= 2
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr3
          WHERE cr3.cr_returned_date_sk = d.d_date_sk
            AND cr3.cr_net_loss > 0
      )
    GROUP BY ROLLUP (d.d_year, d.d_month_seq, hd.hd_buy_potential)
),

base2 AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        hd.hd_buy_potential,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns,
        CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'LOSS' ELSE 'NO_LOSS' END AS loss_flag
    FROM catalog_returns cr
    RIGHT OUTER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_current_month = 'N'
      AND cr.cr_reversed_charge > 50
      AND hd.hd_dep_count <= 2
    GROUP BY ROLLUP (d.d_year, d.d_month_seq, hd.hd_buy_potential)
)

SELECT
    combined.d_year,
    combined.d_month_seq,
    combined.hd_buy_potential,
    combined.total_return_amount,
    combined.total_net_loss,
    combined.cnt_returns,
    combined.loss_flag,
    l.max_return_amount,
    (SELECT COUNT(*) FROM catalog_returns) AS overall_return_count
FROM (
    SELECT * FROM base1
    UNION ALL
    SELECT * FROM base2
) AS combined
CROSS JOIN LATERAL (
    SELECT MAX(cr2.cr_return_amount) AS max_return_amount
    FROM catalog_returns cr2
    JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = combined.d_year
      AND d2.d_month_seq = combined.d_month_seq
) AS l
ORDER BY combined.d_year DESC,
         combined.d_month_seq ASC,
         combined.total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
