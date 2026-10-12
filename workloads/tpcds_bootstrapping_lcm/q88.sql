WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_manufact,
        s.s_store_id,
        s.s_city,
        s.s_state,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        inv_agg.total_quantity_on_hand
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = wr.wr_item_sk
    JOIN inv_agg ON inv_agg.inv_date_sk = d.d_date_sk
                 AND inv_agg.inv_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_manufact,
        s.s_store_id,
        s.s_city,
        s.s_state,
        inv_agg.total_quantity_on_hand
)
SELECT
    d_year,
    d_month_seq,
    i_item_id,
    i_product_name,
    i_category,
    i_manufact,
    s_store_id,
    s_city,
    s_state,
    total_return_amount,
    total_return_quantity,
    avg_net_loss,
    total_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_return_amount DESC) AS return_rank_in_month
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
