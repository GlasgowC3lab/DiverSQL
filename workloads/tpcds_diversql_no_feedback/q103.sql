WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND d.d_year BETWEEN 2001 AND 2002
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND c.c_current_cdemo_sk > 1000000
      AND ss.ss_quantity > 0
      AND ss.ss_wholesale_cost > 0
    GROUP BY d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS returns_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'N'
      AND d.d_year BETWEEN 2001 AND 2002
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt_inc_tax > 0
      AND c.c_current_hdemo_sk IS NOT NULL
      AND sr.sr_fee > 0
    GROUP BY d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE sm.sm_carrier = 'UPS'
      AND d_sold.d_year BETWEEN 2001 AND 2002
      AND ws.ws_quantity > 0
      AND ws.ws_wholesale_cost > 0
      AND c.c_preferred_cust_flag = 'Y'
      AND ws.ws_ext_tax > 0
    GROUP BY d_sold.d_year, d_sold.d_month_seq
),
combined AS (
    SELECT
        COALESCE(s.d_year, r.d_year, w.year) AS year,
        COALESCE(s.d_month_seq, r.d_month_seq, w.month_seq) AS month_seq,
        COALESCE(s.store_net_profit, 0) AS store_net_profit,
        COALESCE(r.returns_net_loss, 0) AS returns_net_loss,
        COALESCE(w.web_net_profit, 0) AS web_net_profit,
        (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) - COALESCE(r.returns_net_loss, 0)) AS profit_after_returns
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.d_year = r.d_year AND s.d_month_seq = r.d_month_seq
    FULL OUTER JOIN web_sales_agg w
        ON COALESCE(s.d_year, r.d_year) = w.year
       AND COALESCE(s.d_month_seq, r.d_month_seq) = w.month_seq
)
SELECT year,
       month_seq,
       profit_after_returns,
       LAG(profit_after_returns) OVER (PARTITION BY 1 ORDER BY year, month_seq) AS lag_profit
FROM combined
WHERE profit_after_returns > 1000
EXCEPT
SELECT year,
       month_seq,
       profit_after_returns,
       LAG(profit_after_returns) OVER (PARTITION BY 1 ORDER BY year, month_seq) AS lag_profit
FROM combined
WHERE profit_after_returns < 0
ORDER BY year, month_seq
LIMIT 100
