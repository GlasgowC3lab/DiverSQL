WITH cd_ib AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        AVG(cd.cd_purchase_estimate) AS avg_purchase,
        COUNT(*) AS cust_cnt
    FROM
        customer_demographics cd
    JOIN
        income_band ib
        ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE
        cd.cd_marital_status IN ('M', 'S')
        AND cd.cd_education_status IN ('College', '4 yr Degree')
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    HAVING
        COUNT(*) >= 5
),
ws_td AS (
    SELECT
        ws.web_site_sk,
        ws.web_city,
        ws.web_state,
        td.t_shift,
        td.t_meal_time
    FROM
        web_site ws
    JOIN
        time_dim td
        ON ws.web_open_date_sk = td.t_time_sk
    WHERE
        td.t_shift = 'Evening'
)
SELECT
    ws_td.web_city,
    ws_td.t_shift,
    cd_ib.ib_income_band_sk,
    cd_ib.avg_purchase,
    cd_ib.cust_cnt,
    RANK() OVER (PARTITION BY ws_td.web_city ORDER BY cd_ib.avg_purchase DESC) AS purchase_rank_city
FROM
    ws_td
CROSS JOIN
    cd_ib
ORDER BY
    ws_td.web_city,
    purchase_rank_city
LIMIT 20
