WITH joined AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        d.d_year,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        r_sr.r_reason_desc AS store_reason,
        r_wr.r_reason_desc AS web_reason,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_ticket_number,
        wr.wr_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d.d_year = 2001
      AND hd.hd_buy_potential = '5001-10000'
      AND ib.ib_lower_bound >= 50000
      AND sr.sr_fee > 20
      AND wr.wr_return_amt > 100
),
agg AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        d_year,
        ib_income_band_sk,
        hd_buy_potential,
        COUNT(DISTINCT sr_ticket_number) AS store_return_cnt,
        SUM(sr_return_amt_inc_tax) AS total_store_return_amt,
        AVG(wr_return_amt) AS avg_web_return_amt,
        MIN(sr_fee) AS min_store_fee,
        MAX(sr_return_ship_cost) AS max_ship_cost
    FROM joined
    GROUP BY
        c_customer_sk,
        c_customer_id,
        d_year,
        ib_income_band_sk,
        hd_buy_potential
),
final AS (
    SELECT
        a.*, 
        cw.total_customer_web_return_amt,
        ROW_NUMBER() OVER (ORDER BY a.total_store_return_amt DESC) AS rn
    FROM agg a
    CROSS JOIN LATERAL (
        SELECT SUM(wr2.wr_return_amt) AS total_customer_web_return_amt
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = a.c_customer_sk
    ) cw
)
SELECT
    c_customer_id,
    d_year,
    ib_income_band_sk,
    hd_buy_potential,
    store_return_cnt,
    total_store_return_amt,
    avg_web_return_amt,
    min_store_fee,
    max_ship_cost,
    total_customer_web_return_amt,
    rn
FROM final
ORDER BY rn
LIMIT 100
