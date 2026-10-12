WITH all_data AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_county,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        hd.hd_income_band_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_quantity,
        t.t_hour,
        t.t_am_pm
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_state = 'TX'
      AND ca.ca_zip = '75001'
      AND t.t_hour BETWEEN 9 AND 17
),
set_a AS (
    SELECT
        s_store_id,
        s_store_name,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_tax) AS avg_return_tax,
        COUNT(*) AS cnt_returns
    FROM all_data
    WHERE sr_return_tax > 5.00
    GROUP BY s_store_id, s_store_name
),
set_b AS (
    SELECT
        s_store_id,
        s_store_name,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_tax) AS avg_return_tax,
        COUNT(*) AS cnt_returns
    FROM all_data
    WHERE sr_return_tax <= 5.00
    GROUP BY s_store_id, s_store_name
)
SELECT *
FROM (
    SELECT s_store_id, s_store_name, total_return_amt, avg_return_tax, cnt_returns
    FROM set_a
    EXCEPT
    SELECT s_store_id, s_store_name, total_return_amt, avg_return_tax, cnt_returns
    FROM set_b
) AS diff
ORDER BY total_return_amt DESC
LIMIT 100
