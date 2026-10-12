WITH catalog_data AS (
    SELECT
        d.d_year AS return_year,
        cp.cp_department AS category,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND NOT EXISTS (
          SELECT 1
          FROM household_demographics hd2
          WHERE hd2.hd_demo_sk = cr.cr_refunded_hdemo_sk
            AND hd2.hd_income_band_sk = 10
      )
    GROUP BY d.d_year, cp.cp_department
),
web_data AS (
    SELECT
        d.d_year AS return_year,
        s.s_city AS category,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'CA'
      AND NOT EXISTS (
          SELECT 1
          FROM household_demographics hd2
          WHERE hd2.hd_demo_sk = wr.wr_refunded_hdemo_sk
            AND hd2.hd_income_band_sk = 10
      )
    GROUP BY d.d_year, s.s_city
)
SELECT
    return_year,
    category,
    total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY return_year ORDER BY total_net_loss DESC) AS loss_rank
FROM (
    SELECT return_year, category, total_net_loss FROM catalog_data
    UNION ALL
    SELECT return_year, category, total_net_loss FROM web_data
) combined
ORDER BY return_year, loss_rank
LIMIT 100
