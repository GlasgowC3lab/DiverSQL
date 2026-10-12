WITH catalog_enriched AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        d.d_date AS return_date,
        cr.cr_return_amount AS return_amount,
        r.r_reason_desc AS reason_desc,
        'Catalog' AS channel,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
web_enriched AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        d.d_date AS return_date,
        wr.wr_return_amt AS return_amount,
        r.r_reason_desc AS reason_desc,
        'Web' AS channel,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
combined AS (
    SELECT
        ce.return_date,
        ce.return_amount,
        ce.reason_desc,
        ce.channel,
        ce.ib_lower_bound,
        ce.ib_upper_bound
    FROM catalog_enriched ce
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN date_dim d2
            ON wr2.wr_returned_date_sk = d2.d_date_sk
        JOIN reason r2
            ON wr2.wr_reason_sk = r2.r_reason_sk
        WHERE d2.d_date = ce.return_date
          AND r2.r_reason_desc = ce.reason_desc
    )
    UNION ALL
    SELECT
        we.return_date,
        we.return_amount,
        we.reason_desc,
        we.channel,
        we.ib_lower_bound,
        we.ib_upper_bound
    FROM web_enriched we
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN date_dim d2
            ON cr2.cr_returned_date_sk = d2.d_date_sk
        JOIN reason r2
            ON cr2.cr_reason_sk = r2.r_reason_sk
        WHERE d2.d_date = we.return_date
          AND r2.r_reason_desc = we.reason_desc
    )
),
ranked AS (
    SELECT
        return_date,
        return_amount,
        reason_desc,
        channel,
        ib_lower_bound,
        ib_upper_bound,
        row_number() OVER (PARTITION BY channel ORDER BY return_amount DESC) AS rn
    FROM combined
)
SELECT
    return_date,
    return_amount,
    reason_desc,
    channel,
    ib_lower_bound,
    ib_upper_bound
FROM ranked
WHERE rn <= 5
ORDER BY channel, rn
