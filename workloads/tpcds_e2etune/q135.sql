WITH weighted AS (
    SELECT
        w.w_county,
        i.ib_income_band_sk,
        SUM(w.w_warehouse_sq_ft * (i.ib_upper_bound - i.ib_lower_bound) / 1000.0) AS weighted_sq_ft,
        SUM(w.w_warehouse_sq_ft) AS total_sq_ft
    FROM
        warehouse w
        JOIN income_band i
          ON i.ib_income_band_sk = ((length(w.w_county) % 5) + 1)
    WHERE
        w.w_warehouse_sq_ft >= 600000
        AND i.ib_upper_bound >= 20000
    GROUP BY
        w.w_county,
        i.ib_income_band_sk
    HAVING
        SUM(w.w_warehouse_sq_ft) >= 600000
)
SELECT
    w_county,
    ib_income_band_sk,
    weighted_sq_ft,
    ROW_NUMBER() OVER (PARTITION BY w_county ORDER BY weighted_sq_ft DESC) AS rank_in_county
FROM
    weighted
ORDER BY
    weighted_sq_ft DESC
LIMIT 20
