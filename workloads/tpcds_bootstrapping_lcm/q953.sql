WITH agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        i.i_category AS item_category,
        i.i_brand AS item_brand,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        d_cc_open.d_year AS cc_open_year,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2002
    GROUP BY
        cc.cc_name,
        cc.cc_city,
        s.s_store_name,
        s.s_city,
        i.i_category,
        i.i_brand,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_cc_open.d_year
)
SELECT
    call_center_name,
    call_center_city,
    store_name,
    store_city,
    item_category,
    item_brand,
    return_year,
    return_month,
    cc_open_year,
    total_return_amount,
    total_return_quantity,
    avg_return_tax,
    total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY call_center_name ORDER BY total_return_amount DESC) AS rank_by_return_amount
FROM agg
ORDER BY total_return_amount DESC
LIMIT 50
