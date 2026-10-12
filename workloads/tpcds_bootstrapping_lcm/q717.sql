SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_state,
    hd_refunded.hd_income_band_sk,
    hd_returning.hd_vehicle_count,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(wr.wr_return_quantity) AS total_quantity,
    COUNT(*) FILTER (WHERE wr.wr_return_tax > 0) AS returns_with_tax,
    ROUND(AVG(wr.wr_return_tax), 2) AS avg_return_tax
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_state,
    hd_refunded.hd_income_band_sk,
    hd_returning.hd_vehicle_count
ORDER BY total_net_loss DESC
LIMIT 100
