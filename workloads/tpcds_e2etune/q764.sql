WITH store_agg AS (
    SELECT
        t.t_hour,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        AVG(ss.ss_ext_discount_amt) AS store_avg_discount,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 21
      AND hd.hd_income_band_sk IN (3,4,5)
    GROUP BY t.t_hour, hd.hd_income_band_sk
),
web_agg AS (
    SELECT
        t.t_hour,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        AVG(ws.ws_ext_discount_amt) AS web_avg_discount,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 21
      AND hd.hd_income_band_sk IN (3,4,5)
    GROUP BY t.t_hour, hd.hd_income_band_sk
)
SELECT
    COALESCE(s.t_hour, w.t_hour) AS hour_of_day,
    COALESCE(s.hd_income_band_sk, w.hd_income_band_sk) AS income_band,
    COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
    (COALESCE(s.store_avg_discount, 0) * COALESCE(s.store_sales_cnt, 0) +
     COALESCE(w.web_avg_discount, 0) * COALESCE(w.web_sales_cnt, 0)) /
        NULLIF(COALESCE(s.store_sales_cnt, 0) + COALESCE(w.web_sales_cnt, 0), 0) AS combined_avg_discount,
    COALESCE(s.store_sales_cnt, 0) + COALESCE(w.web_sales_cnt, 0) AS total_sales_cnt,
    RANK() OVER (ORDER BY COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) DESC) AS profit_rank
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.t_hour = w.t_hour
   AND s.hd_income_band_sk = w.hd_income_band_sk
WHERE COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) > 0
ORDER BY total_net_profit DESC
LIMIT 5
