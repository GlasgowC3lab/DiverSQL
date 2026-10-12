SELECT
    ca_refunded.ca_city           AS refunded_city,
    ca_refunded.ca_state          AS refunded_state,
    ca_returning.ca_city          AS returning_city,
    ca_returning.ca_state         AS returning_state,
    dd_return.d_year              AS return_year,
    dd_return.d_month_seq         AS return_month_seq,
    dd_return.d_day_name          AS return_day_name,
    dd_creation.d_year            AS page_creation_year,
    dd_creation.d_month_seq       AS page_creation_month_seq,
    dd_access.d_year              AS page_access_year,
    dd_access.d_month_seq         AS page_access_month_seq,
    s.s_store_name                AS store_name,
    s.s_city                      AS store_city,
    s.s_state                     AS store_state,
    wp.wp_url                     AS page_url,
    wp.wp_type                    AS page_type,
    wr.wr_return_quantity         AS return_quantity,
    wr.wr_return_amt              AS return_amount,
    wr.wr_return_tax              AS return_tax,
    wr.wr_fee                     AS fee,
    (wr.wr_return_amt + wr.wr_return_tax)      AS total_return_with_tax,
    (wr.wr_return_amt - wr.wr_fee)              AS net_return_excluding_fee,
    ROW_NUMBER() OVER (
        PARTITION BY ca_refunded.ca_state
        ORDER BY wr.wr_returned_date_sk DESC
    ) AS rn_state
FROM web_returns wr
JOIN date_dim dd_return
    ON wr.wr_returned_date_sk = dd_return.d_date_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim dd_creation
    ON wp.wp_creation_date_sk = dd_creation.d_date_sk
JOIN date_dim dd_access
    ON wp.wp_access_date_sk = dd_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_return.d_date_sk
WHERE dd_return.d_year = 2020
  AND wp.wp_type IN ('product', 'article')
  AND s.s_number_employees > 100
ORDER BY total_return_with_tax DESC
LIMIT 100
