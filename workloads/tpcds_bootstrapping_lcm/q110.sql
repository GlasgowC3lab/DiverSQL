SELECT
    d.d_year,
    d.d_quarter_seq,
    s.s_store_name,
    s.s_state AS store_state,
    cc.cc_name,
    cc.cc_state AS call_center_state,
    CASE WHEN s.s_floor_space >= 20000 THEN 'Large' ELSE 'Small' END AS store_size_category,
    CASE WHEN cc.cc_tax_percentage > 5.0 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    sum(ss.ss_ext_sales_price) AS total_sales_amount,
    sum(ss.ss_quantity) AS total_units_sold,
    avg(ss.ss_ext_discount_amt) AS avg_discount_amount,
    sum(ss.ss_net_profit) AS total_net_profit,
    sum(cr.cr_return_amount) AS total_return_amount,
    sum(cr.cr_return_quantity) AS total_return_units,
    sum(cr.cr_net_loss) AS total_return_net_loss,
    sum(ss.ss_ext_sales_price) - sum(cr.cr_return_amount) AS net_sales_minus_returns,
    (sum(cr.cr_return_quantity) * 1.0) / nullif((sum(ss.ss_quantity) + sum(cr.cr_return_quantity)), 0) AS return_rate,
    (sum(ss.ss_net_profit) - sum(cr.cr_net_loss)) AS net_profit_after_returns,
    sum(ss.ss_ext_sales_price) * max(cc.cc_tax_percentage) / 100.0 AS estimated_tax_based_on_sales
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
       AND s.s_closed_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
       AND cc.cc_closed_date_sk = d.d_date_sk
       AND cc.cc_open_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    cc.cc_state,
    CASE WHEN s.s_floor_space >= 20000 THEN 'Large' ELSE 'Small' END,
    CASE WHEN cc.cc_tax_percentage > 5.0 THEN 'HighTax' ELSE 'LowTax' END
HAVING sum(ss.ss_ext_sales_price) > 10000
