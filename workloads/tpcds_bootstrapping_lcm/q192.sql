WITH sales_agg AS (
    SELECT
        st.s_store_sk,
        st.s_store_id,
        st.s_store_name,
        d.d_year,
        d.d_quarter_seq,
        d_closed.d_date AS store_closed_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN date_dim d_closed
        ON st.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY
        st.s_store_sk,
        st.s_store_id,
        st.s_store_name,
        d.d_year,
        d.d_quarter_seq,
        d_closed.d_date
),
reasons_agg AS (
    SELECT
        st.s_store_sk,
        d.d_quarter_seq,
        r.r_reason_desc,
        SUM(wr.wr_return_amt) AS return_amount
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY
        st.s_store_sk,
        d.d_quarter_seq,
        r.r_reason_desc
),
top_reason AS (
    SELECT
        s_store_sk,
        d_quarter_seq,
        r_reason_desc,
        return_amount,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk, d_quarter_seq ORDER BY return_amount DESC) AS rn
    FROM reasons_agg
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.d_year,
    sa.d_quarter_seq,
    sa.store_closed_date,
    sa.total_sales,
    sa.total_quantity_sold,
    sa.total_net_profit,
    sa.total_returns,
    sa.total_quantity_returned,
    tr.r_reason_desc AS top_return_reason,
    tr.return_amount AS top_reason_return_amount,
    (sa.total_sales - sa.total_returns) AS net_sales_after_returns,
    CASE WHEN sa.total_sales > 0 THEN (sa.total_sales - sa.total_returns) / sa.total_sales ELSE NULL END AS net_sales_ratio
FROM sales_agg sa
LEFT JOIN top_reason tr
    ON tr.s_store_sk = sa.s_store_sk
    AND tr.d_quarter_seq = sa.d_quarter_seq
    AND tr.rn = 1
ORDER BY sa.total_sales DESC
LIMIT 100
