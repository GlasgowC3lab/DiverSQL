SELECT
    c_ret.c_customer_id AS returning_customer_id,
    c_ret.c_first_name AS returning_first_name,
    c_ret.c_last_name AS returning_last_name,
    c_ref.c_customer_id AS refunded_customer_id,
    c_ref.c_first_name AS refunded_first_name,
    c_ref.c_last_name AS refunded_last_name,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_net_loss,
    (wr.wr_return_amt - wr.wr_return_tax) AS net_return_without_tax,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_ret.d_date AS return_date,
    d_shipto.d_date AS first_ship_date,
    d_sales.d_date AS first_sales_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_country,
    s.s_floor_space,
    s.s_tax_percentage,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY wr.wr_return_amt DESC) AS return_rank
FROM web_returns AS wr
JOIN date_dim AS d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN item AS i
    ON wr.wr_item_sk = i.i_item_sk
JOIN customer AS c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer AS c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN date_dim AS d_shipto
    ON c_ref.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim AS d_sales
    ON c_ref.c_first_sales_date_sk = d_sales.d_date_sk
JOIN store AS s
    ON s.s_closed_date_sk = d_ret.d_date_sk
ORDER BY wr.wr_return_amt DESC
LIMIT 100
