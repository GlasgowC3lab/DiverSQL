WITH date_promo AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_discount_active,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_email
    FROM date_dim d
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
),
store_closed AS (
    SELECT
        d.d_date,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_floor_space,
        s.s_tax_percentage
    FROM date_dim d
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
),
web_site_open AS (
    SELECT
        d.d_date,
        ws.web_site_id,
        ws.web_name,
        ws.web_city,
        ws.web_state,
        ws.web_gmt_offset
    FROM date_dim d
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
),
web_returns_agg AS (
    SELECT
        d.d_date,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM date_dim d
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT
    dp.d_date,
    dp.d_year,
    dp.d_month_seq,
    dp.p_promo_id,
    dp.p_promo_name,
    dp.p_cost,
    dp.p_channel_tv,
    sc.s_store_id,
    sc.s_store_name,
    sc.s_city AS store_city,
    sc.s_state AS store_state,
    sc.s_floor_space,
    wso.web_site_id,
    wso.web_name,
    wso.web_city,
    wso.web_state,
    wr.total_return_amt,
    wr.total_return_qty,
    wr.avg_return_tax,
    wr.return_cnt
FROM date_promo dp
JOIN store_closed sc
    ON sc.d_date = dp.d_date
JOIN web_site_open wso
    ON wso.d_date = dp.d_date
JOIN web_returns_agg wr
    ON wr.d_date = dp.d_date
ORDER BY dp.d_date DESC
LIMIT 100
