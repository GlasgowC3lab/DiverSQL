WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        sr.sr_return_amt,
        d.d_year,
        d.d_date_sk,
        t.t_hour,
        i.i_category,
        i.i_item_id,
        cp.cp_catalog_number,
        r.r_reason_desc,
        ws.web_state,
        c.c_customer_id,
        ca.ca_city
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_item_sk = cs.cs_item_sk
        AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
        AND ss.ss_sold_time_sk = cs.cs_sold_time_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
), with_array AS (
    SELECT
        *,
        ARRAY[cs_quantity, cs_ext_sales_price] AS measures_arr
    FROM base
)
SELECT
    d_year,
    i_category,
    r_reason_desc,
    web_state,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(cs_quantity) AS avg_quantity,
    SUM(measure) AS sum_measures
FROM with_array
CROSS JOIN UNNEST(measures_arr) AS t(measure)
WHERE d_year = 2001
  AND i_category = 'Sports'
  AND r_reason_desc = 'Damaged'
  AND t_hour BETWEEN 9 AND 17
  AND web_state = 'CA'
GROUP BY d_year, i_category, r_reason_desc, web_state
HAVING SUM(cs_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
