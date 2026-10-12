SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    p.p_channel_tv,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_paid - cs.cs_ext_discount_amt) AS net_paid_after_discount,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_net_loss) AS total_return_loss,
    CAST(SUM(wr.wr_net_loss) AS double) / NULLIF(SUM(cs.cs_net_paid), 0) AS loss_ratio,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    COUNT(wr.wr_order_number) AS num_returns,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_ext_discount_amt ELSE 0 END) AS total_discount_amount
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_p_start
    ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end
    ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2020
  AND p.p_cost > 500.00
  AND d_p_start.d_date <= d_sold.d_date
  AND d_p_end.d_date >= d_sold.d_date
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    p.p_channel_tv,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
