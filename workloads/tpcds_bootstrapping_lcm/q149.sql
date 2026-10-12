SELECT
    d_base.d_year AS year,
    d_base.d_month_seq AS month,
    cc.cc_company_name,
    cc.cc_division,
    s.s_store_name,
    s.s_division_id,
    (cc.cc_division * 10 + s.s_division_id) AS division_key,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(sr.sr_return_quantity) AS total_quantity_returned,
    SUM(sr.sr_net_loss) AS total_returns_net_loss,
    (SUM(cs.cs_net_paid) - SUM(sr.sr_net_loss)) AS net_sales_after_returns,
    CASE
        WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid)
        ELSE NULL
    END AS profit_margin,
    (SUM(cs.cs_net_paid) - SUM(sr.sr_net_loss)) / NULLIF(SUM(cs.cs_quantity) - SUM(sr.sr_return_quantity), 0) AS avg_price_after_returns
FROM
    date_dim d_base
    JOIN store s ON s.s_closed_date_sk = d_base.d_date_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_base.d_date_sk
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
        AND cs.cs_sold_date_sk = d_base.d_date_sk
GROUP BY
    d_base.d_year,
    d_base.d_month_seq,
    cc.cc_company_name,
    cc.cc_division,
    s.s_store_name,
    s.s_division_id,
    (cc.cc_division * 10 + s.s_division_id)
HAVING
    SUM(cs.cs_net_paid) > 0
