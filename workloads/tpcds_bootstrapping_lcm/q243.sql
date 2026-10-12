SELECT
    cc.cc_division,
    s.s_division_id,
    d0.d_year,
    d0.d_moy,
    (d0.d_year * 100 + d0.d_moy) AS year_month_key,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_ext_tax) AS total_sales_tax,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns_inc_tax,
    SUM(sr.sr_net_loss) AS total_returns_net_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    (SUM(cs.cs_net_paid) - COALESCE(SUM(sr.sr_return_amt_inc_tax), 0)) AS net_sales_minus_returns,
    CASE
        WHEN SUM(cs.cs_net_paid) > 0 THEN
            (SUM(cs.cs_net_paid) - COALESCE(SUM(sr.sr_return_amt_inc_tax), 0)) / SUM(cs.cs_net_paid)
        ELSE NULL
    END AS net_margin
FROM date_dim d0
JOIN call_center cc
    ON cc.cc_closed_date_sk = d0.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d0.d_date_sk
   AND cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN store s
    ON s.s_closed_date_sk = d0.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d0.d_date_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
GROUP BY
    cc.cc_division,
    s.s_division_id,
    d0.d_year,
    d0.d_moy,
    (d0.d_year * 100 + d0.d_moy)
