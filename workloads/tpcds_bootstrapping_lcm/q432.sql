WITH
    daily_returns AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_item_sk,
            COUNT(*) AS return_cnt,
            SUM(wr.wr_return_amt) AS total_return_amt,
            SUM(wr.wr_return_quantity) AS total_return_qty,
            SUM(wr.wr_net_loss) AS total_net_loss
        FROM web_returns wr
        GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
    ),
    promo_details AS (
        SELECT
            p.p_promo_id,
            p.p_item_sk,
            p.p_start_date_sk,
            p.p_end_date_sk,
            p.p_cost,
            p.p_discount_active,
            p.p_promo_name,
            p.p_channel_tv,
            (p.p_end_date_sk - p.p_start_date_sk) AS promo_duration_days
        FROM promotion p
    )
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    i.i_manufact,
    s.s_store_name,
    s.s_state,
    pd.p_promo_name,
    pd.p_channel_tv,
    COALESCE(dr.return_cnt, 0) AS return_cnt,
    COALESCE(dr.total_return_amt, 0) AS total_return_amt,
    COALESCE(dr.total_return_qty, 0) AS total_return_qty,
    COALESCE(dr.total_net_loss, 0) AS total_net_loss,
    pd.p_cost,
    pd.promo_duration_days,
    CASE WHEN pd.p_discount_active = 'Y' THEN 1 ELSE 0 END AS discount_active_flag,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY COALESCE(dr.total_return_amt, 0) DESC) AS category_return_rank
FROM date_dim d
LEFT JOIN daily_returns dr ON dr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN item i ON i.i_item_sk = dr.wr_item_sk
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN promo_details pd ON pd.p_item_sk = i.i_item_sk AND pd.p_start_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
ORDER BY total_return_amt DESC
LIMIT 100
