WITH
    sampled_cr AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_net_loss,
            hd.hd_income_band_sk
        FROM catalog_returns cr
        TABLESAMPLE BERNOULLI (10)
        JOIN household_demographics hd
            ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    ),
    cr_agg AS (
        SELECT
            cr_returned_date_sk,
            SUM(cr_net_loss) AS total_cr_net_loss,
            COUNT(*) AS cr_cnt
        FROM sampled_cr
        WHERE cr_return_quantity > 1
          AND cr_return_amount > 20
          AND hd_income_band_sk >= 10
        GROUP BY cr_returned_date_sk
    ),
    wr_join_hd AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            wr.wr_net_loss,
            hd.hd_income_band_sk AS wr_income_band
        FROM web_returns wr
        JOIN household_demographics hd
            ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    ),
    wr_agg AS (
        SELECT
            wr_returned_date_sk,
            SUM(wr_net_loss) AS total_wr_net_loss,
            COUNT(*) AS wr_cnt
        FROM wr_join_hd
        WHERE wr_return_quantity > 1
          AND wr_return_amt > 30
          AND wr_income_band >= 10
        GROUP BY wr_returned_date_sk
    ),
    common_dates AS (
        SELECT cr_returned_date_sk AS d_sk
        FROM cr_agg
        INTERSECT
        SELECT wr_returned_date_sk
        FROM wr_agg
    ),
    combined AS (
        SELECT
            d.d_date,
            d.d_year,
            d.d_month_seq,
            ca.total_cr_net_loss,
            wa.total_wr_net_loss,
            ca.total_cr_net_loss - wa.total_wr_net_loss AS net_loss_diff,
            CASE
                WHEN ca.total_cr_net_loss > wa.total_wr_net_loss THEN 'Catalog Higher'
                WHEN ca.total_cr_net_loss < wa.total_wr_net_loss THEN 'Web Higher'
                ELSE 'Equal'
            END AS loss_comparison,
            RANK() OVER (PARTITION BY d.d_year ORDER BY (ca.total_cr_net_loss - wa.total_wr_net_loss) DESC) AS rank_yearly
        FROM common_dates cd
        JOIN date_dim d
            ON d.d_date_sk = cd.d_sk
        JOIN cr_agg ca
            ON ca.cr_returned_date_sk = d.d_date_sk
        JOIN wr_agg wa
            ON wa.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_moy IN (1, 2, 3)
          AND d.d_current_day = 'N'
          AND (SELECT MAX(hd_income_band_sk) FROM household_demographics) > 5
    )
SELECT
    d_year,
    d_month_seq,
    net_loss_diff,
    loss_comparison,
    rank_yearly
FROM combined
ORDER BY net_loss_diff DESC
LIMIT 100
