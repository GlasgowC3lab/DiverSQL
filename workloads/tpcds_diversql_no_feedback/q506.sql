WITH computed_set AS (
        SELECT 1 AS dummy UNION ALL SELECT 2
    ),
    small_income AS (
        SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
        FROM income_band
        WHERE ib_lower_bound < 200000
    )
SELECT
    c.c_customer_id,
    hd1.hd_buy_potential,
    hd2.hd_vehicle_count,
    ib1.ib_lower_bound,
    ib2.ib_upper_bound,
    wp.wp_type,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    COUNT(*) AS rows_count
FROM store_returns sr
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd1
    ON sr.sr_hdemo_sk = hd1.hd_demo_sk
JOIN household_demographics hd2
    ON c.c_current_hdemo_sk = hd2.hd_demo_sk
JOIN income_band ib1
    ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
JOIN income_band ib2
    ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN web_page wp2
    ON wp2.wp_customer_sk = c.c_customer_sk AND wp2.wp_type = 'product'
JOIN household_demographics hd3
    ON sr.sr_hdemo_sk = hd3.hd_demo_sk
CROSS JOIN small_income si
CROSS JOIN computed_set cs
WHERE sr.sr_ticket_number NOT IN (
        SELECT DISTINCT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_amt_inc_tax > 10000
    )
GROUP BY
    c.c_customer_id,
    hd1.hd_buy_potential,
    hd2.hd_vehicle_count,
    ib1.ib_lower_bound,
    ib2.ib_upper_bound,
    wp.wp_type,
    si.ib_income_band_sk,
    si.ib_lower_bound,
    si.ib_upper_bound,
    cs.dummy
ORDER BY total_net_loss DESC
LIMIT 100
