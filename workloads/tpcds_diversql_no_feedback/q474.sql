WITH base AS (
    SELECT
        s.s_store_name,
        s.s_city,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        d_sales.d_year,
        ws.web_name,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
    JOIN customer_address ca_current ON c.c_current_addr_sk = ca_current.ca_address_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN customer c_return ON sr.sr_customer_sk = c_return.c_customer_sk
    JOIN customer_address ca_return ON sr.sr_addr_sk = ca_return.ca_address_sk
    JOIN store s_return ON sr.sr_store_sk = s_return.s_store_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_first_ship ON c.c_first_shipto_date_sk = d_first_ship.d_date_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY SUM(ss_net_paid) DESC) AS row_num,
    s_store_name,
    s_city,
    i_brand,
    i_category,
    p_promo_name,
    d_year,
    web_name,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(ss_net_paid) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    SUM(sr_return_quantity) AS total_quantity_returned,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(wr_return_quantity) AS total_quantity_web_return,
    SUM(wr_return_amt) AS total_web_return_amount
FROM base
GROUP BY CUBE (s_store_name, s_city, i_brand, i_category, p_promo_name, d_year, web_name)
ORDER BY row_num
LIMIT 100
