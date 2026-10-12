WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY
        cr.cr_call_center_sk,
        d.d_year,
        d.d_month_seq
)
SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    cc.cc_call_center_id,
    cc.cc_city AS call_center_city,
    sales.d_year,
    sales.d_month_seq,
    sales.total_sales,
    sales.total_profit,
    returns.total_return_amount,
    returns.total_return_loss,
    (sales.total_sales - returns.total_return_amount) AS net_sales_minus_returns,
    s.s_tax_percentage,
    cc.cc_tax_percentage,
    s.s_number_employees,
    cc.cc_employees,
    CASE
        WHEN sales.total_sales > 0 THEN ROUND(100.0 * sales.total_profit / sales.total_sales, 2)
        ELSE NULL
    END AS profit_margin_pct,
    CASE
        WHEN returns.total_return_amount > 0 THEN ROUND(100.0 * returns.total_return_loss / returns.total_return_amount, 2)
        ELSE NULL
    END AS return_loss_pct,
    d_store_closed.d_date AS store_closed_date,
    d_cc_open.d_date AS call_center_open_date,
    d_cc_closed.d_date AS call_center_closed_date
FROM sales_agg sales
JOIN store s
    ON sales.ss_store_sk = s.s_store_sk
JOIN returns_agg returns
    ON returns.d_year = sales.d_year
    AND returns.d_month_seq = sales.d_month_seq
JOIN call_center cc
    ON returns.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
WHERE s.s_state = 'TX'
  AND cc.cc_state = 'TX'
ORDER BY
    sales.d_year,
    sales.d_month_seq,
    s.s_store_id
