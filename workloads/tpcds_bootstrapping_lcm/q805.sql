WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_current_month,
        SUM(ss.ss_net_paid) AS ss_total_net_paid,
        SUM(ss.ss_net_profit) AS ss_total_net_profit,
        COUNT(ss.ss_ticket_number) AS ss_txn_cnt
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_current_month
),
cs_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        d_sold.d_year,
        d_sold.d_current_month,
        SUM(cs.cs_net_paid) AS cs_total_net_paid,
        SUM(cs.cs_net_profit) AS cs_total_net_profit,
        COUNT(cs.cs_order_number) AS cs_txn_cnt,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay_days
    FROM catalog_sales cs
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    GROUP BY
        cs.cs_sold_date_sk,
        d_sold.d_year,
        d_sold.d_current_month
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        d.d_year,
        d.d_current_month,
        SUM(wr.wr_return_amt) AS wr_total_return_amt,
        SUM(wr.wr_net_loss) AS wr_total_net_loss,
        COUNT(wr.wr_order_number) AS wr_cnt
    FROM web_returns wr
    INNER JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY
        wr.wr_returned_date_sk,
        d.d_year,
        d.d_current_month
),
store_closed AS (
    SELECT
        s.s_store_sk,
        d.d_year AS closed_year,
        d.d_current_month AS closed_month
    FROM store s
    LEFT JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ss.d_year,
    ss.d_current_month,
    ss.ss_total_net_paid,
    ss.ss_total_net_profit,
    ss.ss_txn_cnt,
    COALESCE(cs.cs_total_net_paid, 0) AS cs_total_net_paid,
    COALESCE(cs.cs_total_net_profit, 0) AS cs_total_net_profit,
    COALESCE(cs.cs_txn_cnt, 0) AS cs_txn_cnt,
    COALESCE(cs.avg_ship_delay_days, 0) AS avg_ship_delay_days,
    COALESCE(wr.wr_total_return_amt, 0) AS wr_total_return_amt,
    COALESCE(wr.wr_total_net_loss, 0) AS wr_total_net_loss,
    COALESCE(wr.wr_cnt, 0) AS wr_cnt,
    st.closed_year,
    st.closed_month
FROM ss_agg ss
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN cs_agg cs
    ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
LEFT JOIN wr_agg wr
    ON ss.ss_sold_date_sk = wr.wr_returned_date_sk
LEFT JOIN store_closed st
    ON s.s_store_sk = st.s_store_sk
WHERE ss.d_year = 2022
ORDER BY ss.ss_total_net_paid DESC
LIMIT 100
