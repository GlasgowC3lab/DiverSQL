WITH base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d.d_year,
        c.c_birth_year,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 1
      AND c.c_birth_year BETWEEN 1950 AND 1980
      AND ib.ib_upper_bound <= 150000
      AND hd.hd_buy_potential IN ('5000-9999','10000-19999')
      AND cr.cr_order_number NOT IN (
            SELECT cr_order_number
            FROM catalog_returns
            WHERE cr_return_amount > 5000
      )
),
aggregated AS (
    SELECT
        d_year,
        c_birth_year,
        hd_buy_potential,
        ib_income_band_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM base
    GROUP BY CUBE (d_year, c_birth_year, hd_buy_potential, ib_income_band_sk)
),
filtered AS (
    SELECT
        d_year,
        c_birth_year,
        hd_buy_potential,
        ib_income_band_sk,
        total_return_amount,
        cnt_returns,
        total_return_amount / cnt_returns AS avg_return_amount
    FROM aggregated
    WHERE total_return_amount > 1000
      AND cnt_returns >= 5
)
SELECT
    f.d_year,
    f.c_birth_year,
    f.hd_buy_potential,
    f.ib_income_band_sk,
    f.total_return_amount,
    f.cnt_returns,
    f.avg_return_amount
FROM filtered f
WHERE f.avg_return_amount < (
        SELECT AVG(total_return_amount) FROM aggregated
      )
  AND f.d_year NOT IN (
        SELECT d_year FROM date_dim WHERE d_holiday = 'Y'
      )
LIMIT 100
