SELECT
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_education_status AS returning_education_status,
    dim.d_year,
    dim.d_month_seq,
    inv.inv_quantity_on_hand,
    inv.inv_item_sk,
    s.s_store_name,
    s.s_state,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_count
FROM web_returns wr
JOIN date_dim dim
    ON wr.wr_returned_date_sk = dim.d_date_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN inventory inv
    ON inv.inv_date_sk = dim.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dim.d_date_sk
WHERE dim.d_year BETWEEN 2000 AND 2005
GROUP BY
    cd_ref.cd_gender,
    cd_ret.cd_education_status,
    dim.d_year,
    dim.d_month_seq,
    inv.inv_quantity_on_hand,
    inv.inv_item_sk,
    s.s_store_name,
    s.s_state
ORDER BY total_return_amount DESC
LIMIT 100
