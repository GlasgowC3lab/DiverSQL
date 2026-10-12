WITH returns_agg AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        t.t_hour AS hour_of_day,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 21
    GROUP BY s.s_store_id, s.s_store_name, t.t_hour, cd.cd_gender, hd.hd_income_band_sk
),
sales_agg AS (
    SELECT 
        t.t_hour AS hour_of_day,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(*) AS sales_cnt,
        SUM(ws.ws_net_paid) AS total_sales_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 21
    GROUP BY t.t_hour, cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    r.s_store_id,
    r.s_store_name,
    r.hour_of_day,
    r.cd_gender,
    r.hd_income_band_sk,
    r.return_cnt,
    r.total_return_amt,
    r.total_net_loss,
    COALESCE(s.sales_cnt, 0) AS sales_cnt,
    COALESCE(s.total_sales_net_paid, 0) AS total_sales_net_paid,
    COALESCE(s.total_discount, 0) AS total_discount,
    CASE WHEN COALESCE(s.sales_cnt, 0) > 0 THEN r.total_return_amt / s.sales_cnt ELSE NULL END AS avg_return_per_sale
FROM returns_agg r
LEFT JOIN sales_agg s
    ON r.hour_of_day = s.hour_of_day
   AND r.cd_gender = s.cd_gender
   AND r.hd_income_band_sk = s.hd_income_band_sk
ORDER BY r.total_net_loss DESC
LIMIT 100
