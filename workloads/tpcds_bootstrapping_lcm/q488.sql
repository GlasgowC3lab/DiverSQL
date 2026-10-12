SELECT
    d_return.d_year,
    CASE
        WHEN d_return.d_quarter_seq BETWEEN 1 AND 4 THEN concat('Q', CAST(d_return.d_quarter_seq AS varchar))
        ELSE 'Other'
    END AS quarter_label,
    s.s_state,
    s.s_city,
    hd_returning.hd_buy_potential,
    ws.web_name,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    AVG(wr.wr_net_loss) AS avg_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(CASE WHEN wr.wr_return_tax > 0 THEN 1 ELSE 0 END) AS taxable_returns,
    SUM(CASE WHEN hd_returning.hd_vehicle_count > 2 THEN wr.wr_return_quantity ELSE 0 END) AS returns_by_multi_vehicle_households,
    COUNT(DISTINCT hd_refunded.hd_income_band_sk) AS distinct_income_bands_refunded,
    MIN(d_return.d_date) AS earliest_return_date,
    MAX(d_close.d_date) AS latest_site_close_date
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_return.d_date_sk
JOIN date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
GROUP BY
    d_return.d_year,
    d_return.d_quarter_seq,
    s.s_state,
    s.s_city,
    hd_returning.hd_buy_potential,
    ws.web_name
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 50
