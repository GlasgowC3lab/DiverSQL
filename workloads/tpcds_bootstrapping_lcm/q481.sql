WITH returns_summary AS (
    SELECT
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        d_clo.d_date AS store_closed_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns,
        COUNT(DISTINCT ca_r.ca_address_sk) AS distinct_returning_addresses,
        COUNT(DISTINCT ca_f.ca_address_sk) AS distinct_refunded_addresses,
        MAX(ca_r.ca_city) FILTER (WHERE ca_r.ca_city IS NOT NULL) AS sample_returning_city,
        MAX(ca_f.ca_city) FILTER (WHERE ca_f.ca_city IS NOT NULL) AS sample_refunded_city
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca_r
        ON wr.wr_returning_addr_sk = ca_r.ca_address_sk
    JOIN customer_address ca_f
        ON wr.wr_refunded_addr_sk = ca_f.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_clo
        ON s.s_closed_date_sk = d_clo.d_date_sk
    WHERE d_ret.d_year = 2022
    GROUP BY
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_clo.d_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_category,
        i.i_brand,
        i.i_product_name
)
SELECT
    s_store_name,
    store_city,
    store_state,
    store_closed_date,
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    i_product_name,
    total_return_quantity,
    total_return_amount,
    total_return_tax,
    total_net_loss,
    total_returns,
    distinct_returning_addresses,
    distinct_refunded_addresses,
    sample_returning_city,
    sample_refunded_city,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_net_loss DESC) AS net_loss_rank
FROM returns_summary
ORDER BY total_net_loss DESC
LIMIT 100
