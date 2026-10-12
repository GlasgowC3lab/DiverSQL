WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_ticket_number AS ticket_number,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class
),
returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS returned_date_sk,
        sr.sr_store_sk AS store_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_ticket_number AS ticket_number,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_ticket_number,
        d.d_year,
        d.d_month_seq
),
store_info AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country
    FROM store s
)
SELECT
    sa.d_year,
    si.s_store_name,
    si.s_city,
    si.s_state,
    si.s_country,
    sa.i_category,
    sa.i_class,
    SUM(sa.total_sales) AS sum_total_sales,
    SUM(sa.total_profit) AS sum_total_profit,
    SUM(sa.total_quantity) AS sum_total_quantity,
    SUM(sa.sales_cnt) AS sum_sales_transactions,
    COALESCE(SUM(ra.total_return_amount), 0) AS sum_total_return_amount,
    COALESCE(SUM(ra.total_return_loss), 0) AS sum_total_return_loss,
    COALESCE(SUM(ra.total_return_qty), 0) AS sum_total_return_quantity,
    COALESCE(SUM(ra.returns_cnt), 0) AS sum_return_transactions,
    (SUM(sa.total_sales) - COALESCE(SUM(ra.total_return_amount), 0)) AS net_sales,
    (SUM(sa.total_profit) - COALESCE(SUM(ra.total_return_loss), 0)) AS net_profit
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.ticket_number = ra.ticket_number
   AND sa.sold_date_sk = ra.returned_date_sk
   AND sa.store_sk = ra.store_sk
   AND sa.item_sk = ra.item_sk
JOIN store_info si
    ON sa.store_sk = si.store_sk
GROUP BY
    sa.d_year,
    si.s_store_name,
    si.s_city,
    si.s_state,
    si.s_country,
    sa.i_category,
    sa.i_class
ORDER BY net_profit DESC
LIMIT 200
